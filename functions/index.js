const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendOtp = functions.https.onCall(async (data, context) => {
  const phoneNumber = data.phoneNumber;
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  await admin.firestore().collection('otps').doc(phoneNumber).set({ otp, timestamp: admin.firestore.FieldValue.serverTimestamp() });

  const message = {
    notification: {
      title: 'Your OTP Code',
      body: `Your OTP code is ${otp}`,
    },
    token: data.fcmToken,
  };

  await admin.messaging().send(message);

  return { success: true };
});

exports.verifyOtp = functions.https.onCall(async (data, context) => {
  const phoneNumber = data.phoneNumber;
  const otp = data.otp;

  const otpDoc = await admin.firestore().collection('otps').doc(phoneNumber).get();
  if (!otpDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'OTP not found');
  }

  const storedOtp = otpDoc.data().otp;
  const timestamp = otpDoc.data().timestamp.toMillis();

  // Check if OTP is valid (e.g., within 5 minutes)
  const now = Date.now();
  if (storedOtp === otp && now - timestamp < 300000) {
    return { success: true };
  } else {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid OTP');
  }
});
