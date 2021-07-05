import * as admin from "firebase-admin";
import {
  approveUser,
  deleteUser,
  getUsers,
  migrateTypesToDocRefs,
  correctRefs,
  registerUserData,
  resetPassword,
  updatePermissions,
  tempUpdateUserData,
  unApproveUser,
} from "./adminEndpoints";
import { onUserDeleted, userSignUp } from "./auth-triggers";
import {
  doBackupFirestoreData,
  updateStudyYears,
} from "./doBackupFirestoreData";
import { exportToExcel } from "./excelOperations";
import {
  onAreaChanged,
  onFamilyChanged,
  onInvitationCreated,
  onPersonChanged,
  onStreetChanged,
} from "./firestore-triggers";
import {
  changePassword,
  changeUserName,
  deleteImage,
  recoverDoc,
  registerAccount,
  registerFCMToken,
  registerWithLink,
  sendMessageToUsers,
} from "./userEndpoints";

admin.initializeApp();

exports.approveUser = approveUser;
exports.deleteUser = deleteUser;
exports.correctRefs = correctRefs;
exports.getUsers = getUsers;
exports.migrateTypesToDocRefs = migrateTypesToDocRefs;
exports.updatePermissions = updatePermissions;
exports.registerUserData = registerUserData;
exports.resetPassword = resetPassword;
exports.tempUpdateUserData = tempUpdateUserData;
exports.unApproveUser = unApproveUser;

exports.onUserDeleted = onUserDeleted;
exports.userSignUp = userSignUp;

exports.doBackupFirestoreData = doBackupFirestoreData;
exports.updateStudyYears = updateStudyYears;

exports.exportToExcel = exportToExcel;

exports.onAreaChanged = onAreaChanged;
exports.onFamilyChanged = onFamilyChanged;
exports.onInvitationCreated = onInvitationCreated;
exports.onPersonChanged = onPersonChanged;
exports.onStreetChanged = onStreetChanged;

exports.changePassword = changePassword;
exports.changeUserName = changeUserName;
exports.deleteImage = deleteImage;
exports.recoverDoc = recoverDoc;
exports.registerAccount = registerAccount;
exports.registerFCMToken = registerFCMToken;
exports.registerWithLink = registerWithLink;
exports.sendMessageToUsers = sendMessageToUsers;
