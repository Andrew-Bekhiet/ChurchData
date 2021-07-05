import * as functions from "firebase-functions";

import { firestore, messaging } from "firebase-admin";
import { Timestamp, FieldValue } from "@google-cloud/firestore";
import { FirebaseDynamicLinks } from "firebase-dynamic-links";

import { getChangeType, isEqual } from "./common";

export const onAreaChanged = functions.firestore
  .document("Areas/{area}")
  .onWrite(async (change, context) => {
    try {
      const changeType = getChangeType(change);
      if (changeType === "update" || changeType === "create") {
        if (
          change.after.data().Location &&
          !change.after.data().LocationConfirmed &&
          !isEqual(
            change.before?.data()?.Location,
            change.after.data().Location
          )
        ) {
          console.log(
            `Sending location change notification on Area ${
              change.before.data().Name
            }, ${change.before.id}`
          );
          await messaging().sendToTopic(
            "ApproveLocations",
            {
              notification: {
                title: "يرجى تأكيد مكان منطقة " + change.after.data().Name,
                body:
                  "تم تغيير موقع " +
                  change.after.data().Name +
                  " بدون تأكيده على الخريطة",
              },
              data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                type: "ApproveLocation",
                title: change.after.data().Name,
                content:
                  "تم تغيير موقع " +
                  change.after.data().Name +
                  " بدون التأكد من الموقع" +
                  "\n" +
                  "برجاء تأكيد الموقع",
                attachement:
                  "https://churchdata.page.link/viewArea?AreaId=" +
                  change.after.ref.id,
                time: String(Date.now()),
              },
            },
            {
              timeToLive: 24 * 60 * 60,
              restrictedPackageName: "com.AndroidQuartz.churchdata",
            }
          );
        }

        const batch = firestore().batch();
        if (
          (change.after.data().LastVisit as Timestamp)?.seconds !==
          (change.before?.data()?.LastVisit as Timestamp)?.seconds
        ) {
          batch.create(change.after.ref.collection("VisitHistory").doc(), {
            By: change.after.data().LastEdit,
            Time: change.after.data().LastVisit,
            AreaId: change.after.ref,
          });
        }
        if (
          (change.after.data().FatherLastVisit as Timestamp)?.seconds !==
          (change.before?.data()?.FatherLastVisit as Timestamp)?.seconds
        ) {
          batch.create(
            change.after.ref.collection("FatherVisitHistory").doc(),
            {
              By: change.after.data().LastEdit,
              Time: change.after.data().FatherLastVisit,
              AreaId: change.after.ref,
            }
          );
        }
        batch.create(change.after.ref.collection("EditHistory").doc(), {
          By: change.after.data().LastEdit,
          Time: FieldValue.serverTimestamp(),
          AreaId: change.after.ref,
        });

        return await batch.commit();
      } else {
        console.log(
          `Deleting Area children: ${change.before.data().Name}, ${
            change.before.id
          }`
        );
        let pendingChanges = firestore().batch();
        const snapshot = await firestore()
          .collection("Streets")
          .where(
            "AreaId",
            "==",
            firestore().doc("Areas/" + context.params.area)
          )
          .get();
        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
          if ((i + 1) % 500 === 0) {
            await pendingChanges.commit();
            pendingChanges = firestore().batch();
          }
          pendingChanges.delete(snapshot.docs[i].ref);
        }
        const docID = new Date().toISOString().split("T")[0];
        await firestore()
          .collection("Deleted")
          .doc(docID)
          .set({ Time: Timestamp.now() });
        await firestore()
          .collection("Deleted")
          .doc(docID)
          .collection("Areas")
          .doc(change.before.id)
          .set(change.before.data());
        return pendingChanges.commit();
      }
    } catch (err) {
      console.error(err);
      console.error(
        `Error occured while executing Area.onWrite on Area: ${
          change.before.data().Name
        }, ${change.before.id}`
      );
    }
    return null;
  });

export const onStreetChanged = functions.firestore
  .document("Streets/{street}")
  .onWrite(async (change, context) => {
    try {
      const changeType = getChangeType(change);
      if (changeType === "update" || changeType === "create") {
        if (
          change.after.data().Location &&
          !change.after.data().LocationConfirmed &&
          !isEqual(
            change.before?.data()?.Location,
            change.after.data().Location
          )
        ) {
          console.log(
            `Sending location change notification on Street ${
              change.before.data().Name
            }, ${change.before.id}`
          );
          await messaging().sendToTopic(
            "ApproveLocations",
            {
              notification: {
                title: "يرجى تأكيد مكان شارع " + change.after.data().Name,
                body:
                  "تم تغيير موقع " +
                  change.after.data().Name +
                  " بدون تأكيده على الخريطة",
              },
              data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                type: "ApproveLocation",
                title: change.after.data().Name,
                content:
                  "تم تغيير موقع " +
                  change.after.data().Name +
                  " بدون التأكد من الموقع" +
                  "\n" +
                  "برجاء تأكيد الموقع",
                attachement:
                  "https://churchdata.page.link/viewStreet?StreetId=" +
                  change.after.ref.id,
                time: String(Date.now()),
              },
            },
            {
              timeToLive: 24 * 60 * 60,
              restrictedPackageName: "com.AndroidQuartz.churchdata",
            }
          );
        }

        const batch = firestore().batch();
        if (
          (change.after.data().LastVisit as Timestamp)?.seconds !==
          (change.before?.data()?.LastVisit as Timestamp)?.seconds
        ) {
          batch.create(change.after.ref.collection("VisitHistory").doc(), {
            By: change.after.data().LastEdit,
            Time: change.after.data().LastVisit,
            AreaId: change.after.data().AreaId ?? null,
            StreetId: change.after.ref,
          });
        }
        if (
          (change.after.data().FatherLastVisit as Timestamp)?.seconds !==
          (change.before?.data()?.FatherLastVisit as Timestamp)?.seconds
        ) {
          batch.create(
            change.after.ref.collection("FatherVisitHistory").doc(),
            {
              By: change.after.data().LastEdit,
              Time: change.after.data().FatherLastVisit,
              AreaId: change.after.data().AreaId ?? null,
              StreetId: change.after.ref,
            }
          );
        }
        batch.create(change.after.ref.collection("EditHistory").doc(), {
          By: change.after.data().LastEdit,
          Time: FieldValue.serverTimestamp(),
          AreaId: change.after.data().AreaId ?? null,
          StreetId: change.after.ref,
        });

        batch.update(change.after.data().AreaId, {
          LastEdit: change.after.data().LastEdit,
          LastEditTime: FieldValue.serverTimestamp(),
        });

        await batch.commit();

        if (
          changeType === "update" &&
          !(
            change.after.data().AreaId as FirebaseFirestore.DocumentReference
          ).isEqual(change.before?.data()?.AreaId)
        ) {
          console.log(
            `Updating Street Children: ${change.before.data().Name}, ${
              change.before.id
            }`
          );

          let pendingChanges = firestore().batch();

          const snapshot = await firestore()
            .collection("Families")
            .where(
              "StreetId",
              "==",
              firestore().doc("Streets/" + context.params.street)
            )
            .get();
          for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            if ((i + 1) % 500 === 0) {
              await pendingChanges.commit();
              pendingChanges = firestore().batch();
            }
            pendingChanges.update(snapshot.docs[i].ref, {
              LastEdit: change.after.data().LastEdit,
              AreaId: change.after.data().AreaId,
            });
          }
          return pendingChanges.commit();
        }
      } else {
        console.log(
          `Deleting Street children: ${change.before.data().Name}, ${
            change.before.id
          }`
        );
        let pendingChanges = firestore().batch();
        const snapshot = await firestore()
          .collection("Families")
          .where(
            "StreetId",
            "==",
            firestore().doc("Streets/" + context.params.street)
          )
          .get();
        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
          if ((i + 1) % 500 === 0) {
            await pendingChanges.commit();
            pendingChanges = firestore().batch();
          }
          pendingChanges.delete(snapshot.docs[i].ref);
        }
        const docID = new Date().toISOString().split("T")[0];
        await firestore()
          .collection("Deleted")
          .doc(docID)
          .set({ Time: Timestamp.now() });
        await firestore()
          .collection("Deleted")
          .doc(docID)
          .collection("Streets")
          .doc(change.before.id)
          .set(change.before.data());
        return pendingChanges.commit();
      }
    } catch (err) {
      console.error(err);
      console.error(
        `Error occured while executing Street.onWrite on Street: ${
          change.before.data().Name
        }, ${change.before.id}`
      );
    }
    return null;
  });

export const onFamilyChanged = functions.firestore
  .document("Families/{family}")
  .onWrite(async (change, context) => {
    try {
      const changeType = getChangeType(change);
      if (changeType === "update" || changeType === "create") {
        if (
          change.after.data().Location &&
          !change.after.data().LocationConfirmed &&
          change.before?.data()?.Location !== change.after.data().Location
        ) {
          console.log(
            `Sending location change notification on Family ${
              change.before.data().Name
            }, ${change.before.id}`
          );
          await messaging().sendToTopic(
            "ApproveLocations",
            {
              notification: {
                title: "يرجى تأكيد مكان عائلة " + change.after.data().Name,
                body:
                  "تم تغيير موقع " +
                  change.after.data().Name +
                  " بدون تأكيده على الخريطة",
              },
              data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                type: "ApproveLocation",
                title: change.after.data().Name,
                content:
                  "تم تغيير موقع " +
                  change.after.data().Name +
                  " بدون التأكد من الموقع" +
                  "\n" +
                  "برجاء تأكيد الموقع",
                attachement:
                  "https://churchdata.page.link/viewFamily?FamilyId=" +
                  change.after.ref.id,
                time: String(Date.now()),
              },
            },
            {
              timeToLive: 24 * 60 * 60,
              restrictedPackageName: "com.AndroidQuartz.churchdata",
            }
          );
        }

        const batch = firestore().batch();

        if (
          (change.after.data().LastVisit as Timestamp)?.seconds !==
          (change.before?.data()?.LastVisit as Timestamp)?.seconds
        ) {
          batch.create(change.after.ref.collection("VisitHistory").doc(), {
            By: change.after.data().LastEdit,
            Time: change.after.data().LastVisit,
            AreaId: change.after.data().AreaId ?? null,
            StreetId: change.after.data().StreetId ?? null,
            FamilyId: change.after.ref,
          });
        }
        if (
          (change.after.data().FatherLastVisit as Timestamp)?.seconds !==
          (change.before?.data()?.FatherLastVisit as Timestamp)?.seconds
        ) {
          batch.create(
            change.after.ref.collection("FatherVisitHistory").doc(),
            {
              By: change.after.data().LastEdit,
              Time: change.after.data().FatherLastVisit,
              AreaId: change.after.data().AreaId ?? null,
              StreetId: change.after.data().StreetId ?? null,
              FamilyId: change.after.ref,
            }
          );
        }
        batch.create(change.after.ref.collection("EditHistory").doc(), {
          By: change.after.data().LastEdit,
          Time: FieldValue.serverTimestamp(),
          AreaId: change.after.data().AreaId ?? null,
          StreetId: change.after.data().StreetId ?? null,
          FamilyId: change.after.ref,
        });

        batch.update(change.after.data().StreetId, {
          LastEdit: change.after.data().LastEdit,
          LastEditTime: FieldValue.serverTimestamp(),
        });

        await batch.commit();

        if (
          changeType === "update" &&
          !(
            change.after.data().StreetId as FirebaseFirestore.DocumentReference
          ).isEqual(change.before?.data()?.StreetId)
        ) {
          console.log(
            `Updating Family Children: ${change.before.data().Name}, ${
              change.before.id
            }`
          );

          let pendingChanges = firestore().batch();
          const snapshot = await firestore()
            .collection("Persons")
            .where(
              "FamilyId",
              "==",
              firestore().doc("Families/" + context.params.family)
            )
            .get();

          if (
            (
              change.after.data().AreaId as FirebaseFirestore.DocumentReference
            ).isEqual(change.before?.data()?.AreaId)
          ) {
            for (let i = 0, l = snapshot.docs.length; i < l; i++) {
              if ((i + 1) % 500 === 0) {
                await pendingChanges.commit();
                pendingChanges = firestore().batch();
              }
              pendingChanges.update(snapshot.docs[i].ref, {
                LastEdit: change.after.data().LastEdit,
                StreetId: change.after.data().StreetId,
              });
            }
          } else {
            for (let i2 = 0, l2 = snapshot.docs.length; i2 < l2; i2++) {
              if ((i2 + 1) % 500 === 0) {
                await pendingChanges.commit();
                pendingChanges = firestore().batch();
              }
              pendingChanges.update(snapshot.docs[i2].ref, {
                LastEdit: change.after.data().LastEdit,
                StreetId: change.after.data().StreetId,
                AreaId: change.after.data().AreaId,
              });
            }
          }
          return pendingChanges.commit();
        }
      } else {
        console.log(
          `Deleting Family children: ${change.before.data().Name}, ${
            change.before.id
          }`
        );
        let pendingChanges = firestore().batch();
        const snapshot = await firestore()
          .collection("Persons")
          .where(
            "FamilyId",
            "==",
            firestore().doc("Families/" + context.params.family)
          )
          .get();
        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
          if ((i + 1) % 500 === 0) {
            await pendingChanges.commit();
            pendingChanges = firestore().batch();
          }
          pendingChanges.delete(snapshot.docs[i].ref);
        }
        const docID = new Date().toISOString().split("T")[0];
        await firestore()
          .collection("Deleted")
          .doc(docID)
          .set({ Time: Timestamp.now() });
        await firestore()
          .collection("Deleted")
          .doc(docID)
          .collection("Families")
          .doc(change.before.id)
          .set(change.before.data());
        return pendingChanges.commit();
      }
    } catch (err) {
      console.error(err);
      console.error(
        `Error occured while executing Family.onWrite on Family: ${
          change.before.data().Name
        }, ${change.before.id}`
      );
    }
    return null;
  });

export const onPersonChanged = functions.firestore
  .document("Persons/{person}")
  .onWrite(async (change) => {
    try {
      if (getChangeType(change) === "delete") {
        const docID = new Date().toISOString().split("T")[0];
        await firestore()
          .collection("Deleted")
          .doc(docID)
          .set({ Time: Timestamp.now() });
        return await firestore()
          .collection("Deleted")
          .doc(docID)
          .collection("Persons")
          .doc(change.before.id)
          .set(change.before.data());
      }
      const batch = firestore().batch();
      if (
        (change.after.data().LastTanawol as Timestamp)?.seconds !==
        (change.before?.data()?.LastTanawol as Timestamp)?.seconds
      ) {
        batch.create(change.after.ref.collection("TanawolHistory").doc(), {
          Time: change.after.data().LastTanawol,
          AreaId: change.after.data().AreaId ?? null,
          StreetId: change.after.data().StreetId ?? null,
          FamilyId: change.after.data().FamilyId ?? null,
          PersonId: change.after.ref,
        });
      }
      if (
        (change.after.data().LastConfession as Timestamp)?.seconds !==
        (change.before?.data()?.LastConfession as Timestamp)?.seconds
      ) {
        batch.create(change.after.ref.collection("ConfessionHistory").doc(), {
          Time: change.after.data().LastConfession,
          AreaId: change.after.data().AreaId ?? null,
          StreetId: change.after.data().StreetId ?? null,
          FamilyId: change.after.data().FamilyId ?? null,
          PersonId: change.after.ref,
        });
      }
      if (
        (change.after.data().LastCall as Timestamp)?.seconds !==
        (change.before?.data()?.LastCall as Timestamp)?.seconds
      ) {
        batch.create(change.after.ref.collection("CallHistory").doc(), {
          By: change.after.data().LastEdit,
          Time: change.after.data().LastCall,
          AreaId: change.after.data().AreaId ?? null,
          StreetId: change.after.data().StreetId ?? null,
          FamilyId: change.after.data().FamilyId ?? null,
          PersonId: change.after.ref,
        });
      }

      batch.create(change.after.ref.collection("EditHistory").doc(), {
        By: change.after.data().LastEdit,
        Time: FieldValue.serverTimestamp(),
        AreaId: change.after.data().AreaIdll ?? null,
        StreetId: change.after.data().StreetId ?? null,
        FamilyId: change.after.data().FamilyId ?? null,
        PersonId: change.after.ref,
      });

      batch.update(change.after.data().FamilyId, {
        LastEdit: change.after.data().LastEdit,
        LastEditTime: FieldValue.serverTimestamp(),
      });

      return await batch.commit();
    } catch (err) {
      console.error(err);
      console.error(
        `Error occured while executing Person.onWrite on Person: ${
          change.before.data().Name
        }, ${change.before.id}`
      );
    }
    return null;
  });

export const onInvitationCreated = functions.firestore
  .document("Invitations/{invitation}")
  .onCreate(async (change) => {
    await change.ref.update({
      Link: (
        await new FirebaseDynamicLinks(
          "{api key}" //TODO: replace with project Web API key
        ).createLink({
          dynamicLinkInfo: {
            domainUriPrefix: "https://churchdata.page.link",
            link: "https://churchdata.com/register?InvitationId=" + change.id,
            androidInfo: {
              androidPackageName: "com.AndroidQuartz.churchdata",
              androidFallbackLink:
                "https://github.com/Andrew-Bekhiet/ChurchData/releases/latest",
              androidMinPackageVersionCode: "3",
            },
          },
          suffix: { option: "UNGUESSABLE" },
        })
      ).shortLink,
    });
  });
