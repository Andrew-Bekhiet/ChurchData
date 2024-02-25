import { runWith } from "firebase-functions";
import { HttpsError } from "firebase-functions/lib/providers/https";

import { Timestamp } from "@google-cloud/firestore";
import { auth, firestore, storage } from "firebase-admin";

import * as xlsx from "xlsx";
// import * as download from "download";

import { assertNotEmpty } from "./common";

export const exportToExcel = runWith({
  memory: "512MB",
  timeoutSeconds: 540,
}).https.onCall(async (data, context) => {
  if (context.auth === undefined) {
    throw new HttpsError("unauthenticated", "");
  }
  const currentUser = await auth().getUser(context.auth.uid);
  if (
    !(currentUser.customClaims.approved && currentUser.customClaims.exportAreas)
  ) {
    throw new HttpsError(
      "permission-denied",
      'Must be approved user with "Export Areas" permission'
    );
  }

  let area: FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>;
  console.log(currentUser);
  console.log(data);

  if (data?.onlyArea) {
    assertNotEmpty("onlyArea", data?.onlyArea, typeof "");
    area = await firestore().collection("Areas").doc(data?.onlyArea).get();
    if (!currentUser.customClaims.superAccess) {
      if (
        !area.exists ||
        !(area.data().Allowed as string[]).includes(currentUser.uid)
      )
        throw new HttpsError(
          "permission-denied",
          "User doesn't have permission to export the required area"
        );
    }
  }

  console.log(
    "Starting export operation from user: " +
      context.auth.uid +
      " for " +
      (data?.onlyArea
        ? "area: " + data?.onlyArea
        : "all data avaliable for the user")
  );

  const users = (await firestore().collection("Users").get()).docs.reduce(
    (map, obj) => {
      map[obj.id] = obj.data().Name ?? "(غير معروف)";
      return map;
    },
    {}
  );

  const studyYears = (
    await firestore().collection("StudyYears").get()
  ).docs.reduce((map, obj, {}) => {
    map[obj.id] = obj.data().Name ?? "(غير معروف)";
    return map;
  });
  const colleges = (await firestore().collection("Colleges").get()).docs.reduce(
    (map, obj) => {
      map[obj.id] = obj.data().Name ?? "(غير معروف)";
      return map;
    },
    {}
  );
  const jobs = (await firestore().collection("Jobs").get()).docs.reduce(
    (map, obj) => {
      map[obj.id] = obj.data().Name ?? "(غير معروف)";
      return map;
    },
    {}
  );
  const types = (await firestore().collection("Types").get()).docs.reduce(
    (map, obj) => {
      map[obj.id] = obj.data().Name ?? "(غير معروف)";
      return map;
    },
    {}
  );
  const churches = (await firestore().collection("Churches").get()).docs.reduce(
    (map, obj) => {
      map[obj.id] = obj.data().Name ?? "(غير معروف)";
      return map;
    },
    {}
  );
  const cfathers = (await firestore().collection("Fathers").get()).docs.reduce(
    (map, obj) => {
      map[obj.id] = obj.data().Name ?? "(غير معروف)";
      return map;
    },
    {}
  );
  const states = (await firestore().collection("States").get()).docs.reduce(
    (map, obj) => {
      map[obj.id] = obj.data().Name ?? "(غير معروف)";
      return map;
    },
    {}
  );
  const servingTypes = (
    await firestore().collection("ServingTypes").get()
  ).docs.reduce((map, obj, {}) => {
    map[obj.id] = obj.data().Name ?? "(غير معروف)";
    return map;
  });

  let areas: Map<String, Map<String, any>> = new Map<
    String,
    Map<String, any>
  >();
  if (data?.onlyArea) {
    const rslt = {};
    rslt["Name"] = area.data()["Name"];
    rslt["Address"] = area.data()["Address"];
    rslt["Last Visit"] =
      (area.data()["LastVisit"] as Timestamp)?.toDate() ?? "";
    rslt["Father Last Visit"] =
      (area.data()["FatherLastVisit"] as Timestamp)?.toDate() ?? "";
    rslt["Last Edit"] = users[area.data()["LastEdit"]] ?? "";
    rslt["Allowed Users"] =
      (area.data()["Allowed"] as string[])
        ?.map((u) => users[u] ?? "(غير معروف)")
        ?.reduce((arr, o) => arr + "," + o) ?? "";
    areas[area.id] = rslt;
  } else {
    areas = (
      currentUser.customClaims.superAccess
        ? await firestore().collection("Areas").orderBy("Name").get()
        : await firestore()
            .collection("Areas")
            .where("Allowed", "array-contains", currentUser.uid)
            .orderBy("Name")
            .get()
    ).docs.reduce<Map<String, Map<String, any>>>((map, a) => {
      const rslt = {};
      //'Name', 'Address', 'LastVisit','FatherLastVisit','LastEdit','Allowed'
      rslt["Name"] = a.data()["Name"];
      rslt["Address"] = a.data()["Address"];
      rslt["Last Visit"] = (a.data()["LastVisit"] as Timestamp)?.toDate() ?? "";
      rslt["Father Last Visit"] =
        (a.data()["FatherLastVisit"] as Timestamp)?.toDate() ?? "";
      rslt["Last Edit"] = users[a.data()["LastEdit"]] ?? "";
      rslt["Allowed Users"] =
        (a.data()["Allowed"] as string[])
          ?.map((u) => users[u] ?? "(غير معروف)")
          ?.reduce((arr, o) => arr + "," + o) ?? "";
      map[a.id] = rslt;
      return map;
    }, new Map<String, Map<String, any>>());
  }

  const streets = (
    data?.onlyArea
      ? await firestore()
          .collection("Streets")
          .where("AreaId", "==", area.ref)
          .orderBy("Name")
          .get()
      : currentUser.customClaims.superAccess
      ? await firestore().collection("Streets").orderBy("Name").get()
      : await firestore()
          .collection("Streets")
          .where(
            "AreaId",
            "in",
            Object.keys(areas).map((a) =>
              firestore().collection("Areas").doc(a)
            )
          )
          .orderBy("Name")
          .get()
  ).docs.reduce<Map<String, Map<String, any>>>((map, s) => {
    const rslt = {};
    rslt["Inside Area"] =
      areas[(s.data()["AreaId"] as firestore.DocumentReference)?.id]?.Name ??
      "(غير موجودة)";
    rslt["Name"] = s.data()["Name"];
    rslt["Last Visit"] = (s.data()["LastVisit"] as Timestamp)?.toDate() ?? "";
    rslt["Father Last Visit"] =
      (s.data()["FatherLastVisit"] as Timestamp)?.toDate() ?? "";
    rslt["Last Edit"] = users[s.data()["LastEdit"]] ?? "";
    map[s.id] = rslt;
    return map;
  }, new Map<String, Map<String, any>>());

  const familiesMap = (
    currentUser.customClaims.superAccess
      ? await firestore().collection("Families").orderBy("Name").get()
      : await firestore()
          .collection("Families")
          .where(
            "AreaId",
            "in",
            Object.keys(areas).map((a) =>
              firestore().collection("Areas").doc(a)
            )
          )
          .orderBy("Name")
          .get()
  ).docs.reduce<Map<String, Map<String, any>>>((map, f) => {
    map[f.id] = f.data();
    return map;
  }, new Map<String, Map<String, any>>());

  const families = (
    data?.onlyArea
      ? await firestore()
          .collection("Families")
          .where("AreaId", "==", area.ref)
          .orderBy("Name")
          .get()
      : currentUser.customClaims.superAccess
      ? await firestore().collection("Families").orderBy("Name").get()
      : await firestore()
          .collection("Families")
          .where(
            "AreaId",
            "in",
            Object.keys(areas).map((a) =>
              firestore().collection("Areas").doc(a)
            )
          )
          .orderBy("Name")
          .get()
  ).docs.reduce<Map<String, Map<String, any>>>((map, f) => {
    const rslt = {};
    rslt["Inside Area"] =
      areas[(f.data()["AreaId"] as firestore.DocumentReference)?.id]?.Name ??
      "(غير موجودة)";
    rslt["Inside Street"] =
      streets[(f.data()["StreetId"] as firestore.DocumentReference)?.id]
        ?.Name ?? "(غير موجود)";
    rslt["Inside Family"] =
      familiesMap[
        (f.data()["InsideFamily"] as firestore.DocumentReference)?.id
      ]?.Name;
    rslt["Inside Family 2"] =
      familiesMap[
        (f.data()["InsideFamily2"] as firestore.DocumentReference)?.id
      ]?.Name;
    rslt["Is Store"] = f.data()["IsStore"];
    rslt["Name"] = f.data()["Name"];
    rslt["Address"] = f.data()["Address"];
    rslt["Notes"] = f.data()["Notes"];
    rslt["LastVisit"] = (f.data()["LastVisit"] as Timestamp)?.toDate() ?? "";
    rslt["FatherLastVisit"] =
      (f.data()["FatherLastVisit"] as Timestamp)?.toDate() ?? "";
    rslt["LastEdit"] = users[f.data()["LastEdit"]] ?? "";
    map[f.id] = rslt;
    return map;
  }, new Map<String, Map<String, any>>());

  const persons = (
    data?.onlyArea
      ? await firestore()
          .collection("Persons")
          .where("AreaId", "==", area.ref)
          .orderBy("Name")
          .get()
      : currentUser.customClaims.superAccess
      ? await firestore().collection("Persons").orderBy("Name").get()
      : await firestore()
          .collection("Persons")
          .where(
            "AreaId",
            "in",
            Object.keys(areas).map((a) =>
              firestore().collection("Areas").doc(a)
            )
          )
          .orderBy("Name")
          .get()
  ).docs.reduce<Map<String, Map<String, any>>>((map, p) => {
    const rslt = {};
    rslt["Inside Area"] =
      areas[(p.data()["AreaId"] as firestore.DocumentReference)?.id]?.Name ??
      "(غير موجودة)";
    rslt["Inside Street"] =
      streets[(p.data()["StreetId"] as firestore.DocumentReference)?.id]
        ?.Name ?? "(غير موجود)";
    rslt["Inside Family"] =
      families[(p.data()["FamilyId"] as firestore.DocumentReference)?.id]
        ?.Name ?? "(غير موجودة)";
    rslt["Name"] = p.data()["Name"];
    rslt["Phone Number"] = p.data()["Phone"];
    Object.assign(rslt, p.data()["Phones"]);

    rslt["Birth Date"] = (p.data()["BirthDate"] as Timestamp)?.toDate() ?? "";
    rslt["Is Student"] = p.data()["IsStudent"];
    rslt["Study Year"] =
      studyYears[(p.data()["StudyYear"] as firestore.DocumentReference)?.id];
    rslt["College"] =
      colleges[(p.data()["College"] as firestore.DocumentReference)?.id];
    rslt["Job"] = jobs[(p.data()["Job"] as firestore.DocumentReference)?.id];
    rslt["Job Description"] = p.data()["JobDescription"];
    rslt["Qualification"] = p.data()["Qualification"];
    rslt["Type"] = types[p.data()["Type"]];
    rslt["Notes"] = p.data()["Notes"];
    rslt["Is Servant"] = p.data()["IsServant"];
    rslt["Serving Area"] =
      areas[(p.data()["ServingAreaId"] as firestore.DocumentReference)?.id];
    rslt["Church"] =
      churches[(p.data()["Church"] as firestore.DocumentReference)?.id];
    rslt["Meeting"] = p.data()["Meeting"];
    rslt["Confession Father"] =
      cfathers[(p.data()["CFather"] as firestore.DocumentReference)?.id];
    rslt["State"] =
      states[(p.data()["State"] as firestore.DocumentReference)?.id];
    rslt["Serving Type"] =
      servingTypes[
        (p.data()["ServingType"] as firestore.DocumentReference)?.id
      ];
    rslt["Last Tanawol"] =
      (p.data()["LastTanawol"] as Timestamp)?.toDate() ?? "";
    rslt["Last Call"] = (p.data()["LastCall"] as Timestamp)?.toDate() ?? "";
    rslt["Last Confession"] =
      (p.data()["LastConfession"] as Timestamp)?.toDate() ?? "";
    rslt["Last Edit"] = users[p.data()["LastEdit"]] ?? "";
    map[p.id] = rslt;
    return map;
  }, new Map<String, Map<String, any>>());

  const book = xlsx.utils.book_new();
  xlsx.utils.book_append_sheet(
    book,
    xlsx.utils.json_to_sheet(Object.values(areas)),
    "Areas"
  );
  xlsx.utils.book_append_sheet(
    book,
    xlsx.utils.json_to_sheet(Object.values(streets)),
    "Streets"
  );
  xlsx.utils.book_append_sheet(
    book,
    xlsx.utils.json_to_sheet(Object.values(families)),
    "Families"
  );
  xlsx.utils.book_append_sheet(
    book,
    xlsx.utils.json_to_sheet(Object.values(persons)),
    "Persons"
  );
  await xlsx.writeFile(book, "/tmp/Export.xlsx");
  const file = (
    await storage()
      .bucket()
      .upload("/tmp/Export.xlsx", {
        destination: "Exports/Export-" + new Date().toISOString() + ".xlsx",
        gzip: true,
      })
  )[0];
  await file.setMetadata({ metadata: { createdBy: currentUser.uid } });
  return file.id;
});
