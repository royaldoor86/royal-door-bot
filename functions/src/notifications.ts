import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const androidConfig = {
  notification: {
    channelId: "high_importance_channel",
    clickAction: "FLUTTER_NOTIFICATION_CLICK",
    sound: "default",
  },
};

// 1. Enhanced Chat Notification
export const sendChatNotification = functions.firestore
  .document("chatRooms/{roomId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    if (!messageData || messageData.type === "gift") {
      return null;
    }

    const roomId = context.params.roomId;
    const roomDoc = await admin.firestore().collection("chatRooms").doc(roomId).get();
    const roomData = roomDoc.data();
    if (!roomData) {
      return null;
    }

    const participants: string[] = roomData.participants || [];
    const senderId = messageData.senderId;

    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderName = senderDoc.data()?.name || "مستخدم";

    const message: admin.messaging.MulticastMessage = {
      notification: {
        title: roomData.isGroup ? `${roomData.groupName}` : senderName,
        body: roomData.isGroup ? `${senderName}: ${messageData.text}` : messageData.text,
      },
      android: androidConfig,
      data: {type: "chat", roomId: roomId},
      tokens: [],
    };

    const tokens: string[] = [];
    for (const uid of participants) {
      if (uid === senderId) {
        continue;
      }
      const userDoc = await admin.firestore().collection("users").doc(uid).get();
      const userData = userDoc.data();
      if (userData?.fcmToken && (!userData.isActive || userData.currentRoomId !== roomId)) {
        tokens.push(userData.fcmToken);
      }
    }

    if (tokens.length > 0) {
      message.tokens = tokens;
      return admin.messaging().sendEachForMulticast(message);
    }
    return null;
  });

// 2. Friend Request Notification
export const sendFriendRequestNotification = functions.firestore
  .document("friendRequests/{requestId}")
  .onCreate(async (snapshot) => {
    const data = snapshot.data();
    if (!data || data.status !== "pending") {
      return null;
    }

    const receiverDoc = await admin.firestore().collection("users").doc(data.receiverId).get();
    const token = receiverDoc.data()?.fcmToken;
    if (!token) {
      return null;
    }

    const senderDoc = await admin.firestore().collection("users").doc(data.senderId).get();
    const senderName = senderDoc.data()?.name || "مستخدم";

    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: "طلب صداقة جديد 🤝",
        body: `يرغب ${senderName} في إضافتك لقائمة أصدقائه`,
      },
      android: androidConfig,
      data: {type: "friend_request", senderId: data.senderId},
    };

    return admin.messaging().send(message);
  });

// 3. Profile Visitor Notification
export const sendVisitorNotification = functions.firestore
  .document("users/{userId}/visitors/{visitorId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) {
      return null;
    }

    const userId = context.params.userId;
    const visitorId = context.params.visitorId;
    if (userId === visitorId) {
      return null;
    }

    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) {
      return null;
    }

    const visitorDoc = await admin.firestore().collection("users").doc(visitorId).get();
    const visitorName = visitorDoc.data()?.name || "شخص ما";

    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: "زائر جديد 👀",
        body: `قام ${visitorName} بزيارة بروفايلك الآن`,
      },
      android: androidConfig,
      data: {type: "visitor", visitorId: visitorId},
    };

    return admin.messaging().send(message);
  });

// 4. Follow Notification
export const sendFollowNotification = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    
    const beforeFollowers = before.followers || [];
    const afterFollowers = after.followers || [];

    const newFollowerId = afterFollowers.find((id: string) => !beforeFollowers.includes(id));
    if (!newFollowerId) {
      return null;
    }

    if (!after.fcmToken) {
      return null;
    }

    const followerDoc = await admin.firestore().collection("users").doc(newFollowerId).get();
    const followerName = followerDoc.data()?.name || "متابع جديد";

    const message: admin.messaging.Message = {
      token: after.fcmToken,
      notification: {
        title: "متابع جديد ✨",
        body: `بدأ ${followerName} بمتابعتك الآن`,
      },
      android: androidConfig,
      data: {type: "follow", followerId: newFollowerId},
    };

    return admin.messaging().send(message);
  });

// 5. Gift Notification
export const sendGiftNotification = functions.firestore
  .document("chatRooms/{roomId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    if (messageData?.type !== "gift") {
      return null;
    }

    const roomId = context.params.roomId;
    const roomDoc = await admin.firestore().collection("chatRooms").doc(roomId).get();
    const receiverId = roomDoc.data()?.participants?.find((id: string) => id !== messageData.senderId);

    if (!receiverId) {
      return null;
    }

    const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) {
      return null;
    }

    const senderDoc = await admin.firestore().collection("users").doc(messageData.senderId).get();
    const senderName = senderDoc.data()?.name || "مستخدم";

    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: "هدية جديدة! 🎁",
        body: `لقد أرسل لك ${senderName} هدية: ${messageData.giftName}`,
      },
      android: androidConfig,
      data: {type: "gift", roomId: roomId},
    };

    return admin.messaging().send(message);
  });

// 6. Mic Invite Notification
export const sendMicInviteNotification = functions.firestore
  .document("rooms/{roomId}/mic_invites/{inviteId}")
  .onCreate(async (snapshot, context) => {
    const inviteData = snapshot.data();
    if (!inviteData) {
      return null;
    }

    const userDoc = await admin.firestore().collection("users").doc(inviteData.toUserId).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) {
      return null;
    }

    const senderDoc = await admin.firestore().collection("users").doc(inviteData.fromUserId).get();
    const senderName = senderDoc.data()?.name || "مستخدم";

    const roomDoc = await admin.firestore().collection("rooms").doc(context.params.roomId).get();
    const roomName = roomDoc.data()?.name || "غرفة صوتية";

    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: "دعوة للمايك 🎤",
        body: `يدعوك ${senderName} للتحدث في غرفة ${roomName}`,
      },
      android: androidConfig,
      data: {
        type: "mic_invite",
        roomId: context.params.roomId,
        seat: inviteData.seat.toString(),
      },
    };

    return admin.messaging().send(message);
  });

// 7. New Post Notification
export const sendNewPostNotification = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snapshot) => {
    const postData = snapshot.data();
    if (!postData) {
      return null;
    }

    const authorDoc = await admin.firestore().collection("users").doc(postData.authorId).get();
    const authorName = authorDoc.data()?.name || "صديقك";
    const followers = authorDoc.data()?.followers || [];
    if (followers.length === 0) {
      return null;
    }

    const tokens: string[] = [];
    const users = await admin.firestore().collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", followers.slice(0, 10))
      .get();
    
    users.forEach((u) => {
      if (u.data().fcmToken) {
        tokens.push(u.data().fcmToken);
      }
    });

    if (tokens.length === 0) {
      return null;
    }

    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: "يوميات جديدة 📸",
        body: `نشر ${authorName} منشوراً جديداً، ألقِ نظرة!`,
      },
      android: androidConfig,
      data: {type: "post", postId: snapshot.id},
    };

    return admin.messaging().sendEachForMulticast(message);
  });

// 8. Room Battle Notification
export const sendBattleNotification = functions.firestore
  .document("rooms/{roomId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before.battle?.active && after.battle?.active === true) {
      const followersSnap = await admin.firestore().collection("rooms").doc(context.params.roomId).collection("followers").get();
      const uids = followersSnap.docs.map((doc) => doc.id);
      if (uids.length === 0) {
        return null;
      }

      const users = await admin.firestore().collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", uids.slice(0, 10))
        .get();
      
      const tokens: string[] = [];
      users.forEach((u) => {
        if (u.data().fcmToken) {
          tokens.push(u.data().fcmToken);
        }
      });

      if (tokens.length === 0) {
        return null;
      }

      const message: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title: "بداية معركة! ⚔️",
          body: `بدأت معركة حماسية الآن في غرفة ${after.name}، انضم للدعم!`,
        },
        android: androidConfig,
        data: {type: "room", roomId: context.params.roomId},
      };

      return admin.messaging().sendEachForMulticast(message);
    }
    return null;
  });

// 9. Interaction Notification
export const sendInteractionNotification = functions.firestore
  .document("posts/{postId}/comments/{commentId}")
  .onCreate(async (snapshot, context) => {
    const comment = snapshot.data();
    if (!comment) {
      return null;
    }

    const postDoc = await admin.firestore().collection("posts").doc(context.params.postId).get();
    const authorId = postDoc.data()?.authorId;
    if (!authorId || authorId === comment.userId) {
      return null;
    }

    const authorDoc = await admin.firestore().collection("users").doc(authorId).get();
    const token = authorDoc.data()?.fcmToken;
    if (!token) {
      return null;
    }

    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: "تعليق جديد 💬",
        body: `علق ${comment.userName} على منشورك`,
      },
      android: androidConfig,
      data: {type: "post", postId: context.params.postId},
    };

    return admin.messaging().send(message);
  });

// 10. Story Interaction
export const sendStoryInteractionNotification = functions.firestore
  .document("stories/{storyId}/replies/{replyId}")
  .onCreate(async (snapshot, context) => {
    const replyData = snapshot.data();
    if (!replyData) {
      return null;
    }

    const storyDoc = await admin.firestore().collection("stories").doc(context.params.storyId).get();
    const ownerId = storyDoc.data()?.userId;
    if (!ownerId || ownerId === replyData.userId) {
      return null;
    }

    const ownerDoc = await admin.firestore().collection("users").doc(ownerId).get();
    const token = ownerDoc.data()?.fcmToken;
    if (!token) {
      return null;
    }

    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: "رد على قصتك 🗨️",
        body: `${replyData.userName} رد على الستوري الخاصة بك`,
      },
      android: androidConfig,
      data: {type: "story", storyId: context.params.storyId},
    };

    return admin.messaging().send(message);
  });

// 11. Family Notification
export const sendFamilyNotification = functions.firestore
  .document("families/{familyId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    const beforeMembers = before.members || [];
    const afterMembers = after.members || [];

    const newMemberId = afterMembers.find((id: string) => !beforeMembers.includes(id));
    if (!newMemberId) {
      return null;
    }

    const userDoc = await admin.firestore().collection("users").doc(newMemberId).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) {
      return null;
    }

    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: "مرحباً بك في العائلة! 🛡️",
        body: `تمت إضافتك بنجاح إلى عائلة ${after.name}`,
      },
      android: androidConfig,
      data: {type: "family", familyId: change.after.id},
    };

    return admin.messaging().send(message);
  });

// 12. Transfer Notification
export const sendTransferNotification = functions.firestore
  .document("transfers/{transferId}")
  .onCreate(async (snapshot) => {
    const data = snapshot.data();
    if (!data) {
      return null;
    }

    const receiverDoc = await admin.firestore().collection("users").doc(data.receiverId).get();
    const token = receiverDoc.data()?.fcmToken;
    if (!token) {
      return null;
    }

    const senderDoc = await admin.firestore().collection("users").doc(data.senderId).get();
    const senderName = senderDoc.data()?.name || "مستخدم";

    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: "استلام رصيد 💸",
        body: `لقد أرسل لك ${senderName} مبلِغ ${data.amount} ${data.type === "coins" ? "نجمة ⭐" : "جواهر"}`,
      },
      android: androidConfig,
      data: {type: "wallet"},
    };

    return admin.messaging().send(message);
  });

// 13. Game Invite Notification
export const sendGameInviteNotification = functions.firestore
  .document("game_invites/{inviteId}")
  .onCreate(async (snapshot) => {
    const data = snapshot.data();
    if (!data) {
      return null;
    }

    const receiverDoc = await admin.firestore().collection("users").doc(data.receiverId).get();
    const token = receiverDoc.data()?.fcmToken;
    if (!token) {
      return null;
    }

    const senderDoc = await admin.firestore().collection("users").doc(data.senderId).get();
    const senderName = senderDoc.data()?.name || "مستخدم";

    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: "تحدي جديد! 🎮",
        body: `يدعوك ${senderName} للعب ${data.gameName}`,
      },
      android: androidConfig,
      data: {type: "game", gameId: data.gameId},
    };

    return admin.messaging().send(message);
  });
