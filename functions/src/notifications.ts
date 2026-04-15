import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const sendChatNotification = functions.firestore
    .document('chatRooms/{roomId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        const roomId = context.params.roomId;

        if (!messageData) return;

        // 1. Get Room Data to find participants
        const roomDoc = await admin.firestore().collection('chatRooms').doc(roomId).get();
        const roomData = roomDoc.data();
        if (!roomData) return;

        const participants: string[] = roomData.participants || [];
        const senderId = messageData.senderId;
        const receiverId = participants.find(id => id !== senderId);

        if (!receiverId) return;

        // 2. Get Receiver's FCM Token and Status
        const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
        const userData = userDoc.data();
        
        if (!userData || !userData.fcmToken) return;
        
        // Don't send notification if user is currently active in this specific room
        // (Optional: requires updating 'currentRoomId' in Firestore when user enters a room)
        if (userData.isActive && userData.currentRoomId === roomId) return;

        // 3. Get Sender's Name
        const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
        const senderName = senderDoc.data()?.name || "مستخدم";

        const payload = {
            notification: {
                title: `رسالة جديدة من ${senderName}`,
                body: messageData.type === 'text' ? messageData.text : "أرسل لك وسائط 📷",
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
            data: {
                type: 'chat',
                roomId: roomId,
                senderId: senderId,
            }
        };

        return admin.messaging().sendToDevice(userData.fcmToken, payload);
    });

export const sendGiftNotification = functions.firestore
    .document('chatRooms/{roomId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        if (messageData?.type !== 'gift') return;

        const roomId = context.params.roomId;
        const roomDoc = await admin.firestore().collection('chatRooms').doc(roomId).get();
        const receiverId = roomDoc.data()?.participants?.find((id: string) => id !== messageData.senderId);

        if (!receiverId) return;

        const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
        const token = userDoc.data()?.fcmToken;
        if (!token) return;

        const senderDoc = await admin.firestore().collection('users').doc(messageData.senderId).get();
        const senderName = senderDoc.data()?.name || "مستخدم";

        const payload = {
            notification: {
                title: "هدية جديدة! 🎁",
                body: `لقد أرسل لك ${senderName} هدية: ${messageData.giftName}`,
            },
            data: {
                type: 'gift',
                roomId: roomId,
            }
        };

        return admin.messaging().sendToDevice(token, payload);
    });
