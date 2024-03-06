import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

export const doBackupFirestoreData = functions.pubsub
  .schedule("0 0 * * 0")
  .onRun(async () => {
    const firestore = require("@google-cloud/firestore");
    const client = new firestore.v1.FirestoreAdminClient();
    const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
    const databaseName = client.databasePath(projectId, "(default)");
    const timestamp = new Date().toISOString();

    console.log(
      `Starting backup project ${projectId} database ${databaseName} with name ${timestamp}`
    );

    return client
      .exportDocuments({
        name: databaseName,
        outputUriPrefix: `gs://${projectId}-firestore-backup/${timestamp}`,
        collectionIds: [
          "Areas",
          "Streets",
          "Families",
          "Persons",

          "Invitations",
          "Users",

          "Churches",
          "Classes",
          "Colleges",
          "Fathers",
          "Jobs",
          "Schools",
          "ServingTypes",
          "States",
          "StudyYears",
          "Types",

          "Kodas",
          "Meeting",
          "Confession",
          "ConfessionHistory",
          "Tanawol",
          "TanawolHistory",
          "VisitHistory",
          "CallHistory",
          "FatherVisitHistory",
        ],
      })
      .then(async (responses: any[]) => {
        const response = responses[0];
        console.log(`Operation Name: ${response["name"]}`);
        if (new Date().getDate() <= 7) {
          await admin
            .storage()
            .bucket("gs://" + projectId + ".appspot.com")
            .deleteFiles({ prefix: "Exports/" });
          await admin
            .storage()
            .bucket("gs://" + projectId + ".appspot.com")
            .deleteFiles({ prefix: "Imports/" });
          await admin
            .storage()
            .bucket("gs://" + projectId + ".appspot.com")
            .deleteFiles({ prefix: "Deleted/" });

          return await admin
            .firestore()
            .recursiveDelete(admin.firestore().collection("Deleted"));
        }
        return responses;
      })
      .catch((err: any) => {
        console.error(err);
        throw new Error("Export operation failed");
      });
  });

export const updateStudyYears = functions.pubsub
  .schedule("0 0 11 9 *")
  .onRun(async (context) => {
    const studyYears = await admin
      .firestore()
      .collection("StudyYears")
      .orderBy("Grade")
      .get();
    const firstYear = studyYears.docs[0].data();
    const lastYear = studyYears.docs[studyYears.docs.length - 1];
    const batch = admin.firestore().batch();

    for (let index = 1; index < studyYears.docs.length; index++) {
      batch.update(
        studyYears.docs[index - 1].ref,
        studyYears.docs[index].data()
      );
    }

    batch.set(admin.firestore().collection("StudyYears").doc(), firstYear);
    batch.update(lastYear.ref, {
      Grade: lastYear.data().Grade + 1,
      Name: "{تم ترحيل السنة برجاء ادخال اسم}",
      IsCollegeYear: lastYear.data().Grade + 1 > 12,
    });

    await batch.commit();
  });
