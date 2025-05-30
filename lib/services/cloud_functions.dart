// // functions/index.js
// const functions = require("firebase-functions");
// const admin = require("firebase-admin");
// admin.initializeApp();

// exports.deleteUserById = functions.https.onCall(async (data, context) => {
//   // تحقق أن المستخدم يملك صلاحيات كافية (مثلاً Admin)
//   if (!context.auth || !context.auth.token.admin) {
//     throw new functions.https.HttpsError('permission-denied', 'غير مصرح');
//   }

//   const uid = data.uid;

//   try {
//     await admin.auth().deleteUser(uid);
//     return { message: 'تم حذف المستخدم' };
//   } catch (error) {
//     throw new functions.https.HttpsError('internal', error.message);
//   }
// });
