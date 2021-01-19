import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue, Timestamp } from '@google-cloud/firestore';
import * as download from 'download';

admin.initializeApp();

//TODO: edit these varaibles
const adminPassword = '';
const packageName = 'com.example.app';

exports.doBackupFirestoreData = functions.pubsub.schedule('0 0 * * 0').onRun(async (context) => {
    const firestore = require('@google-cloud/firestore');
    const client = new firestore.v1.FirestoreAdminClient();
    const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
    const databaseName = client.databasePath(projectId, '(default)');
    const timestamp = new Date().toISOString();

    console.log(`Starting backup project ${projectId} database ${databaseName} with name ${timestamp}`);

    return client.exportDocuments({
        name: databaseName,
        outputUriPrefix: `gs://${projectId}/${timestamp}`,
        collectionIds: [],
    })
        .then(responses => {
            const response = responses[0];
            console.log(`Operation Name: ${response['name']}`);
            return responses;
        })
        .catch(err => {
            console.error(err);
            throw new Error('Export operation failed');
        });
});

//Call this Function if you wish to use 'DocumentReference' in the 'Type' field instead of 'String'
//استخدم هذه الدالة لاستبدال أنواع الأشخاص بالنوع DocumentReference بدلا من String
exports.migrateTypesToDocRefs = functions.https.onCall(async (data, context) => {
    let pendingChanges = admin.firestore().batch();
    const snapshot = await admin.firestore().collection('Persons').get();
    for (let i = 0, l = snapshot.docs.length; i < l; i++) {
        if ((i + 1) % 500 === 0) {
            await pendingChanges.commit();
            pendingChanges = admin.firestore().batch();
        }
        pendingChanges.update(snapshot.docs[i].ref, { 'Type': functions.firestore.document('Types/' + snapshot.docs[i].data().Type) });
    }
    return await pendingChanges.commit();
});

exports.userSignUp = functions.auth.user().onCreate(async (user) => {
    const customClaims = {
        password: null,         //Empty password
        manageUsers: false,     //Can manage Users' names, reset passwords and permissions
        superAccess: false,     //Can read everything
        write: true,           //Can write
        exportAreas: false,     //Can Export individual Areas to Excel sheet
        birthdayNotify: false,  //Can receive Birthday notifications
        confessionsNotify: false,  //Can receive Confessions notifications
        tanawolNotify: false,  //Can receive Tanawol notifications
        approveLocations: false,//Can Approve entities' locations
        approved: false,        //A User with 'Manage Users' permission must approve new users
        personRef: null,         //DocumentReference path to linked Person
    };
    await admin.messaging().sendToTopic('ManagingUsers',
        {
            notification:
            {
                title: 'قام ' + user.displayName + ' بتسجيل حساب بالبرنامج',
                body: 'ان كنت تعرف ' + user.displayName + 'فقم بتنشيط حسابه ليتمكن من الدخول للبرنامج',
            },
            data:
            {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                type: 'ManagingUsers',
                title: 'قام ' + user.displayName + ' بتسجيل حساب بالبرنامج',
                content: '',
                attachement: 'https://churchdata.page.link/viewUser?UID=' + user.uid,
                time: String(Date.now()),
            },
        },
        {
            timeToLive: 24 * 60 * 60, restrictedPackageName: packageName,
        }
    );
    await admin.auth().setCustomUserClaims(user.uid, customClaims);
    await download(user.photoURL, '/tmp/', { filename: user.uid + '.jpg' });
    return admin.storage().bucket().upload('/tmp/' + user.uid + '.jpg', {
        contentType: 'image/jpeg',
        destination: 'UsersPhotos/' + user.uid,
        gzip: true,
    });
});

exports.getUsers = functions.https.onCall(async (data, context) => {
    if (context.auth === undefined) {
        if (data.adminPassword === adminPassword) {
            return (await admin.auth().listUsers()).users.map((user, i, ary) => {
                const customClaims = user.customClaims;
                return Object.assign(customClaims, { uid: user.uid, name: user.displayName, email: user.email, phone: user.phoneNumber, photoUrl: user.photoURL });
            });
        }
        else {
            throw new functions.https.HttpsError("unauthenticated", '');
        }
    }
    const currentUser = (await admin.auth().getUser(context.auth.uid));
    if (currentUser.customClaims.approved && currentUser.customClaims.manageUsers) {
        return (await admin.auth().listUsers()).users.filter((user, i, arry) => { return !user.disabled }).map((user, i, ary) => {
            const customClaims = user.customClaims;
            delete customClaims.password;
            return Object.assign(customClaims, { uid: user.uid, name: user.displayName, email: user.email, phone: user.phoneNumber, photoUrl: user.photoURL });
        });
    } else if (currentUser.customClaims.approved) {
        return (await admin.auth().listUsers()).users.filter((user, i, arry) => { return !user.disabled && user.customClaims.approved }).map((user) => {
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

            return Object.assign(customClaims, { uid: user.uid, name: user.displayName, photoUrl: user.photoURL });
        });
    }
    throw new functions.https.HttpsError('unauthenticated', "Must be an approved user");
});

exports.registerUserData = functions.https.onCall(async (data, context) => {
    if (context.auth === undefined)
        throw new functions.https.HttpsError('unauthenticated', '')

    assertNotEmpty('data', data.data, typeof data.data);
    assertNotEmpty('data.Name', data.data.Name, typeof '');
    assertNotEmpty('data.Type', data.data.Type, typeof '');

    const userData = (await admin.auth().getUser(context.auth.uid)).customClaims;
    let docRef = admin.firestore().collection('Persons').doc();
    const personData = {
        FamilyId: null,
        StreetId: null,
        Name: data.data.Name,
        Phone: data.data.Phone,
        HasPhoto: data.data.HasPhoto,
        Color: data.data.Color,
        BirthDate: admin.firestore.Timestamp.fromMillis(data.data.BirthDate),
        BirthDay: admin.firestore.Timestamp.fromMillis(data.data.BirthDay),
        IsStudent: data.data.IsStudent,
        StudyYear: data.data.StudyYear !== null && data.data.StudyYear !== undefined && data.data.StudyYear !== '' ? admin.firestore().doc(data.data.StudyYear) : null,
        College: data.data.College !== null && data.data.College !== undefined && data.data.College !== '' ? admin.firestore().doc(data.data.College) : null,
        Job: data.data.Job !== null && data.data.Job !== undefined && data.data.Job !== '' ? admin.firestore().doc(data.data.Job) : null,
        JobDescription: data.data.JobDescription,
        Qualification: data.data.Qualification,
        Type: data.data.Type,
        Notes: data.data.Notes,
        IsServant: true,
        ServingAreaId: null,
        Church: data.data.Church !== null && data.data.Church !== undefined && data.data.Church !== '' ? admin.firestore().doc(data.data.Church) : null,
        Meeting: data.data.Meeting,
        CFather: data.data.CFather !== null && data.data.CFather !== undefined && data.data.CFather !== '' ? admin.firestore().doc(data.data.CFather) : null,
        State: null,
        ServingType: data.data.ServingType !== null && data.data.ServingType !== undefined && data.data.ServingType !== '' ? admin.firestore().doc(data.data.ServingType) : null,
        LastTanawol: admin.firestore.Timestamp.fromMillis(data.data.LastTanawol),
        LastConfession: admin.firestore.Timestamp.fromMillis(data.data.LastConfession),
        LastEdit: context.auth.uid,
    };
    if (userData.personRef === null || userData.personRef === undefined || userData.personRef === '') {
        await docRef.set(personData);
        userData.personRef = docRef.path;
        console.log(userData.personRef);
        await admin.auth().setCustomUserClaims(context.auth.uid, userData);
        return admin.database().ref().child('Users/' + context.auth.uid + '/forceRefresh').set(true);
    }
    console.log(userData.personRef);
    docRef = admin.firestore().doc(userData.personRef);
    return docRef.update(personData);
});

exports.approveUser = functions.https.onCall(async (data, context) => {
    const currentUser = (await admin.auth().getUser(context.auth.uid));
    if (currentUser.customClaims.approved && currentUser.customClaims.manageUsers) {
        assertNotEmpty('affectedUser', data.affectedUser, typeof '');
        const user = (await admin.auth().getUser(data.affectedUser));
        const newClaims = user.customClaims;
        newClaims.approved = true;
        await admin.auth().setCustomUserClaims(user.uid, newClaims);
        await admin.database().ref().child('Users/' + user.uid + '/forceRefresh').set(true);
        if (user.displayName === null) {
            return admin.firestore().doc('Users/' + user.uid).set({ 'Name': user.phoneNumber, 'ApproveLocations': false });
        }
        return admin.firestore().doc('Users/' + user.uid).set({ 'Name': user.displayName, 'ApproveLocations': false });
    }
    throw new functions.https.HttpsError('permission-denied', "Must be an approved user with 'manageUsers' permission");
});

exports.unApproveUser = functions.https.onCall(async (data, context) => {
    const currentUser = (await admin.auth().getUser(context.auth.uid));
    if (currentUser.customClaims.approved && currentUser.customClaims.manageUsers) {

        assertNotEmpty('affectedUser', data.affectedUser, typeof '');

        const user = (await admin.auth().getUser(data.affectedUser));
        await admin.auth().setCustomUserClaims(user.uid, {
            password: null,         //Empty password
            manageUsers: false,     //Can manage Users' names, reset passwords and permissions
            superAccess: false,     //Can read everything
            write: true,           //Can write
            exportAreas: false,     //Can Export individual Areas to Excel sheet
            birthdayNotify: false,  //Can receive Birthday notifications
            confessionsNotify: false,  //Can receive Confessions notifications
            tanawolNotify: false,  //Can receive Tanawol notifications
            approveLocations: false,//Can Approve entities' locations
            approved: false,        //A User with 'Manage Users' permission must approve new users
            personRef: null,         //DocumentReference path to linked Person
        });
        await admin.database().ref().child('Users/' + user.uid + '/forceRefresh').set(true);
        return admin.firestore().doc('Users/' + user.uid).delete();
    }
    throw new functions.https.HttpsError('permission-denied', "Must be an approved user with 'manageUsers' permission");
});

exports.resetPassword = functions.https.onCall(async (data, context) => {
    const currentUser = (await admin.auth().getUser(context.auth.uid));
    if (currentUser.customClaims.approved && currentUser.customClaims.manageUsers) {
        assertNotEmpty('affectedUser', data.affectedUser, typeof '');
        const user = (await admin.auth().getUser(data.affectedUser));
        const newClaims = user.customClaims;
        newClaims.password = null;
        await admin.auth().setCustomUserClaims(user.uid, newClaims);
        return admin.database().ref().child('Users/' + user.uid + '/forceRefresh').set(true);
    }
    throw new functions.https.HttpsError('permission-denied', "Must be an approved user with 'manageUsers' permission");
});

exports.changeUserName = functions.https.onCall(async (data, context) => {
    const currentUser = (await admin.auth().getUser(context.auth.uid));
    if (currentUser.customClaims.approved && currentUser.customClaims.manageUsers) {
        assertNotEmpty('newName', data.newName, typeof '');
        if (data.affectedUser !== null && data.affectedUser !== undefined && typeof data.affectedUser === typeof '') {
            await admin.auth().updateUser(data.affectedUser, { displayName: data.newName });
            return admin.firestore().doc('Users/' + data.affectedUser).update({ 'Name': data.newName });
        }
        else {
            await admin.auth().updateUser(context.auth.uid, { displayName: data.newName });
            return admin.firestore().doc('Users/' + context.auth.uid).update({ 'Name': data.newName });
        }
    }
    else if (currentUser.customClaims.approved) {
        assertNotEmpty('newName', data.newName, typeof '');
        await admin.auth().updateUser(context.auth.uid, { displayName: data.newName });
        return admin.firestore().doc('Users/' + context.auth.uid).update({ 'Name': data.newName });
    }
    throw new functions.https.HttpsError('permission-denied', "Must be an approved user with 'manageUsers' permission");
});

//Use this function to update Users tokens from the console
exports.tempUpdateUserData = functions.https.onCall(async (data, context) => {
    if (data.adminPassword !== adminPassword) return null;
    const newPermissions = data.permissions;
    const oldPermissions = (await admin.auth().getUser(data.affectedUser)).customClaims;
    if (newPermissions.approveLocations !== undefined && oldPermissions.approveLocations !== newPermissions.approveLocations) {
        await admin.firestore().doc('Users/' + data.affectedUser).update({ ApproveLocations: newPermissions.approveLocations });
    }
    await admin.auth().setCustomUserClaims(data.affectedUser, Object.assign(oldPermissions, newPermissions));
    return admin.database().ref().child('Users/' + data.affectedUser + '/forceRefresh').set(true);
});

exports.registerFCMToken = functions.https.onCall(async (data, context) => {
    if (context.auth === undefined) {
        throw new functions.https.HttpsError("unauthenticated", '');
    }
    assertNotEmpty('token', data.token, typeof '');
    await admin.database().ref('Users/' + context.auth.uid + '/FCM_Tokens').remove();
    await admin.database().ref('Users/' + context.auth.uid + '/FCM_Tokens/' + data.token).set('token');
    const currentUserClaims = (await admin.auth().getUser(context.auth.uid)).customClaims;
    if (currentUserClaims.approved && currentUserClaims.manageUsers && await getFCMTokenForUser(context.auth.uid) !== null) {
        await admin.messaging().subscribeToTopic(
            await getFCMTokenForUser(context.auth.uid),
            'ManagingUsers'
        );
    }
    if (currentUserClaims.approved && currentUserClaims.approveLocations && await getFCMTokenForUser(context.auth.uid) !== null) {
        await admin.messaging().subscribeToTopic(
            await getFCMTokenForUser(context.auth.uid),
            'ApproveLocations'
        );
    }
    return null;
});

exports.sendMessageToUsers = functions.https.onCall(async (data, context) => {
    let from: string;
    if (context.auth === undefined) {
        if (data.adminPassword === adminPassword) {
            from = '';
        }
        else {
            throw new functions.https.HttpsError("unauthenticated", '');
        }
    }
    else if ((await admin.auth().getUser(context.auth.uid)).customClaims.approved) {
        from = context.auth.uid;
    }
    else {
        throw new functions.https.HttpsError("unauthenticated", '');
    }
    assertNotEmpty('users', data.users, typeof []);
    assertNotEmpty('title', data.title, typeof '');
    assertNotEmpty('content', data.content, typeof '');
    assertNotEmpty('attachement', data.attachement, typeof '');
    let usersToSend: string[] = await Promise.all(data.users.map(async (user: any, i: any, ary: any) => await getFCMTokenForUser(user)));
    usersToSend = usersToSend.filter((v) => v !== null);
    return admin.messaging().sendToDevice(usersToSend,
        {
            notification:
            {
                title: data.title,
                body: data.body,
            },
            data:
            {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                type: 'Message',
                title: data.title,
                content: data.content,
                attachement: data.attachement,
                time: String(Date.now()),
                sentFrom: from,
            },
        },
        {
            timeToLive: 7 * 24 * 60 * 60, restrictedPackageName: packageName,
        }
    );
});

exports.updatePermissions = functions.https.onCall(async (data, context) => {
    const currentUser = (await admin.auth().getUser(context.auth.uid));
    if (currentUser.customClaims.approved && currentUser.customClaims.manageUsers) {
        const newPermissions = data.permissions;
        if (data.permissions.approved !== undefined)
            assertNotEmpty('permissions.approved', data.permissions.approved, typeof true);
        if (data.permissions.manageUsers !== undefined)
            assertNotEmpty('permissions.manageUsers', data.permissions.manageUsers, typeof true);
        if (data.permissions.superAccess !== undefined)
            assertNotEmpty('permissions.superAccess', data.permissions.superAccess, typeof true);
        if (data.permissions.write !== undefined)
            assertNotEmpty('permissions.write', data.permissions.write, typeof true);
        if (data.permissions.exportAreas !== undefined)
            assertNotEmpty('permissions.exportAreas', data.permissions.exportAreas, typeof true);
        if (data.permissions.approveLocations !== undefined)
            assertNotEmpty('permissions.approveLocations', data.permissions.approveLocations, typeof true);
        if (data.permissions.birthdayNotify !== undefined)
            assertNotEmpty('permissions.birthdayNotify', data.permissions.birthdayNotify, typeof true);
        if (data.permissions.confessionsNotify !== undefined)
            assertNotEmpty('permissions.confessionsNotify', data.permissions.confessionsNotify, typeof true);
        if (data.permissions.tanawolNotify !== undefined)
            assertNotEmpty('permissions.tanawolNotify', data.permissions.tanawolNotify, typeof true);
        if (data.permissions.personRef !== undefined)
            assertNotEmpty('permissions.personRef', data.permissions.personRef, typeof '');

        const oldPermissions = (await admin.auth().getUser(data.affectedUser)).customClaims;
        if (newPermissions.approveLocations !== undefined && oldPermissions.approveLocations !== newPermissions.approveLocations) {
            await admin.firestore().doc('Users/' + data.affectedUser).update({ ApproveLocations: newPermissions.approveLocations });
        }
        delete newPermissions.password;
        delete newPermissions.approved;
        if (oldPermissions.manageUsers !== newPermissions.manageUsers && await getFCMTokenForUser(data.affectedUser) !== null) {
            if (newPermissions.manageUsers) {
                await admin.messaging().subscribeToTopic(
                    await getFCMTokenForUser(data.affectedUser),
                    'ManagingUsers'
                );
            }
            else {
                await admin.messaging().unsubscribeFromTopic(
                    await getFCMTokenForUser(data.affectedUser),
                    'ManagingUsers'
                );
            }
        }
        if (oldPermissions.approveLocations !== newPermissions.approveLocations && await getFCMTokenForUser(data.affectedUser) !== null) {
            if (newPermissions.approveLocations) {
                await admin.messaging().subscribeToTopic(
                    await getFCMTokenForUser(data.affectedUser),
                    'ApproveLocations'
                );
            }
            else {
                await admin.messaging().unsubscribeFromTopic(
                    await getFCMTokenForUser(data.affectedUser),
                    'ApproveLocations'
                );
            }
        }
        await admin.auth().setCustomUserClaims(data.affectedUser, Object.assign(oldPermissions, newPermissions));
        return admin.database().ref().child('Users/' + data.affectedUser + '/forceRefresh').set(true);
    }
    throw new functions.https.HttpsError('permission-denied', "Must be an approved user with 'manageUsers' permission");
});

exports.changePassword = functions.https.onCall(async (data, context) => { //ChangePassword
    try {
        if (context.auth === undefined) {
            if (data.adMinpAsS !== '3L0^E^EpB!6okg7GF9#f%xw^m') {
                throw new functions.https.HttpsError("unauthenticated", '');
            }
        }
        else if (!(await admin.auth().getUser(context.auth.uid)).customClaims.approved) {
            throw new functions.https.HttpsError("unauthenticated", '');
        }
        const currentUser = (await admin.auth().getUser(context.auth.uid));
        const newCustomClaims = currentUser.customClaims;

        assertNotEmpty('newPassword', data.newPassword, typeof '');

        if (data.oldPassword !== null || (currentUser.customClaims.password === null && data.oldPassword === null)) {
            //TODO: Implement encryption Algorithms
            if (password !== currentUser.customClaims.password && currentUser.customClaims.password !== null) {
                throw new functions.https.HttpsError('permission-denied', 'Old Password is incorrect');
            }
        }
        else {
            throw new functions.https.HttpsError('permission-denied', 'Old Password is empty');
        }
        newCustomClaims['password'] = data.newPassword;
        await admin.auth().setCustomUserClaims(context.auth.uid, newCustomClaims);
        return admin.database().ref().child('Users/' + context.auth.uid + '/forceRefresh').set(true);
    } catch (err) {
        console.error(err);
        throw new functions.https.HttpsError('internal', '');
    }
});

exports.onAreaChanged = functions.firestore
    .document('Areas/{area}')
    .onWrite(async (change, context) => {
        try {
            const changeType = getChangeType(change);
            if (changeType === 'update' || changeType === 'create') {
                if (change.after.data().Location && !change.after.data().LocationConfirmed && !isEqual(change.before?.data()?.Location, change.after.data().Location)) {
                    console.log(`Sending location change notification on Area ${change.before.data().Name}, ${change.before.id}`)
                    await admin.messaging().sendToTopic('ApproveLocations',
                        {
                            notification:
                            {
                                title: 'يرجى تأكيد مكان منطقة ' + change.after.data().Name,
                                body: 'تم تغيير موقع ' + change.after.data().Name + ' بدون تأكيده على الخريطة',
                            },
                            data:
                            {
                                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                                type: 'ApproveLocation',
                                title: change.after.data().Name,
                                content: 'تم تغيير موقع ' + change.after.data().Name + ' بدون التأكد من الموقع' + '\n' + 'برجاء تأكيد الموقع',
                                attachement: 'https://churchdata.page.link/viewArea?AreaId=' + change.after.ref.id,
                                time: String(Date.now()),
                            },
                        },
                        {
                            timeToLive: 24 * 60 * 60, restrictedPackageName: packageName,
                        }
                    );
                }

                const batch = admin.firestore().batch();
                if ((change.after.data().LastVisit as Timestamp)?.seconds !== (change.before?.data()?.LastVisit as Timestamp)?.seconds) {
                    batch.create(change.after.ref.collection('VisitHistory').doc(), { 'By': change.after.data().LastEdit, 'Time': change.after.data().LastVisit });
                }
                if ((change.after.data().FatherLastVisit as Timestamp)?.seconds !== (change.before?.data()?.FatherLastVisit as Timestamp)?.seconds) {
                    batch.create(change.after.ref.collection('FatherVisitHistory').doc(), { 'By': change.after.data().LastEdit, 'Time': change.after.data().FatherLastVisit });
                }
                batch.create(change.after.ref.collection('EditHistory').doc(), { 'By': change.after.data().LastEdit, 'Time': FieldValue.serverTimestamp() });

                return await batch.commit();
            }
            else {
                console.log(`Deleting Area children: ${change.before.data().Name}, ${change.before.id}`);
                let pendingChanges = admin.firestore().batch();
                const snapshot = await admin.firestore().collection('Streets').where('AreaId', '==', admin.firestore().doc('Areas/' + context.params.area)).get();
                for (let i = 0, l = snapshot.docs.length; i < l; i++) {
                    if ((i + 1) % 500 === 0) {
                        await pendingChanges.commit();
                        pendingChanges = admin.firestore().batch();
                    }
                    pendingChanges.delete(snapshot.docs[i].ref);
                }
                return pendingChanges.commit();
            }
        } catch (err) {
            console.error(err);
            console.error(`Error occured while executing Area.onWrite on Area: ${change.before.data().Name}, ${change.before.id}`)
        }
        return null;
    });

exports.onStreetChanged = functions.firestore
    .document('Streets/{street}')
    .onWrite(async (change, context) => {
        try {
            const changeType = getChangeType(change);
            if (changeType === 'update' || changeType === 'create') {
                if (change.after.data().Location && !change.after.data().LocationConfirmed && !isEqual(change.before?.data()?.Location, change.after.data().Location)) {
                    console.log(`Sending location change notification on Street ${change.before.data().Name}, ${change.before.id}`)
                    await admin.messaging().sendToTopic('ApproveLocations',
                        {
                            notification:
                            {
                                title: 'يرجى تأكيد مكان شارع ' + change.after.data().Name,
                                body: 'تم تغيير موقع ' + change.after.data().Name + ' بدون تأكيده على الخريطة',
                            },
                            data:
                            {
                                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                                type: 'ApproveLocation',
                                title: change.after.data().Name,
                                content: 'تم تغيير موقع ' + change.after.data().Name + ' بدون التأكد من الموقع' + '\n' + 'برجاء تأكيد الموقع',
                                attachement: 'https://churchdata.page.link/viewStreet?StreetId=' + change.after.ref.id,
                                time: String(Date.now()),
                            },
                        },
                        {
                            timeToLive: 24 * 60 * 60, restrictedPackageName: packageName,
                        }
                    );
                }

                const batch = admin.firestore().batch();
                if ((change.after.data().LastVisit as Timestamp)?.seconds !== (change.before?.data()?.LastVisit as Timestamp)?.seconds) {
                    batch.create(change.after.ref.collection('VisitHistory').doc(), { 'By': change.after.data().LastEdit, 'Time': change.after.data().LastVisit });
                }
                if ((change.after.data().FatherLastVisit as Timestamp)?.seconds !== (change.before?.data()?.FatherLastVisit as Timestamp)?.seconds) {
                    batch.create(change.after.ref.collection('FatherVisitHistory').doc(), { 'By': change.after.data().LastEdit, 'Time': change.after.data().FatherLastVisit });
                }
                batch.create(change.after.ref.collection('EditHistory').doc(), { 'By': change.after.data().LastEdit, 'Time': FieldValue.serverTimestamp() });

                batch.update(change.after.data().AreaId, { 'LastEdit': change.after.data().LastEdit, 'LastEditTime': FieldValue.serverTimestamp() });

                await batch.commit();

                if (changeType === 'update' && !(change.after.data().AreaId as FirebaseFirestore.DocumentReference).isEqual(change.before?.data()?.AreaId)) {
                    console.log(`Updating Street Children: ${change.before.data().Name}, ${change.before.id}`);

                    let pendingChanges = admin.firestore().batch();

                    const snapshot = await admin.firestore().collection('Families').where('StreetId', '==', admin.firestore().doc('Streets/' + context.params.street)).get();
                    for (let i = 0, l = snapshot.docs.length; i < l; i++) {
                        if ((i + 1) % 500 === 0) {
                            await pendingChanges.commit();
                            pendingChanges = admin.firestore().batch();
                        }
                        pendingChanges.update(snapshot.docs[i].ref, { 'LastEdit': change.after.data().LastEdit, 'AreaId': change.after.data().AreaId });
                    }
                    return pendingChanges.commit();
                }
            }
            else {
                console.log(`Deleting Street children: ${change.before.data().Name}, ${change.before.id}`);
                let pendingChanges = admin.firestore().batch();
                const snapshot = await admin.firestore().collection('Families').where('StreetId', '==', admin.firestore().doc('Streets/' + context.params.street)).get();
                for (let i = 0, l = snapshot.docs.length; i < l; i++) {
                    if ((i + 1) % 500 === 0) {
                        await pendingChanges.commit();
                        pendingChanges = admin.firestore().batch();
                    }
                    pendingChanges.delete(snapshot.docs[i].ref);
                }
                return pendingChanges.commit();
            }
        } catch (err) {
            console.error(err);
            console.error(`Error occured while executing Street.onWrite on Street: ${change.before.data().Name}, ${change.before.id}`)
        }
        return null;
    });

exports.onFamilyChanged = functions.firestore
    .document('Families/{family}')
    .onWrite(async (change, context) => {
        try {
            const changeType = getChangeType(change);
            if (changeType === 'update' || changeType === 'create') {
                if (change.after.data().Location && !change.after.data().LocationConfirmed && change.before?.data()?.Location !== change.after.data().Location) {
                    console.log(`Sending location change notification on Family ${change.before.data().Name}, ${change.before.id}`)
                    await admin.messaging().sendToTopic('ApproveLocations',
                        {
                            notification:
                            {
                                title: 'يرجى تأكيد مكان عائلة ' + change.after.data().Name,
                                body: 'تم تغيير موقع ' + change.after.data().Name + ' بدون تأكيده على الخريطة',
                            },
                            data:
                            {
                                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                                type: 'ApproveLocation',
                                title: change.after.data().Name,
                                content: 'تم تغيير موقع ' + change.after.data().Name + ' بدون التأكد من الموقع' + '\n' + 'برجاء تأكيد الموقع',
                                attachement: 'https://churchdata.page.link/viewFamily?FamilyId=' + change.after.ref.id,
                                time: String(Date.now()),
                            },
                        },
                        {
                            timeToLive: 24 * 60 * 60, restrictedPackageName: packageName,
                        }
                    );
                }

                const batch = admin.firestore().batch();

                if ((change.after.data().LastVisit as Timestamp)?.seconds !== (change.before?.data()?.LastVisit as Timestamp)?.seconds) {
                    batch.create(change.after.ref.collection('VisitHistory').doc(), { 'By': change.after.data().LastEdit, 'Time': change.after.data().LastVisit });
                }
                if ((change.after.data().FatherLastVisit as Timestamp)?.seconds !== (change.before?.data()?.FatherLastVisit as Timestamp)?.seconds) {
                    batch.create(change.after.ref.collection('FatherVisitHistory').doc(), { 'By': change.after.data().LastEdit, 'Time': change.after.data().FatherLastVisit });
                }
                batch.create(change.after.ref.collection('EditHistory').doc(), { 'By': change.after.data().LastEdit, 'Time': FieldValue.serverTimestamp() });

                batch.update(change.after.data().StreetId, { 'LastEdit': change.after.data().LastEdit, 'LastEditTime': FieldValue.serverTimestamp() });

                await batch.commit();

                if (changeType === 'update' && !(change.after.data().StreetId as FirebaseFirestore.DocumentReference).isEqual(change.before?.data()?.StreetId)) {
                    console.log(`Updating Family Children: ${change.before.data().Name}, ${change.before.id}`);

                    let pendingChanges = admin.firestore().batch();
                    const snapshot = await admin.firestore().collection('Persons').where('FamilyId', '==', admin.firestore().doc('Families/' + context.params.family)).get();

                    if ((change.after.data().AreaId as FirebaseFirestore.DocumentReference).isEqual(change.before?.data()?.AreaId)) {
                        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
                            if ((i + 1) % 500 === 0) {
                                await pendingChanges.commit();
                                pendingChanges = admin.firestore().batch();
                            }
                            pendingChanges.update(snapshot.docs[i].ref, { 'LastEdit': change.after.data().LastEdit, 'StreetId': change.after.data().StreetId });
                        }
                    }
                    else {
                        for (let i2 = 0, l2 = snapshot.docs.length; i2 < l2; i2++) {
                            if ((i2 + 1) % 500 === 0) {
                                await pendingChanges.commit();
                                pendingChanges = admin.firestore().batch();
                            }
                            pendingChanges.update(snapshot.docs[i2].ref,
                                {
                                    'LastEdit': change.after.data().LastEdit,
                                    'StreetId': change.after.data().StreetId,
                                    'AreaId': change.after.data().AreaId,
                                });
                        }
                    }
                    return pendingChanges.commit();
                }
            } else {
                console.log(`Deleting Family children: ${change.before.data().Name}, ${change.before.id}`);
                let pendingChanges = admin.firestore().batch();
                const snapshot = await admin.firestore().collection('Persons').where('FamilyId', '==', admin.firestore().doc('Families/' + context.params.family)).get();
                for (let i = 0, l = snapshot.docs.length; i < l; i++) {
                    if ((i + 1) % 500 === 0) {
                        await pendingChanges.commit();
                        pendingChanges = admin.firestore().batch();
                    }
                    pendingChanges.delete(snapshot.docs[i].ref);
                }
                return pendingChanges.commit();
            }
        } catch (err) {
            console.error(err);
            console.error(`Error occured while executing Family.onWrite on Family: ${change.before.data().Name}, ${change.before.id}`)
        }
        return null;
    });

exports.onPersonChanged = functions.firestore
    .document('Persons/{person}')
    .onWrite(async (change) => {
        try {
            if (getChangeType(change) === 'delete') return null;
            const batch = admin.firestore().batch();
            if ((change.after.data().LastTanawol as Timestamp)?.seconds !== (change.before?.data()?.LastTanawol as Timestamp)?.seconds) {
                batch.create(change.after.ref.collection('TanawolHistory').doc(), { 'Time': change.after.data().LastTanawol });
            }
            if ((change.after.data().LastConfession as Timestamp)?.seconds !== (change.before?.data()?.LastConfession as Timestamp)?.seconds) {
                batch.create(change.after.ref.collection('ConfessionHistory').doc(), { 'Time': change.after.data().LastConfession });
            }

            batch.create(change.after.ref.collection('EditHistory').doc(), { 'By': change.after.data().LastEdit, 'Time': FieldValue.serverTimestamp() });

            batch.update(change.after.data().FamilyId, { 'LastEdit': change.after.data().LastEdit, 'LastEditTime': FieldValue.serverTimestamp() });

            return await batch.commit();
        } catch (err) {
            console.error(err);
            console.error(`Error occured while executing Person.onWrite on Person: ${change.before.data().Name}, ${change.before.id}`)
        }
        return null;
    });

exports.removeOldBirthDates = functions.https.onCall(async (data) => {
    try {
        let pendingChanges = admin.firestore().batch();
        let snapshot = await admin.firestore().collectionGroup('EditHistory')
            .where('Time', '>=', Timestamp.fromMillis(1609178280000))
            .where('Time', '<=', Timestamp.fromMillis(1609178400000))
            .get();

        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            console.log(`Added: ${snapshot.docs[i].data().By},  ${snapshot.docs[i].data().Time} for delete`);
            if ((i + 1) % 500 === 0) {
                console.log(`Commiting batch`);
                await pendingChanges.commit();
                pendingChanges = admin.firestore().batch();
            }
            pendingChanges.delete(snapshot.docs[i].ref);
        }
        await pendingChanges.commit();
        console.log('EditHistory1 Operation completed succesfully');

        pendingChanges = admin.firestore().batch();
        snapshot = await admin.firestore().collectionGroup('EditHistory')
            .where('Time', '>=', Timestamp.fromMillis(1609097400000))
            .where('Time', '<=', Timestamp.fromMillis(1609097520000))
            .get();

        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            console.log(`Added: ${snapshot.docs[i].data().By},  ${snapshot.docs[i].data().Time} for delete`);
            if ((i + 1) % 500 === 0) {
                console.log(`Commiting batch`);
                await pendingChanges.commit();
                pendingChanges = admin.firestore().batch();
            }
            pendingChanges.delete(snapshot.docs[i].ref);
        }
        await pendingChanges.commit();
        console.log('EditHistory2 Operation completed succesfully');

        pendingChanges = admin.firestore().batch();
        snapshot = await admin.firestore().collectionGroup('VisitHistory')
            .where('Time', '>=', Timestamp.fromMillis(1609178280000))
            .where('Time', '<=', Timestamp.fromMillis(1609178400000))
            .get();

        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            console.log(`Added: ${snapshot.docs[i].data().By},  ${snapshot.docs[i].data().Time} for delete`);
            if ((i + 1) % 500 === 0) {
                console.log(`Commiting batch`);
                await pendingChanges.commit();
                pendingChanges = admin.firestore().batch();
            }
            pendingChanges.delete(snapshot.docs[i].ref);
        }
        await pendingChanges.commit();
        console.log('VisitHistory1 Operation completed succesfully');

        pendingChanges = admin.firestore().batch();
        snapshot = await admin.firestore().collectionGroup('VisitHistory')
            .where('Time', '>=', Timestamp.fromMillis(1609097400000))
            .where('Time', '<=', Timestamp.fromMillis(1609097520000))
            .get();

        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            console.log(`Added: ${snapshot.docs[i].data().By},  ${snapshot.docs[i].data().Time} for delete`);
            if ((i + 1) % 500 === 0) {
                console.log(`Commiting batch`);
                await pendingChanges.commit();
                pendingChanges = admin.firestore().batch();
            }
            pendingChanges.delete(snapshot.docs[i].ref);
        }
        await pendingChanges.commit();
        console.log('VisitHistory2 Operation completed succesfully');

        pendingChanges = admin.firestore().batch();
        snapshot = await admin.firestore().collectionGroup('FatherVisitHistory')
            .where('Time', '>=', Timestamp.fromMillis(1609178280000))
            .where('Time', '<=', Timestamp.fromMillis(1609178400000))
            .get();

        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            console.log(`Added: ${snapshot.docs[i].data().By},  ${snapshot.docs[i].data().Time} for delete`);
            if ((i + 1) % 500 === 0) {
                console.log(`Commiting batch`);
                await pendingChanges.commit();
                pendingChanges = admin.firestore().batch();
            }
            pendingChanges.delete(snapshot.docs[i].ref);
        }
        await pendingChanges.commit();
        console.log('FatherVisitHistory1 Operation completed succesfully');

        pendingChanges = admin.firestore().batch();
        snapshot = await admin.firestore().collectionGroup('FatherVisitHistory')
            .where('Time', '>=', Timestamp.fromMillis(1609097400000))
            .where('Time', '<=', Timestamp.fromMillis(1609097520000))
            .get();

        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            console.log(`Added: ${snapshot.docs[i].data().By},  ${snapshot.docs[i].data().Time} for delete`);
            if ((i + 1) % 500 === 0) {
                console.log(`Commiting batch`);
                await pendingChanges.commit();
                pendingChanges = admin.firestore().batch();
            }
            pendingChanges.delete(snapshot.docs[i].ref);
        }
        await pendingChanges.commit();
        console.log('FatherVisitHistory2 Operation completed succesfully');



        pendingChanges = admin.firestore().batch();
        snapshot = await admin.firestore().collectionGroup('TanawolHistory')
            .where('Time', '>=', Timestamp.fromMillis(1609178280000))
            .where('Time', '<=', Timestamp.fromMillis(1609178400000))
            .get();

        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            console.log(`Added: ${snapshot.docs[i].data().By},  ${snapshot.docs[i].data().Time} for delete`);
            if ((i + 1) % 500 === 0) {
                console.log(`Commiting batch`);
                await pendingChanges.commit();
                pendingChanges = admin.firestore().batch();
            }
            pendingChanges.delete(snapshot.docs[i].ref);
        }
        await pendingChanges.commit();
        console.log('TanawolHistory1 Operation completed succesfully');

        pendingChanges = admin.firestore().batch();
        snapshot = await admin.firestore().collectionGroup('TanawolHistory')
            .where('Time', '>=', Timestamp.fromDate(new Date(2020, 12, 27, 23, 30)))
            .where('Time', '<=', Timestamp.fromDate(new Date(2020, 12, 27, 23, 32)))
            .get();

        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            console.log(`Added: ${snapshot.docs[i].data().By},  ${snapshot.docs[i].data().Time} for delete`);
            if ((i + 1) % 500 === 0) {
                console.log(`Commiting batch`);
                await pendingChanges.commit();
                pendingChanges = admin.firestore().batch();
            }
            pendingChanges.delete(snapshot.docs[i].ref);
        }
        await pendingChanges.commit();
        console.log('TanawolHistory2 Operation completed succesfully');


        pendingChanges = admin.firestore().batch();
        snapshot = await admin.firestore().collectionGroup('ConfessionHistory')
            .where('Time', '>=', Timestamp.fromDate(new Date(2020, 12, 28, 21, 58)))
            .where('Time', '<=', Timestamp.fromDate(new Date(2020, 12, 28, 22, 0)))
            .get();

        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            console.log(`Added: ${snapshot.docs[i].data().By},  ${snapshot.docs[i].data().Time} for delete`);
            if ((i + 1) % 500 === 0) {
                console.log(`Commiting batch`);
                await pendingChanges.commit();
                pendingChanges = admin.firestore().batch();
            }
            pendingChanges.delete(snapshot.docs[i].ref);
        }
        await pendingChanges.commit();
        console.log('ConfessionHistory1 Operation completed succesfully');

        pendingChanges = admin.firestore().batch();
        snapshot = await admin.firestore().collectionGroup('ConfessionHistory')
            .where('Time', '>=', Timestamp.fromDate(new Date(2020, 12, 27, 23, 30)))
            .where('Time', '<=', Timestamp.fromDate(new Date(2020, 12, 27, 23, 32)))
            .get();

        for (let i = 0, l = snapshot.docs.length; i < l; i++) {
            console.log(`Added: ${snapshot.docs[i].data().By},  ${snapshot.docs[i].data().Time} for delete`);
            if ((i + 1) % 500 === 0) {
                console.log(`Commiting batch`);
                await pendingChanges.commit();
                pendingChanges = admin.firestore().batch();
            }
            pendingChanges.delete(snapshot.docs[i].ref);
        }
        await pendingChanges.commit();
        console.log('ConfessionHistory2 Operation completed succesfully');

    } catch (err) {
        console.error(err);
        console.log('Error occured while performing operation removeOldBirthDates');
    }
});
function isEqual(array, array2) {
    // if the other array is a falsy value, return
    if (!array || !array2)
        return false;

    // compare lengths - can save a lot of time 
    if (array2.length !== array.length)
        return false;

    for (let i = 0, l = array2.length; i < l; i++) {
        if (!array2.includes(array[i])) {
            // Warning - two different object instances will never be equal: {x:20} !=={x:20}
            return false;
        }
    }
    return true;
}

async function getFCMTokenForUser(uid) {
    const token = (await admin.database().ref('Users/' + uid + '/FCM_Tokens').once("value")).val();
    if (token === null || token === undefined) return null;
    return Object.entries(token)[0][0];
}

function assertNotEmpty(varName: string, variable: any, typeDef: any) {
    if (variable === null || variable === undefined || typeof variable !== typeDef)
        throw new functions.https.HttpsError('invalid-argument', varName + ' cannot be null or undefined and must be ' + typeDef);
}

function getChangeType(change: functions.Change<FirebaseFirestore.DocumentSnapshot>): 'create' | 'update' | 'delete' {
    const before: boolean = change.before.exists;
    const after: boolean = change.after.exists;

    if (before === false && after === true) {
        return 'create';
    } else if (before === true && after === true) {
        return 'update';
    } else if (before === true && after === false) {
        return 'delete';
    } else {
        throw new Error(`Unkown firestore event! before: '${before}', after: '${after}'`);
    }
}