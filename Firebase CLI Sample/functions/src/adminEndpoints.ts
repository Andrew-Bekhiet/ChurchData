import * as functions from "firebase-functions";

import { auth, firestore, database, messaging } from "firebase-admin";

import { assertNotEmpty, getFCMTokensForUser } from "./common";
import { adminPassword } from "./adminPassword";
import { DocumentReference } from "@google-cloud/firestore";

export const migrateTypesToDocRefs = functions.https.onCall(
  async (data, context) => {
    if (data.adminPassword === adminPassword) {
      let pendingChanges = firestore().batch();
      const snapshot = await firestore().collection("Persons").get();
      for (let i = 0, l = snapshot.docs.length; i < l; i++) {
        if ((i + 1) % 500 === 0) {
          await pendingChanges.commit();
          pendingChanges = firestore().batch();
        }
        pendingChanges.update(snapshot.docs[i].ref, {
          Type: functions.firestore.document(
            "Types/" + snapshot.docs[i].data().Type
          ),
        });
      }
      return await pendingChanges.commit();
    }
    return null;
  }
);

export const getUsers = functions.https.onCall(async (data, context) => {
  if (context.auth === undefined) {
    if (data.adminPassword === adminPassword) {
      return (await auth().listUsers()).users.map((user, i, ary) => {
        const customClaims = user.customClaims;
        return Object.assign(customClaims, {
          uid: user.uid,
          name: user.displayName,
          email: user.email,
          phone: user.phoneNumber,
          photoUrl: user.photoURL,
        });
      });
    } else {
      throw new functions.https.HttpsError("unauthenticated", "");
    }
  }
  const currentUser = await auth().getUser(context.auth.uid);
  if (
    currentUser.customClaims.approved &&
    currentUser.customClaims.manageUsers
  ) {
    return (await auth().listUsers()).users
      .filter((user, i, arry) => {
        return !user.disabled;
      })
      .map((user, i, ary) => {
        const customClaims = user.customClaims;
        delete customClaims.password;
        return Object.assign(customClaims, {
          uid: user.uid,
          name: user.displayName,
          email: user.email,
          phone: user.phoneNumber,
          photoUrl: user.photoURL,
        });
      });
  } else if (currentUser.customClaims.approved) {
    return (await auth().listUsers()).users
      .filter((user, i, arry) => {
        return !user.disabled && user.customClaims.approved;
      })
      .map((user) => {
        const customClaims = user.customClaims;
        delete customClaims.password;
        delete customClaims.manageUsers;
        delete customClaims.superAccess;
        delete customClaims.write;
        delete customClaims.exportClasses;
        delete customClaims.birthdayNotify;
        delete customClaims.confessionsNotify;
        delete customClaims.tanawolNotify;
        delete customClaims.approveLocations;
        delete customClaims.approved;

        return Object.assign(customClaims, {
          uid: user.uid,
          name: user.displayName,
          photoUrl: user.photoURL,
        });
      });
  }
  throw new functions.https.HttpsError(
    "unauthenticated",
    "Must be an approved user"
  );
});

export const registerUserData = functions.https.onCall(
  async (data, context) => {
    if (context.auth === undefined)
      throw new functions.https.HttpsError("unauthenticated", "");

    assertNotEmpty("data", data.data, typeof data.data);
    assertNotEmpty("data.Name", data.data.Name, typeof "");
    assertNotEmpty("data.Type", data.data.Type, typeof "");

    const userData = (await auth().getUser(context.auth.uid)).customClaims;
    let docRef = firestore().collection("Persons").doc();
    const personData = {
      FamilyId: null,
      StreetId: null,
      Name: data.data.Name,
      Phone: data.data.Phone,
      HasPhoto: data.data.HasPhoto,
      Color: data.data.Color,
      BirthDate: firestore.Timestamp.fromMillis(data.data.BirthDate),
      BirthDay: firestore.Timestamp.fromMillis(data.data.BirthDay),
      IsStudent: data.data.IsStudent,
      StudyYear:
        data.data.StudyYear !== null &&
        data.data.StudyYear !== undefined &&
        data.data.StudyYear !== ""
          ? firestore().doc(data.data.StudyYear)
          : null,
      College:
        data.data.College !== null &&
        data.data.College !== undefined &&
        data.data.College !== ""
          ? firestore().doc(data.data.College)
          : null,
      Job:
        data.data.Job !== null &&
        data.data.Job !== undefined &&
        data.data.Job !== ""
          ? firestore().doc(data.data.Job)
          : null,
      JobDescription: data.data.JobDescription,
      Qualification: data.data.Qualification,
      Type: data.data.Type,
      Notes: data.data.Notes,
      IsServant: true,
      ServingAreaId: null,
      Church:
        data.data.Church !== null &&
        data.data.Church !== undefined &&
        data.data.Church !== ""
          ? firestore().doc(data.data.Church)
          : null,
      Meeting: data.data.Meeting,
      CFather:
        data.data.CFather !== null &&
        data.data.CFather !== undefined &&
        data.data.CFather !== ""
          ? firestore().doc(data.data.CFather)
          : null,
      State: null,
      ServingType:
        data.data.ServingType !== null &&
        data.data.ServingType !== undefined &&
        data.data.ServingType !== ""
          ? firestore().doc(data.data.ServingType)
          : null,
      LastTanawol: firestore.Timestamp.fromMillis(data.data.LastTanawol),
      LastConfession: firestore.Timestamp.fromMillis(data.data.LastConfession),
      LastEdit: context.auth.uid,
    };
    if (
      userData.personRef === null ||
      userData.personRef === undefined ||
      userData.personRef === ""
    ) {
      await docRef.set(personData);
      userData.personRef = docRef.path;
      console.log(userData.personRef);
      await auth().setCustomUserClaims(context.auth.uid, userData);
      return database()
        .ref()
        .child("Users/" + context.auth.uid + "/forceRefresh")
        .set(true);
    }
    console.log(userData.personRef);
    docRef = firestore().doc(userData.personRef);
    return docRef.update(personData);
  }
);

export const approveUser = functions.https.onCall(async (data, context) => {
  const currentUser = await auth().getUser(context.auth.uid);
  if (
    currentUser.customClaims.approved &&
    currentUser.customClaims.manageUsers
  ) {
    assertNotEmpty("affectedUser", data.affectedUser, typeof "");
    const user = await auth().getUser(data.affectedUser);
    const newClaims = user.customClaims;
    newClaims.approved = true;
    await auth().setCustomUserClaims(user.uid, newClaims);
    await database()
      .ref()
      .child("Users/" + user.uid + "/forceRefresh")
      .set(true);
    if (user.displayName === null) {
      return firestore()
        .doc("Users/" + user.uid)
        .set({ Name: user.phoneNumber, ApproveLocations: false });
    }
    return firestore()
      .doc("Users/" + user.uid)
      .set({ Name: user.displayName, ApproveLocations: false });
  }
  throw new functions.https.HttpsError(
    "permission-denied",
    "Must be an approved user with 'manageUsers' permission"
  );
});

export const unApproveUser = functions.https.onCall(async (data, context) => {
  const currentUser = await auth().getUser(context.auth.uid);
  if (
    currentUser.customClaims.approved &&
    currentUser.customClaims.manageUsers
  ) {
    assertNotEmpty("affectedUser", data.affectedUser, typeof "");

    const user = await auth().getUser(data.affectedUser);
    await auth().setCustomUserClaims(user.uid, {
      password: null, //Empty password
      manageUsers: false, //Can manage Users' names, reset passwords and permissions
      superAccess: false, //Can read everything
      write: false, //Can write
      exportAreas: false, //Can Export individual Areas to Excel sheet
      birthdayNotify: false, //Can receive Birthday notifications
      confessionsNotify: false, //Can receive Confessions notifications
      tanawolNotify: false, //Can receive Tanawol notifications
      approveLocations: false, //Can Approve entities' locations
      approved: false, //A User with 'Manage Users' permission must approve new users
      personRef: null, //DocumentReference path to linked Person
    });
    return firestore()
      .doc("Users/" + data.affectedUser)
      .delete();
  }
  throw new functions.https.HttpsError(
    "permission-denied",
    "Must be an approved user with 'manageUsers' permission"
  );
});

export const deleteUser = functions.https.onCall(async (data, context) => {
  const currentUser = await auth().getUser(context.auth.uid);
  if (
    currentUser.customClaims.approved &&
    currentUser.customClaims.manageUsers
  ) {
    assertNotEmpty("affectedUser", data.affectedUser, typeof "");

    await auth().getUser(data.affectedUser);
    await auth().deleteUser(data.affectedUser);
    return firestore()
      .doc("Users/" + data.affectedUser)
      .delete();
  }
  throw new functions.https.HttpsError(
    "permission-denied",
    "Must be an approved user with 'manageUsers' permission"
  );
});

export const resetPassword = functions.https.onCall(async (data, context) => {
  const currentUser = await auth().getUser(context.auth.uid);
  if (
    currentUser.customClaims.approved &&
    currentUser.customClaims.manageUsers
  ) {
    assertNotEmpty("affectedUser", data.affectedUser, typeof "");
    const user = await auth().getUser(data.affectedUser);
    const newClaims = user.customClaims;
    newClaims.password = null;
    await auth().setCustomUserClaims(user.uid, newClaims);
    return database()
      .ref()
      .child("Users/" + user.uid + "/forceRefresh")
      .set(true);
  }
  throw new functions.https.HttpsError(
    "permission-denied",
    "Must be an approved user with 'manageUsers' permission"
  );
});

export const updatePermissions = functions.https.onCall(
  async (data, context) => {
    const currentUser = await auth().getUser(context.auth.uid);
    if (
      currentUser.customClaims.approved &&
      currentUser.customClaims.manageUsers
    ) {
      const newPermissions = data.permissions;
      if (data.permissions.approved !== undefined)
        assertNotEmpty(
          "permissions.approved",
          data.permissions.approved,
          typeof true
        );
      if (data.permissions.manageUsers !== undefined)
        assertNotEmpty(
          "permissions.manageUsers",
          data.permissions.manageUsers,
          typeof true
        );
      if (data.permissions.manageAllowedUsers !== undefined)
        assertNotEmpty(
          "permissions.manageAllowedUsers",
          data.permissions.manageAllowedUsers,
          typeof true
        );
      if (data.permissions.manageDeleted !== undefined)
        assertNotEmpty(
          "permissions.manageDeleted",
          data.permissions.manageDeleted,
          typeof true
        );
      if (data.permissions.superAccess !== undefined)
        assertNotEmpty(
          "permissions.superAccess",
          data.permissions.superAccess,
          typeof true
        );
      if (data.permissions.write !== undefined)
        assertNotEmpty(
          "permissions.write",
          data.permissions.write,
          typeof true
        );
      if (data.permissions.exportAreas !== undefined)
        assertNotEmpty(
          "permissions.exportAreas",
          data.permissions.exportAreas,
          typeof true
        );
      if (data.permissions.approveLocations !== undefined)
        assertNotEmpty(
          "permissions.approveLocations",
          data.permissions.approveLocations,
          typeof true
        );
      if (data.permissions.birthdayNotify !== undefined)
        assertNotEmpty(
          "permissions.birthdayNotify",
          data.permissions.birthdayNotify,
          typeof true
        );
      if (data.permissions.confessionsNotify !== undefined)
        assertNotEmpty(
          "permissions.confessionsNotify",
          data.permissions.confessionsNotify,
          typeof true
        );
      if (data.permissions.tanawolNotify !== undefined)
        assertNotEmpty(
          "permissions.tanawolNotify",
          data.permissions.tanawolNotify,
          typeof true
        );
      if (data.permissions.personRef !== undefined)
        assertNotEmpty(
          "permissions.personRef",
          data.permissions.personRef,
          typeof ""
        );

      const oldPermissions = (await auth().getUser(data.affectedUser))
        .customClaims;
      if (
        newPermissions.approveLocations !== undefined &&
        oldPermissions.approveLocations !== newPermissions.approveLocations
      ) {
        await firestore()
          .doc("Users/" + data.affectedUser)
          .update({ ApproveLocations: newPermissions.approveLocations });
      }

      delete newPermissions.password;
      delete newPermissions.approved;

      try {
        const tokens = await getFCMTokensForUser(data.affectedUser);
        if (
          oldPermissions.manageUsers !== newPermissions["manageUsers"] &&
          tokens !== null &&
          tokens !== [] &&
          tokens !== undefined &&
          tokens !== ""
        ) {
          if (newPermissions["manageUsers"]) {
            await messaging().subscribeToTopic(tokens, "ManagingUsers");
          } else if (newPermissions["manageUsers"] === false) {
            await messaging().unsubscribeFromTopic(tokens, "ManagingUsers");
          } else if (
            oldPermissions.manageAllowedUsers !==
              newPermissions["manageAllowedUsers"] &&
            tokens !== null &&
            tokens !== [] &&
            tokens !== undefined &&
            tokens !== ""
          ) {
            if (newPermissions["manageAllowedUsers"]) {
              await messaging().subscribeToTopic(tokens, "ManagingUsers");
            } else if (newPermissions["manageAllowedUsers"] === false) {
              await messaging().unsubscribeFromTopic(tokens, "ManagingUsers");
            }
          }
        }
      } catch (e) {}
      try {
        const tokens = await getFCMTokensForUser(data.affectedUser);
        if (
          oldPermissions.approveLocations !==
            newPermissions["approveLocations"] &&
          tokens !== null &&
          tokens !== [] &&
          tokens !== undefined &&
          tokens !== ""
        ) {
          if (newPermissions["approveLocations"]) {
            await messaging().subscribeToTopic(tokens, "ApproveLocations");
          } else if (newPermissions["approveLocations"] === false) {
            await messaging().unsubscribeFromTopic(tokens, "ApproveLocations");
          }
        }
      } catch (e) {}

      await auth().setCustomUserClaims(
        data.affectedUser,
        Object.assign(oldPermissions, newPermissions)
      );
      return database()
        .ref()
        .child("Users/" + data.affectedUser + "/forceRefresh")
        .set(true);
    }
    throw new functions.https.HttpsError(
      "permission-denied",
      "Must be an approved user with 'manageUsers' permission"
    );
  }
);

export const tempUpdateUserData = functions.https.onCall(
  async (data, context) => {
    if (data.adminPassword === adminPassword) {
      const newPermissions = data.permissions;
      const oldPermissions = (await auth().getUser(data.affectedUser))
        .customClaims;
      if (
        newPermissions.approveLocations !== undefined &&
        oldPermissions.approveLocations !== newPermissions.approveLocations
      ) {
        await firestore()
          .doc("Users/" + data.affectedUser)
          .update({ ApproveLocations: newPermissions.approveLocations });
      }
      await auth().setCustomUserClaims(
        data.affectedUser,
        Object.assign(oldPermissions, newPermissions)
      );
      return database()
        .ref()
        .child("Users/" + data.affectedUser + "/forceRefresh")
        .set(true);
    }
    return null;
  }
);
