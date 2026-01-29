import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

// App is free; no prices or purchases. Access is granted by admin only.