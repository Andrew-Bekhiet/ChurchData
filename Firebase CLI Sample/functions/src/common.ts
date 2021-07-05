import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export function isEqual(array, array2) {
  // if the other array is a falsy value, return
  if (!array || !array2) return false;

  // compare lengths - can save a lot of time
  if (array2.length !== array.length) return false;

  for (let i = 0, l = array2.length; i < l; i++) {
    if (!array2.includes(array[i])) {
      // Warning - two different object instances will never be equal: {x:20} !=={x:20}
      return false;
    }
  }
  return true;
}

export async function getFCMTokensForUser(
  uid: string
): Promise<string[] | string> {
  const token = (
    await admin
      .database()
      .ref("Users/" + uid + "/FCM_Tokens")
      .once("value")
  ).val();
  if (token === null || token === undefined) return [];
  console.log(token);
  console.log(Object.getOwnPropertyNames(token));
  return Object.getOwnPropertyNames(token);
}
export function assertNotEmpty(varName: string, variable: any, typeDef: any) {
  if (
    variable === null ||
    variable === undefined ||
    typeof variable !== typeDef
  )
    throw new functions.https.HttpsError(
      "invalid-argument",
      varName + " cannot be null or undefined and must be " + typeDef
    );
}

export function getChangeType(
  change: functions.Change<FirebaseFirestore.DocumentSnapshot>
): "create" | "update" | "delete" {
  const before: boolean = change.before.exists;
  const after: boolean = change.after.exists;

  if (before === false && after === true) {
    return "create";
  } else if (before === true && after === true) {
    return "update";
  } else if (before === true && after === false) {
    return "delete";
  } else {
    throw new Error(
      `Unkown firestore event! before: '${before}', after: '${after}'`
    );
  }
}
