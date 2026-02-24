import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

// App is free; no prices or purchases. All authenticated users can access the app; admins only help with technical support and account management.