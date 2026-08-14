import * as functions from "firebase-functions";
import { db, auth } from "./index";

const admin = require("firebase-admin");

/**
 * Send notification to user
 */
export const sendNotification = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { userId, title, body, data: notificationData } = data;

    if (!userId || !title || !body) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields"
      );
    }

    try {
      // Get user's FCM tokens
      const userDoc = await db.collection("users").doc(userId).get();
      const tokens = userDoc.data()?.fcmTokens || [];

      if (tokens.length === 0) {
        return { success: false, message: "User has no FCM tokens" };
      }

      // Send multicast message
      const message = {
        notification: {
          title,
          body,
        },
        data: notificationData || {},
      };

      const response = await admin.messaging().sendMulticast({
        ...message,
        tokens,
      });

      // Save notification to database
      await db.collection("notifications").add({
        userId,
        title,
        body,
        data: notificationData,
        sentAt: new Date(),
        read: false,
      });

      return {
        success: true,
        message: `Notification sent to ${response.successCount} device(s)`,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      console.error(`Error sending notification: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send notification"
      );
    }
  }
);

/**
 * Notify volunteers about new donation
 */
export const notifyVolunteersAboutDonation = functions.firestore
  .document("donations/{donationId}")
  .onCreate(async (snap) => {
    const donation = snap.data();

    if (!donation) return;

    try {
      // Get all volunteers in the area (for now, get all volunteers)
      const volunteersSnapshot = await db
        .collection("users")
        .where("role", "==", "volunteer")
        .where("isActive", "==", true)
        .get();

      const message = {
        notification: {
          title: "New Food Donation Available!",
          body: `${donation.foodName} available at ${donation.location}`,
        },
        data: {
          donationId: donation.id,
          type: "new_donation",
          location: donation.location,
        },
      };

      volunteersSnapshot.docs.forEach(async (doc) => {
        const tokens = doc.data().fcmTokens || [];
        if (tokens.length > 0) {
          try {
            await admin.messaging().sendMulticast({
              ...message,
              tokens,
            });
          } catch (error) {
            console.error(`Error sending to volunteer ${doc.id}: ${error}`);
          }
        }
      });
    } catch (error) {
      console.error(`Error notifying volunteers: ${error}`);
    }
  });

/**
 * Notify donor when donation is claimed
 */
export const notifyDonorOnClaim = functions.firestore
  .document("donations/{donationId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before?.status !== "available" && after?.status === "claimed") {
      try {
        const userDoc = await db.collection("users").doc(after.donorId).get();
        const tokens = userDoc.data()?.fcmTokens || [];

        if (tokens.length > 0) {
          const message = {
            notification: {
              title: "Your donation has been claimed!",
              body: `${after.foodName} has been claimed for pickup`,
            },
            data: {
              donationId: after.id,
              type: "donation_claimed",
            },
          };

          await admin.messaging().sendMulticast({
            ...message,
            tokens,
          });
        }
      } catch (error) {
        console.error(`Error notifying donor: ${error}`);
      }
    }
  });

/**
 * Notify NGO about new pickup request
 */
export const notifyNGOAboutPickup = functions.firestore
  .document("pickups/{pickupId}")
  .onCreate(async (snap) => {
    const pickup = snap.data();

    if (!pickup || !pickup.ngoId) return;

    try {
      const ngoDoc = await db.collection("users").doc(pickup.ngoId).get();
      const tokens = ngoDoc.data()?.fcmTokens || [];

      if (tokens.length > 0) {
        const donationDoc = await db
          .collection("donations")
          .doc(pickup.donationId)
          .get();
        const donation = donationDoc.data();

        const message = {
          notification: {
            title: "New Pickup Request",
            body: `Pickup scheduled for ${donation?.foodName}`,
          },
          data: {
            pickupId: pickup.id,
            donationId: pickup.donationId,
            type: "new_pickup",
          },
        };

        await admin.messaging().sendMulticast({
          ...message,
          tokens,
        });
      }
    } catch (error) {
      console.error(`Error notifying NGO: ${error}`);
    }
  });

/**
 * Get user notifications
 */
export const getUserNotifications = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    try {
      const snapshot = await db
        .collection("notifications")
        .where("userId", "==", context.auth.uid)
        .orderBy("sentAt", "desc")
        .limit(50)
        .get();

      const notifications = snapshot.docs.map((doc) => doc.data());
      return { success: true, notifications };
    } catch (error) {
      console.error(`Error fetching notifications: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch notifications"
      );
    }
  }
);

/**
 * Mark notification as read
 */
export const markNotificationAsRead = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { notificationId } = data;

    if (!notificationId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Notification ID is required"
      );
    }

    try {
      await db.collection("notifications").doc(notificationId).update({
        read: true,
        readAt: new Date(),
      });

      return { success: true, message: "Notification marked as read" };
    } catch (error) {
      console.error(`Error marking notification: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to mark notification"
      );
    }
  }
);
