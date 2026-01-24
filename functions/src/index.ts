import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/** Callable: update subscription pricing (admin only). Uses Admin SDK to bypass Firestore rules. */
export const updateSubscriptionPricing = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to update pricing.");
    }
    const uid = request.auth.uid;

    const userDoc = await db.collection("users").doc(uid).get();
    const isAdmin = userDoc.exists && userDoc.data()?.isAdmin === true;
    if (!isAdmin) {
      throw new HttpsError(
        "permission-denied",
        "Only admins can update subscription pricing."
      );
    }

    const data = request.data as Record<string, unknown> | null;
    if (!data || typeof data !== "object") {
      throw new HttpsError("invalid-argument", "Missing request data.");
    }
    const monthlyPrice = Number(data.monthlyPrice);
    const yearlyPrice = Number(data.yearlyPrice);
    const currency =
      typeof data.currency === "string" && data.currency.trim()
        ? String(data.currency).trim()
        : "USD";

    if (!Number.isFinite(monthlyPrice) || monthlyPrice < 0) {
      throw new HttpsError(
        "invalid-argument",
        "Monthly price must be a non‑negative number."
      );
    }
    if (!Number.isFinite(yearlyPrice) || yearlyPrice < 0) {
      throw new HttpsError(
        "invalid-argument",
        "Yearly price must be a non‑negative number."
      );
    }

    await db
      .collection("subscription_pricing")
      .doc("config")
      .set(
        {
          monthlyPrice,
          yearlyPrice,
          currency,
          lastUpdated: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

    return { success: true };
  }
);