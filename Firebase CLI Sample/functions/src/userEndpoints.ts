import { https } from "firebase-functions";

import { auth, firestore, database, storage, messaging } from "firebase-admin";
import { Timestamp, FieldValue } from "@google-cloud/firestore";
import * as download from "download";

import { assertNotEmpty, getFCMTokensForUser } from "./common";
import { adminPassword } from "./adminPassword";

export const recoverDoc = https.onCall(async (data, context) => {
  if (!(await auth().getUser(context.auth.uid)).customClaims.approved)
    throw new https.HttpsError("unauthenticated", "Must be approved user");
  if (
    (await auth().getUser(context.auth.uid)).customClaims.manageDeleted ||
    (context.auth === undefined && data.adminPassword === adminPassword)
  ) {
    if (
      !data.deletedPath ||
      !(data.deletedPath as string).startsWith("Deleted") ||
      !(data.deletedPath as string).match(
        RegExp(
          "Deleted/\\d{4}-\\d{2}-\\d{2}/((Areas)|(Streets)|(Families)|(Persons)).+"
        )
      )
    )
      throw new https.HttpsError("invalid-argument", "Invalid 'deletedPath'");

    const documentToRecover = await firestore().doc(data.deletedPath).get();

    if (!documentToRecover.exists)
      throw new https.HttpsError("invalid-argument", "Invalid 'deletedPath'");

    const documentToWrite = firestore().doc(
      (data.deletedPath as string).replace(
        RegExp("Deleted/\\d{4}-\\d{2}-\\d{2}/"),
        ""
      )
    );

    if (!data.nested) {
      await documentToWrite.set(documentToRecover.data(), { merge: true });
      if (!data.keepBackup) await firestore().doc(data.deletedPath).delete();
    } else {
      const doc = (data.deletedPath as string).replace(
        RegExp("Deleted/\\d{4}-\\d{2}-\\d{2}/"),
        ""
      );
      let batch = firestore().batch();
      let count = 1;
      batch.set(documentToWrite, documentToRecover.data(), { merge: true });
      if (!data.keepBackup) {
        batch.delete(firestore().doc(data.deletedPath));
        count++;
      }

      if (doc.startsWith("Areas")) {
        for (const item of (
          await firestore()
            .collectionGroup("Streets")
            .where("AreaId", "==", firestore().doc(doc))
            .get()
        ).docs.filter((d) => d.ref.path.startsWith("Deleted"))) {
          if (count % 500 === 0) {
            await batch.commit();
            batch = firestore().batch();
          }
          batch.set(
            firestore().doc(
              item.ref.path.replace(RegExp("Deleted/\\d{4}-\\d{2}-\\d{2}/"), "")
            ),
            item.data(),
            { merge: true }
          );
          count++;
          if (!data.keepBackup) {
            batch.delete(item.ref);
            count++;
          }
        }
        for (const item of (
          await firestore()
            .collectionGroup("Families")
            .where("AreaId", "==", firestore().doc(doc))
            .get()
        ).docs.filter((d) => d.ref.path.startsWith("Deleted"))) {
          if (count % 500 === 0) {
            await batch.commit();
            batch = firestore().batch();
          }
          batch.set(
            firestore().doc(
              item.ref.path.replace(RegExp("Deleted/\\d{4}-\\d{2}-\\d{2}/"), "")
            ),
            item.data(),
            { merge: true }
          );
          count++;
          if (!data.keepBackup) {
            batch.delete(item.ref);
            count++;
          }
        }
        for (const item of (
          await firestore()
            .collectionGroup("Persons")
            .where("AreaId", "==", firestore().doc(doc))
            .get()
        ).docs.filter((d) => d.ref.path.startsWith("Deleted"))) {
          if (count % 500 === 0) {
            await batch.commit();
            batch = firestore().batch();
          }
          batch.set(
            firestore().doc(
              item.ref.path.replace(RegExp("Deleted/\\d{4}-\\d{2}-\\d{2}/"), "")
            ),
            item.data(),
            { merge: true }
          );
          count++;
          if (!data.keepBackup) {
            batch.delete(item.ref);
            count++;
          }
        }
      } else if (doc.startsWith("Streets")) {
        for (const item of (
          await firestore()
            .collectionGroup("Families")
            .where("StreetId", "==", firestore().doc(doc))
            .get()
        ).docs.filter((d) => d.ref.path.startsWith("Deleted"))) {
          if (count % 500 === 0) {
            await batch.commit();
            batch = firestore().batch();
          }
          batch.set(
            firestore().doc(
              item.ref.path.replace(RegExp("Deleted/\\d{4}-\\d{2}-\\d{2}/"), "")
            ),
            item.data(),
            { merge: true }
          );
          count++;
          if (!data.keepBackup) {
            batch.delete(item.ref);
            count++;
          }
        }
        for (const item of (
          await firestore()
            .collectionGroup("Persons")
            .where("StreetId", "==", firestore().doc(doc))
            .get()
        ).docs.filter((d) => d.ref.path.startsWith("Deleted"))) {
          if (count % 500 === 0) {
            await batch.commit();
            batch = firestore().batch();
          }
          batch.set(
            firestore().doc(
              item.ref.path.replace(RegExp("Deleted/\\d{4}-\\d{2}-\\d{2}/"), "")
            ),
            item.data(),
            { merge: true }
          );
          count++;
          if (!data.keepBackup) {
            batch.delete(item.ref);
            count++;
          }
        }
      } else if (doc.startsWith("Families")) {
        for (const item of (
          await firestore()
            .collectionGroup("Persons")
            .where("FamilyId", "==", firestore().doc(doc))
            .get()
        ).docs.filter((d) => d.ref.path.startsWith("Deleted"))) {
          if (count % 500 === 0) {
            await batch.commit();
            batch = firestore().batch();
          }
          batch.set(
            firestore().doc(
              item.ref.path.replace(RegExp("Deleted/\\d{4}-\\d{2}-\\d{2}/"), "")
            ),
            item.data(),
            { merge: true }
          );
          count++;
          if (!data.keepBackup) {
            batch.delete(item.ref);
            count++;
          }
        }
      }
      await batch.commit();
    }
    return "OK";
  }
  if (context.auth)
    throw new https.HttpsError(
      "permission-denied",
      "Must be approved user with 'manageDeleted' permission"
    );
  else throw new https.HttpsError("unauthenticated", "unauthenticated");
});

export const registerWithLink = https.onCall(async (data, context) => {
  if (context.auth === undefined) {
    throw new https.HttpsError("unauthenticated", "");
  }
  const currentUser = await auth().getUser(context.auth.uid);
  if (currentUser.customClaims.approved) {
    throw new https.HttpsError("aborted", "User already approved");
  }
  assertNotEmpty("link", data.link, typeof "");
  if ((data.link as string).startsWith("https://churchdata.page.link")) {
    const deeplink = (
      await require("node-fetch")(data.link, { redirect: "manual" })
    ).headers.get("location");
    const id = deeplink.replace(
      "https://churchdata.com/register?InvitationId=",
      ""
    );
    const doc = await firestore().collection("Invitations").doc(id).get();
    if (!doc.exists)
      throw new https.HttpsError("not-found", "Invitation not found");
    if (
      (doc.data().ExpiryDate as Timestamp).toMillis() -
        new Date().getMilliseconds() <=
      0
    )
      throw new https.HttpsError("failed-precondition", "Invitation expired");
    if (doc.data().Link !== data.link)
      throw new https.HttpsError("failed-precondition", "");
    if (doc.data().UsedBy)
      throw new https.HttpsError("failed-precondition", "");
    const batch = firestore().batch();
    batch.update(doc.ref, { UsedBy: context.auth.uid });

    const newPermissions = doc.data().Permissions;
    if (
      (await auth().getUser(doc.data().GeneratedBy)).customClaims[
        "manageAllowedUsers"
      ] === true
    ) {
      delete newPermissions.manageUsers;
      batch.update(firestore().collection("Users").doc(currentUser.uid), {
        allowedUsers: FieldValue.arrayUnion(doc.data().GeneratedBy),
      });
    }

    delete newPermissions.password;
    delete newPermissions.lastTanawol;
    delete newPermissions.lastConfession;
    newPermissions.approved = true;
    await auth().setCustomUserClaims(
      currentUser.uid,
      Object.assign(currentUser.customClaims, newPermissions)
    );
    await database()
      .ref()
      .child("Users/" + currentUser.uid + "/forceRefresh")
      .set(true);
    batch.set(firestore().doc("Users/" + currentUser.uid), {
      Name: currentUser.displayName,
    });
    await batch.commit();
    return "OK";
  }

  throw new https.HttpsError("invalid-argument", "Invalid registeration link");
});

export const deleteImage = https.onCall(async (data, context) => {
  await download((await auth().getUser(context.auth.uid)).photoURL, "/tmp/", {
    filename: "user.jpg",
  });
  return storage()
    .bucket()
    .upload("/tmp/user.jpg", {
      contentType: "image/jpeg",
      destination: "UsersPhotos/" + context.auth.uid,
      gzip: true,
    });
});

export const changeUserName = https.onCall(async (data, context) => {
  const currentUser = await auth().getUser(context.auth.uid);
  if (
    currentUser.customClaims.approved &&
    currentUser.customClaims.manageUsers
  ) {
    assertNotEmpty("newName", data.newName, typeof "");
    if (
      data.affectedUser !== null &&
      data.affectedUser !== undefined &&
      typeof data.affectedUser === typeof ""
    ) {
      await auth().updateUser(data.affectedUser, { displayName: data.newName });
      return firestore()
        .doc("Users/" + data.affectedUser)
        .update({ Name: data.newName });
    } else {
      await auth().updateUser(context.auth.uid, { displayName: data.newName });
      return firestore()
        .doc("Users/" + context.auth.uid)
        .update({ Name: data.newName });
    }
  } else if (currentUser.customClaims.approved) {
    assertNotEmpty("newName", data.newName, typeof "");
    await auth().updateUser(context.auth.uid, { displayName: data.newName });
    return firestore()
      .doc("Users/" + context.auth.uid)
      .update({ Name: data.newName });
  }
  throw new https.HttpsError(
    "permission-denied",
    "Must be an approved user with 'manageUsers' permission"
  );
});

export const registerAccount = https.onCall(async (data, context) => {
  if (context.auth === undefined) {
    throw new https.HttpsError("unauthenticated", "");
  } else if (!(await auth().getUser(context.auth.uid)).customClaims.approved) {
    throw new https.HttpsError("unauthenticated", "Must be approved user");
  }
  assertNotEmpty("name", data.name, typeof "");
  assertNotEmpty("password", data.password, typeof "");
  assertNotEmpty("fcmToken", data.fcmToken, typeof "");

  const currentUser = await auth().getUser(context.auth.uid);
  const newCustomClaims = currentUser.customClaims;

  newCustomClaims["password"] = data.password;
  try {
    if (
      currentUser.customClaims.approved &&
      (currentUser.customClaims.manageUsers ||
        currentUser.customClaims.manageAllowedUsers)
    ) {
      await messaging().subscribeToTopic(data.fcmToken, "ManagingUsers");
    }
    if (
      currentUser.customClaims.approved &&
      currentUser.customClaims.approveLocations
    ) {
      await messaging().subscribeToTopic(data.fcmToken, "ApproveLocations");
    }
  } catch (e) {
    throw new https.HttpsError("not-found", "FCM Token not found");
  }

  await auth().updateUser(currentUser.uid, { displayName: data.name });
  await firestore()
    .doc("Users/" + currentUser.uid)
    .update({ Name: data.name });
  await database()
    .ref("Users/" + currentUser.uid + "/FCM_Tokens/" + data.fcmtoken)
    .set("token");
  await auth().setCustomUserClaims(currentUser.uid, newCustomClaims);
  return database()
    .ref()
    .child("Users/" + currentUser.uid + "/forceRefresh")
    .set(true);
});

export const registerFCMToken = https.onCall(async (data, context) => {
  if (context.auth === undefined) {
    throw new https.HttpsError("unauthenticated", "");
  }
  assertNotEmpty("token", data.token, typeof "");
  await database()
    .ref("Users/" + context.auth.uid + "/FCM_Tokens")
    .remove();
  await database()
    .ref("Users/" + context.auth.uid + "/FCM_Tokens/" + data.token)
    .set("token");
  const currentUserClaims = (await auth().getUser(context.auth.uid))
    .customClaims;
  if (
    currentUserClaims.approved &&
    currentUserClaims.manageUsers &&
    (await getFCMTokensForUser(context.auth.uid)) !== null
  ) {
    await messaging().subscribeToTopic(
      await getFCMTokensForUser(context.auth.uid),
      "ManagingUsers"
    );
  }
  if (
    currentUserClaims.approved &&
    currentUserClaims.approveLocations &&
    (await getFCMTokensForUser(context.auth.uid)) !== null
  ) {
    await messaging().subscribeToTopic(
      await getFCMTokensForUser(context.auth.uid),
      "ApproveLocations"
    );
  }
  return null;
});

export const sendMessageToUsers = https.onCall(async (data, context) => {
  let from: string;
  if (context.auth === undefined) {
    if (data.adminPassword === adminPassword) {
      from = "";
    } else {
      throw new https.HttpsError("unauthenticated", "");
    }
  } else if ((await auth().getUser(context.auth.uid)).customClaims.approved) {
    from = context.auth.uid;
  } else {
    throw new https.HttpsError("unauthenticated", "");
  }
  if (
    data.users === null ||
    data.users === undefined ||
    (typeof data.users !== typeof [] && data.users !== "all")
  ) {
    throw new https.HttpsError(
      "invalid-argument",
      "users cannot be null or undefined and must be " + typeof []
    );
  }
  assertNotEmpty("title", data.title, typeof "");
  assertNotEmpty("content", data.content, typeof "");
  assertNotEmpty("attachement", data.attachement, typeof "");
  let usersToSend: string[] | string = [];
  if (typeof data.users === typeof []) {
    usersToSend = await Promise.all(
      data.users.map(
        async (user: any, i: any, ary: any) => await getFCMTokensForUser(user)
      )
    );
    usersToSend = usersToSend
      .reduce((accumulator, value) => accumulator.concat(value), [])
      .filter((v) => v !== null && v !== undefined);
  } else if (data.users === "all") {
    usersToSend = await Promise.all(
      ((await auth().listUsers()).users as any).map(
        async (user: any, i: any, ary: any) =>
          await getFCMTokensForUser(user.uid)
      )
    );
    usersToSend = usersToSend
      .reduce((accumulator, value) => accumulator.concat(value), [])
      .filter((v) => v !== null && v !== undefined);
  } else {
    throw new https.HttpsError("invalid-argument", "users");
  }
  usersToSend = usersToSend.filter((v) => v !== null);
  return messaging().sendToDevice(
    usersToSend,
    {
      notification: {
        title: data.title,
        body: data.body,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "Message",
        title: data.title,
        content: data.content,
        attachement: data.attachement,
        time: String(Date.now()),
        sentFrom: from,
      },
    },
    {
      timeToLive: 7 * 24 * 60 * 60,
      restrictedPackageName: "com.AndroidQuartz.churchdata",
    }
  );
});
export const changePassword = https.onCall(async (data, context) => {
  //ChangePassword
  try {
    if (context.auth === undefined) {
      if (data.adminPassword !== "3L0^E^EpB!6okg7GF9#f%xw^m") {
        throw new https.HttpsError("unauthenticated", "");
      }
    } else if (
      !(await auth().getUser(context.auth.uid)).customClaims.approved
    ) {
      throw new https.HttpsError("unauthenticated", "");
    }
    const currentUser = await auth().getUser(context.auth.uid);
    const newCustomClaims = currentUser.customClaims;

    assertNotEmpty("newPassword", data.newPassword, typeof "");

    if (
      data.oldPassword !== null ||
      (currentUser.customClaims.password === null && data.oldPassword === null)
    ) {
      const crypto = require("sha3");
      const s265 = new crypto.SHA3(256);
      const s512 = new crypto.SHA3(512);
      s512.update(data.oldPassword + "o$!hP64J^7c");
      s265.update(
        s512.digest("base64") + "fKLpdlk1px5ZwvF^YuIb9252C08@aQ4qDRZz5h2"
      );
      const digest = s265.digest("base64");
      if (
        digest !== currentUser.customClaims.password &&
        currentUser.customClaims.password !== null
      ) {
        throw new https.HttpsError(
          "permission-denied",
          "Old Password is incorrect"
        );
      }
    } else {
      throw new https.HttpsError("permission-denied", "Old Password is empty");
    }
    newCustomClaims["password"] = data.newPassword;
    await auth().setCustomUserClaims(context.auth.uid, newCustomClaims);
    return database()
      .ref()
      .child("Users/" + context.auth.uid + "/forceRefresh")
      .set(true);
  } catch (err) {
    console.error(err);
    throw new https.HttpsError("internal", "");
  }
});
