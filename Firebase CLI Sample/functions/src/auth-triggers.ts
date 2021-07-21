import * as functions from "firebase-functions";

import { firestore, database, storage, messaging, auth } from "firebase-admin";
import { FieldValue } from "@google-cloud/firestore";
import * as download from "download";

export const onUserDeleted = functions.auth
  .user()
  .onDelete(async (user, context) => {
    await database()
      .ref()
      .child("Users/" + user.uid)
      .set(null);
    await storage()
      .bucket()
      .file("UsersPhotos/" + user.uid)
      .delete();
    await firestore().collection("Users").doc(user.uid).delete();
    let batch = firestore().batch();
    for (const doc of (
      await firestore()
        .collection("Classes")
        .where("Allowed", "array-contains", user.uid)
        .get()
    ).docs) {
      batch.update(doc.ref, { Allowed: FieldValue.arrayRemove(user.uid) });
    }
    await batch.commit();
    batch = firestore().batch();
    for (const doc of (
      await firestore()
        .collection("Invitations")
        .where("GeneratedBy", "==", user.uid)
        .get()
    ).docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    batch = firestore().batch();
    for (const doc of (
      await firestore()
        .collection("Invitations")
        .where("UsedBy", "==", user.uid)
        .get()
    ).docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  });

export const userSignUp = functions.auth.user().onCreate(async (user) => {
  let customClaims: object;
  if ((await auth().listUsers(1)).users.length === 1) {
    customClaims = {
      password: null, //Empty password
      manageUsers: true, //Can manage Users' names, reset passwords and permissions
      superAccess: true, //Can read everything
      manageDeleted: true, //Can read and restore deleted items
      write: true, //Can write
      exportAreas: true, //Can Export individual Areas to Excel sheet
      birthdayNotify: true, //Can receive Birthday notifications
      confessionsNotify: true, //Can receive Confessions notifications
      tanawolNotify: true, //Can receive Tanawol notifications
      approveLocations: true, //Can Approve entities' locations
      approved: true, //A User with 'Manage Users' permission must approve new users
      personRef: firestore().collection('Persons').doc().path, //DocumentReference path to linked Person
    };
  } else {
    customClaims = {
      password: null, //Empty password
      manageUsers: false, //Can manage Users' names, reset passwords and permissions
      superAccess: false, //Can read everything
      manageDeleted: false, //Can read and restore deleted items
      write: false, //Can write
      exportAreas: false, //Can Export individual Areas to Excel sheet
      birthdayNotify: false, //Can receive Birthday notifications
      confessionsNotify: false, //Can receive Confessions notifications
      tanawolNotify: false, //Can receive Tanawol notifications
      approveLocations: false, //Can Approve entities' locations
      approved: false, //A User with 'Manage Users' permission must approve new users
      personRef: firestore().collection("Persons").doc().path, //DocumentReference path to linked Person
    };
  }
  await messaging().sendToTopic(
    "ManagingUsers",
    {
      notification: {
        title: "قام " + user.displayName + " بتسجيل حساب بالبرنامج",
        body:
          "ان كنت تعرف " +
          user.displayName +
          "فقم بتنشيط حسابه ليتمكن من الدخول للبرنامج",
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "ManagingUsers",
        title: "قام " + user.displayName + " بتسجيل حساب بالبرنامج",
        content: "",
        attachement: "https://churchdata.page.link/viewUser?UID=" + user.uid,
        time: String(Date.now()),
      },
    },
    {
      timeToLive: 24 * 60 * 60,
      restrictedPackageName: "com.AndroidQuartz.churchdata",
    }
  );
  await auth().setCustomUserClaims(user.uid, customClaims);
  await download(user.photoURL, "/tmp/", { filename: user.uid + ".jpg" });
  return storage()
    .bucket()
    .upload("/tmp/" + user.uid + ".jpg", {
      contentType: "image/jpeg",
      destination: "UsersPhotos/" + user.uid,
      gzip: true,
    });
});
