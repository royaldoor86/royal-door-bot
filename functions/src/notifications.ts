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
      
      // التحقق من إعدادات الإشعارات للمستخدم
      const chatNotificationsEnabled = userData?.chatNotificationsEnabled ?? true;
      const pushNotificationsEnabled = userData?.pushNotificationsEnabled ?? true;
      
      if (userData?.fcmToken && chatNotificationsEnabled && pushNotificationsEnabled && (!userData.isActive || userData.currentRoomId !== roomId)) {
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
    const receiverData = receiverDoc.data();
    if (!receiverData?.fcmToken) {
      return null;
    }

    // التحقق من إعدادات الإشعارات
    const friendRequestNotificationsEnabled = receiverData?.friendRequestNotificationsEnabled ?? true;
    const pushNotificationsEnabled = receiverData?.pushNotificationsEnabled ?? true;
    const allowFriendRequests = receiverData?.allowFriendRequests ?? true;

    if (!friendRequestNotificationsEnabled || !pushNotificationsEnabled || !allowFriendRequests) {
      return null;
    }

    const senderDoc = await admin.firestore().collection("users").doc(data.senderId).get();
    const senderName = senderDoc.data()?.name || "مستخدم";

    const message: admin.messaging.Message = {
      token: receiverData.fcmToken,
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
    const userData = userDoc.data();
    if (!userData?.fcmToken) {
      return null;
    }

    // التحقق من إعدادات الإشعارات
    const notificationsFromNonFriends = userData?.notificationsFromNonFriends ?? true;
    const pushNotificationsEnabled = userData?.pushNotificationsEnabled ?? true;

    if (!notificationsFromNonFriends || !pushNotificationsEnabled) {
      return null;
    }

    const visitorDoc = await admin.firestore().collection("users").doc(visitorId).get();
    const visitorName = visitorDoc.data()?.name || "شخص ما";

    const message: admin.messaging.Message = {
      token: userData.fcmToken,
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

    // التحقق من إعدادات الإشعارات
    const followNotificationsEnabled = after.followNotificationsEnabled ?? true;
    const pushNotificationsEnabled = after.pushNotificationsEnabled ?? true;

    if (!followNotificationsEnabled || !pushNotificationsEnabled) {
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
    const userData = userDoc.data();
    if (!userData?.fcmToken) {
      return null;
    }

    // التحقق من إعدادات الإشعارات
    const giftNotificationsEnabled = userData?.giftNotificationsEnabled ?? true;
    const pushNotificationsEnabled = userData?.pushNotificationsEnabled ?? true;

    if (!giftNotificationsEnabled || !pushNotificationsEnabled) {
      return null;
    }

    const senderDoc = await admin.firestore().collection("users").doc(messageData.senderId).get();
    const senderName = senderDoc.data()?.name || "مستخدم";

    const message: admin.messaging.Message = {
      token: userData.fcmToken,
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
    const userData = userDoc.data();
    if (!userData?.fcmToken) {
      return null;
    }

    // التحقق من إعدادات الإشعارات
    const systemNotificationsEnabled = userData?.systemNotificationsEnabled ?? true;
    const pushNotificationsEnabled = userData?.pushNotificationsEnabled ?? true;

    if (!systemNotificationsEnabled || !pushNotificationsEnabled) {
      return null;
    }

    const senderDoc = await admin.firestore().collection("users").doc(inviteData.fromUserId).get();
    const senderName = senderDoc.data()?.name || "مستخدم";

    const roomDoc = await admin.firestore().collection("rooms").doc(context.params.roomId).get();
    const roomName = roomDoc.data()?.name || "غرفة صوتية";

    const message: admin.messaging.Message = {
      token: userData.fcmToken,
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

    const followers = Array.isArray(authorDoc.data()?.followers) ? authorDoc.data()?.followers : [];
    const friends = Array.isArray(authorDoc.data()?.friends) ? authorDoc.data()?.friends : [];

    // اتحاد المتلقين: متابعين + أصدقاء، مع إزالة الكاتب نفسه
    const recipients = Array.from(new Set([...(followers || []), ...(friends || [])])).filter((uid) => uid !== postData.authorId);
    if (recipients.length === 0) return null;

    const notifTitle = 'منشور جديد 📝';
    const notifBody = `${authorName} نشر منشوراً جديداً، اطلِع عليه.`;

    // احفظ إشعار داخلي لكل متلقي
    const writePromises: Array<Promise<any>> = [];
    recipients.forEach((uid: string) => {
      const ref = admin.firestore().collection('notifications').doc(uid).collection('items').doc();
      writePromises.push(ref.set({
        title: notifTitle,
        body: notifBody,
        type: 'post',
        postId: snapshot.id,
        senderId: postData.authorId,
        isRead: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      }));
    });

    // اجمع كل رموز الأجهزة (FCM tokens) في دفعات لاستهلاك where-in من Firestore
    const allTokens: string[] = [];
    for (let i = 0; i < recipients.length; i += 10) {
      const batch = recipients.slice(i, i + 10);
      const usersSnap = await admin.firestore().collection('users').where(admin.firestore.FieldPath.documentId(), 'in', batch).get();
      usersSnap.forEach((u) => {
        const t = u.data()?.fcmToken;
        if (t) allTokens.push(t);
      });
    }

    // إرسال Push في دفعات (حد FCM = 500 لكل إرسال متعدد)
    const sendPromises: Array<Promise<any>> = [];
    for (let i = 0; i < allTokens.length; i += 500) {
      const tokensBatch = allTokens.slice(i, i + 500);
      if (tokensBatch.length === 0) continue;
      const message: admin.messaging.MulticastMessage = {
        tokens: tokensBatch,
        notification: {
          title: notifTitle,
          body: notifBody,
        },
        android: androidConfig,
        data: { type: 'post', postId: snapshot.id, actionUrl: `app://post/${snapshot.id}` },
      };
      sendPromises.push(admin.messaging().sendMulticast(message));
    }

    await Promise.all(writePromises);
    if (sendPromises.length === 0) return null;
    return Promise.all(sendPromises);
  });

// 8. Story Published Notification
export const sendNewStoryNotification = functions.firestore
  .document("stories/{storyId}")
  .onCreate(async (snapshot) => {
    const storyData = snapshot.data();
    if (!storyData) {
      return null;
    }

    const authorId = storyData.userId;
    const authorDoc = await admin.firestore().collection("users").doc(authorId).get();
    const authorName = authorDoc.data()?.name || "صديقك";

    const followers = Array.isArray(authorDoc.data()?.followers)
      ? authorDoc.data()?.followers
      : [];
    const friends = Array.isArray(authorDoc.data()?.friends)
      ? authorDoc.data()?.friends
      : [];

    const recipients = Array.from(
      new Set([...(followers || []), ...(friends || [])])
    ).filter((uid) => uid !== authorId);
    if (recipients.length === 0) return null;

    const notifTitle = 'قصة جديدة 🌟';
    const notifBody = `${authorName} نشر قصة جديدة، اطلع عليها الآن.`;

    const writePromises: Array<Promise<any>> = [];
    recipients.forEach((uid: string) => {
      const ref = admin.firestore()
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc();
      writePromises.push(ref.set({
        title: notifTitle,
        body: notifBody,
        type: 'story',
        storyId: snapshot.id,
        senderId: authorId,
        isRead: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      }));
    });

    const allTokens: string[] = [];
    for (let i = 0; i < recipients.length; i += 10) {
      const batch = recipients.slice(i, i + 10);
      const usersSnap = await admin.firestore()
        .collection('users')
        .where(admin.firestore.FieldPath.documentId(), 'in', batch)
        .get();
      usersSnap.forEach((u) => {
        const t = u.data()?.fcmToken;
        if (t) allTokens.push(t);
      });
    }

    const sendPromises: Array<Promise<any>> = [];
    for (let i = 0; i < allTokens.length; i += 500) {
      const tokensBatch = allTokens.slice(i, i + 500);
      if (tokensBatch.length === 0) continue;
      const message: admin.messaging.MulticastMessage = {
        tokens: tokensBatch,
        notification: {
          title: notifTitle,
          body: notifBody,
        },
        android: androidConfig,
        data: {
          type: 'story',
          storyId: snapshot.id,
          actionUrl: `app://story/${snapshot.id}`,
        },
      };
      sendPromises.push(admin.messaging().sendMulticast(message));
    }

    await Promise.all(writePromises);
    if (sendPromises.length === 0) return null;
    return Promise.all(sendPromises);
  });

// 9. Room Battle Notification
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

// 14. Family War Started Notification
export const sendFamilyWarNotification = functions.firestore
  .document("family_wars/{warId}")
  .onCreate(async (snapshot, context) => {
    const warData = snapshot.data();
    if (!warData || warData.status !== "active") {
      return null;
    }

    const warId = context.params.warId;
    const createdBy = warData.createdBy;
    const challengerId = warData.challengerId;
    const targetId = warData.targetId;
    const challengerName = warData.challengerName || "عائلة";
    const targetName = warData.targetName || "عائلة";
    const warType = warData.warType || "normal";

    // Get friends of the creator
    const creatorDoc = await admin.firestore().collection("users").doc(createdBy).get();
    const creatorData = creatorDoc.data();
    const friends: string[] = creatorData?.friends || [];

    // Get family organizers (leader and co-leaders) for both families
    const organizerIds: string[] = [];
    
    for (const familyId of [challengerId, targetId]) {
      const membersSnap = await admin.firestore()
        .collection("families")
        .doc(familyId)
        .collection("members")
        .where("role", "in", ["leader", "co-leader"])
        .get();
      
      membersSnap.forEach((doc) => {
        if (!organizerIds.includes(doc.id)) {
          organizerIds.push(doc.id);
        }
      });
    }

    // Combine friends and organizers, remove duplicates
    const recipientIds = [...new Set([...friends, ...organizerIds])];

    if (recipientIds.length === 0) {
      return null;
    }

    // Get FCM tokens for all recipients
    const tokens: string[] = [];
    const users = await admin.firestore()
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", recipientIds.slice(0, 500))
      .get();
    
    users.forEach((u) => {
      if (u.data().fcmToken) {
        tokens.push(u.data().fcmToken);
      }
    });

    if (tokens.length === 0) {
      return null;
    }

    // Determine war type text
    const warTypeText = warType === "championship" ? "حرب بطولة 🏆" : 
      warType === "alliance" ? "حرب تحالف 🤝" : "حرب عادية ⚔️";

    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: `${warTypeText} بدأت!`,
        body: `بدأت حرب بين ${challengerName} و ${targetName}. انضم لدعم عائلتك!`,
      },
      android: androidConfig,
      data: {
        type: "family_war",
        warId: warId,
        challengerId: challengerId,
        targetId: targetId,
      },
    };

    return admin.messaging().sendEachForMulticast(message);
  });

// 15. Family Vote Created Notification
export const sendFamilyVoteNotification = functions.firestore
  .document("family_votes/{voteId}")
  .onCreate(async (snapshot, context) => {
    const voteData = snapshot.data();
    if (!voteData) return null;

    const voteId = context.params.voteId;
    const familyId = voteData.familyId;
    const title = voteData.title || "تصويت جديد";
    const type = voteData.type || "custom";

    // Get all family members
    const membersSnap = await admin.firestore()
      .collection("families")
      .doc(familyId)
      .collection("members")
      .get();

    const memberIds: string[] = [];
    membersSnap.forEach((doc) => memberIds.push(doc.id));

    if (memberIds.length === 0) return null;

    // Get FCM tokens for all members
    const tokens: string[] = [];
    const users = await admin.firestore()
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", memberIds.slice(0, 500))
      .get();

    users.forEach((u) => {
      if (u.data().fcmToken) {
        tokens.push(u.data().fcmToken);
      }
    });

    if (tokens.length === 0) return null;

    // Get vote type text
    const typeText = type === "name_change" ? "تغيير اسم" :
      type === "member_remove" ? "طرد عضو" :
        type === "leader_election" ? "انتخابات" : "تصويت";

    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: `${typeText} جديد 🗳️`,
        body: `${title}. صوِ الآن!`,
      },
      android: androidConfig,
      data: {
        type: "family_vote",
        voteId: voteId,
        familyId: familyId,
      },
    };

    return admin.messaging().sendEachForMulticast(message);
  });

// 16. Family Mini Game Created Notification
export const sendFamilyMiniGameNotification = functions.firestore
  .document("family_mini_games/{gameId}")
  .onCreate(async (snapshot, context) => {
    const gameData = snapshot.data();
    if (!gameData) return null;

    const gameId = context.params.gameId;
    const familyId = gameData.familyId;
    const gameName = gameData.nameAr || "لعبة جديدة";
    const gameType = gameData.type || "quiz";

    // Get all family members
    const membersSnap = await admin.firestore()
      .collection("families")
      .doc(familyId)
      .collection("members")
      .get();

    const memberIds: string[] = [];
    membersSnap.forEach((doc) => memberIds.push(doc.id));

    if (memberIds.length === 0) return null;

    // Get FCM tokens for all members
    const tokens: string[] = [];
    const users = await admin.firestore()
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", memberIds.slice(0, 500))
      .get();

    users.forEach((u) => {
      if (u.data().fcmToken) {
        tokens.push(u.data().fcmToken);
      }
    });

    if (tokens.length === 0) return null;

    // Get game type text
    const typeText = gameType === "quiz" ? "اختبار" :
      gameType === "trivia" ? "معلومات عامة" :
        gameType === "reaction" ? "رد فعل" :
          gameType === "memory" ? "ذاكرة" : "لعبة";

    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: `${typeText} جديد 🎮`,
        body: `${gameName}. انضم للعب الآن!`,
      },
      android: androidConfig,
      data: {
        type: "family_game",
        gameId: gameId,
        familyId: familyId,
      },
    };

    return admin.messaging().sendEachForMulticast(message);
  });

// 17. Family Challenge Created Notification
export const sendFamilyChallengeNotification = functions.firestore
  .document("family_challenges/{challengeId}")
  .onCreate(async (snapshot, context) => {
    const challengeData = snapshot.data();
    if (!challengeData) return null;

    const challengeId = context.params.challengeId;
    const familyId = challengeData.familyId;
    const title = challengeData.title || "تحدي جديد";
    const type = challengeData.type || "contribution";

    // Get all family members
    const membersSnap = await admin.firestore()
      .collection("families")
      .doc(familyId)
      .collection("members")
      .get();

    const memberIds: string[] = [];
    membersSnap.forEach((doc) => memberIds.push(doc.id));

    if (memberIds.length === 0) return null;

    // Get FCM tokens for all members
    const tokens: string[] = [];
    const users = await admin.firestore()
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", memberIds.slice(0, 500))
      .get();

    users.forEach((u) => {
      if (u.data().fcmToken) {
        tokens.push(u.data().fcmToken);
      }
    });

    if (tokens.length === 0) return null;

    // Get challenge type text
    const typeText = type === "contribution" ? "مساهمة" :
      type === "activity" ? "نشاط" : "تحدي";

    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: `${typeText} جديد 🏆`,
        body: `${title}. شارك وتحدى نفسك!`,
      },
      android: androidConfig,
      data: {
        type: "family_challenge",
        challengeId: challengeId,
        familyId: familyId,
      },
    };

    return admin.messaging().sendEachForMulticast(message);
  });

// 18. Family Alliance Created Notification
export const sendFamilyAllianceNotification = functions.firestore
  .document("family_alliances/{allianceId}")
  .onCreate(async (snapshot, context) => {
    const allianceData = snapshot.data();
    if (!allianceData) return null;

    const allianceId = context.params.allianceId;
    const familyId1 = allianceData.familyId1;
    const familyId2 = allianceData.familyId2;
    const allianceName = allianceData.name || "تحالف جديد";
    const status = allianceData.status || "pending";

    if (status !== "pending") return null;

    // Notify familyId2 (target family) about the alliance request
    const membersSnap = await admin.firestore()
      .collection("families")
      .doc(familyId2)
      .collection("members")
      .get();

    const memberIds: string[] = [];
    membersSnap.forEach((doc) => memberIds.push(doc.id));

    if (memberIds.length === 0) return null;

    // Get FCM tokens for all members
    const tokens: string[] = [];
    const users = await admin.firestore()
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", memberIds.slice(0, 500))
      .get();

    users.forEach((u) => {
      if (u.data().fcmToken) {
        tokens.push(u.data().fcmToken);
      }
    });

    if (tokens.length === 0) return null;

    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: "طلب تحالف جديد 🤝",
        body: `${allianceName}. قبل أو ارفض الطلب.`,
      },
      android: androidConfig,
      data: {
        type: "family_alliance",
        allianceId: allianceId,
        familyId1: familyId1,
        familyId2: familyId2,
      },
    };

    return admin.messaging().sendEachForMulticast(message);
  });

// 19. Family Member Joined Notification
export const sendFamilyMemberJoinedNotification = functions.firestore
  .document("families/{familyId}/members/{memberId}")
  .onCreate(async (snapshot, context) => {
    const memberData = snapshot.data();
    if (!memberData) return null;

    const familyId = context.params.familyId;
    const memberId = context.params.memberId;
    const role = memberData.role || "member";

    // Get family name
    const familySnap = await admin.firestore()
      .collection("families")
      .doc(familyId)
      .get();

    const familyName = familySnap.data()?.name || "العائلة";

    // Get all family members except the new member
    const membersSnap = await admin.firestore()
      .collection("families")
      .doc(familyId)
      .collection("members")
      .get();

    const memberIds: string[] = [];
    membersSnap.forEach((doc) => {
      if (doc.id !== memberId) memberIds.push(doc.id);
    });

    if (memberIds.length === 0) return null;

    // Get new member name
    const userSnap = await admin.firestore()
      .collection("users")
      .doc(memberId)
      .get();

    const userName = userSnap.data()?.name || "عضو جديد";

    // Get FCM tokens for all members
    const tokens: string[] = [];
    const users = await admin.firestore()
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", memberIds.slice(0, 500))
      .get();

    users.forEach((u) => {
      if (u.data().fcmToken) {
        tokens.push(u.data().fcmToken);
      }
    });

    if (tokens.length === 0) return null;

    // Get role text
    const roleText = role === "leader" ? "قائد" :
      role === "co-leader" ? "قائد مساعد" : "عضو";

    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: "عضو جديد انضم! 👋",
        body: `${userName} انضم ل${familyName} ك${roleText}.`,
      },
      android: androidConfig,
      data: {
        type: "family_member_joined",
        familyId: familyId,
        memberId: memberId,
      },
    };

    return admin.messaging().sendEachForMulticast(message);
  });
