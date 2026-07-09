# Cloud Functions for RoyalDur

This folder contains Firebase Cloud Functions used by the RoyalDur app:

- `onStoryDelete`: runs when a story doc is deleted, deletes referenced Storage files and replies subcollection.
- `onNotificationCreate`: runs when a notification document is created; sends FCM push if the recipient has a `fcmToken`.

How to deploy:
1. Install dependencies:

```bash
cd functions
npm install
```

2. Deploy functions:

```bash
firebase deploy --only functions
```

Notes:
- Ensure the Firebase project is selected (use `firebase use <projectId>`).
- The functions assume `users` documents may contain `fcmToken` fields.
- Prefer setting IAM and Firestore security rules to restrict who can write to `notifications`.
