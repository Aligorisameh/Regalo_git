const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationOnNewMessage = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = context.params.chatId;

    // Fetch admin tokens
    const adminDevicesSnapshot = await admin.firestore().collection('adminDevices').get();
    const tokens = adminDevicesSnapshot.docs.map(doc => doc.data().token);

    const payload = {
      notification: {
        title: 'New Chat Message',
        body: `${message.sender} sent a new message`,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    // Send notifications to all tokens
    const response = await admin.messaging().sendToDevice(tokens, payload);
    console.log('Notification sent:', response);
  });
