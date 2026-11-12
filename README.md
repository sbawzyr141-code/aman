# Aman Security App

## Admin control panel

The app grants admin access when the signed-in user's `users/{uid}` Firestore
document has `isAdmin` set to the Boolean `true`. Neither a particular email
address, email-verification state, nor the user's `role` grants admin access.
The control panel is available on web, Android, and iOS, and opens when an
admin signs in. It supports store and user management, permission changes,
report review, sales and ownership-transfer oversight, PDF summary reports,
and an administrator audit log.

### Grant the first admin

1. Create the intended account through the app.
2. In Firebase Console, open Authentication and copy that account's UID.
3. In Firestore, open `users/{uid}` for that same UID and set `isAdmin` to the
   Boolean `true` (not the string `"true"`).
4. Deploy the rules below, then sign out and sign back in.

Clients cannot add or change `isAdmin`; only an existing admin or a trusted
Firebase Console/Admin SDK operation can grant the first admin.

### Deploy Firestore security rules

The control panel's privileged reads and writes are enforced by
`firestore.rules`, not only by hiding the panel in the app. The app uses the
`aman-protection-2026` Firebase project on web and Android. Deploy the rules to
that project:

```shell
firebase deploy --only firestore:rules --project aman-protection-2026
```

The web app is registered in Firebase as `aman_app_web`.
