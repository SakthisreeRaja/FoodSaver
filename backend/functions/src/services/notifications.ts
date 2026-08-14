import { db } from "../index";
import * as admin from "firebase-admin";

export interface Notification {
  id?: string;
  userId: string;
  title: string;
  body: string;
  type: "donation" | "pickup" | "system" | "rating";
  data?: Record<string, any>;
  read: boolean;
  createdAt: Date;
}

/**
 * Send notification to user via FCM
 */
export const sendNotification = async (
  userId: string,
  title: string,
  body: string,
  type: string,
  data?: Record<string, any>
): Promise<void> => {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      console.warn(`User ${userId} not found`);
      return;
    }

    const fcmTokens = userDoc.data()?.fcmTokens || [];
    if (fcmTokens.length === 0) {
      console.warn(`No FCM tokens for user ${userId}`);
      return;
    }

    const message = {
      notification: {
        title,
        body,
      },
      data: {
        type,
        ...data,
      },
      tokens: fcmTokens,
    };

    const response = await admin.messaging().sendMulticast(message as any);

    // Save notification to Firestore
    await saveNotificationToDatabase(userId, title, body, type, data);

    console.log(`Notifications sent successfully:`, response);
  } catch (error) {
    console.error("Error sending notification:", error);
  }
};

/**
 * Save notification to database for in-app display
 */
export const saveNotificationToDatabase = async (
  userId: string,
  title: string,
  body: string,
  type: string,
  data?: Record<string, any>
): Promise<string> => {
  try {
    const notificationRef = db.collection("notifications").doc();
    const notification: Notification = {
      id: notificationRef.id,
      userId,
      title,
      body,
      type: type as any,
      data: data || {},
      read: false,
      createdAt: new Date(),
    };

    await notificationRef.set(notification);
    return notificationRef.id;
  } catch (error) {
    console.error("Error saving notification:", error);
    throw error;
  }
};

/**
 * Get user notifications
 */
export const getUserNotifications = async (
  userId: string,
  limit: number = 20
): Promise<Notification[]> => {
  try {
    const snapshot = await db
      .collection("notifications")
      .where("userId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();

    return snapshot.docs.map((doc) => doc.data() as Notification);
  } catch (error) {
    console.error("Error fetching notifications:", error);
    throw error;
  }
};

/**
 * Mark notification as read
 */
export const markNotificationAsRead = async (
  notificationId: string
): Promise<void> => {
  try {
    await db
      .collection("notifications")
      .doc(notificationId)
      .update({ read: true });
  } catch (error) {
    console.error("Error marking notification as read:", error);
    throw error;
  }
};

/**
 * Delete notification
 */
export const deleteNotification = async (
  notificationId: string
): Promise<void> => {
  try {
    await db.collection("notifications").doc(notificationId).delete();
  } catch (error) {
    console.error("Error deleting notification:", error);
    throw error;
  }
};

/**
 * Notify nearby NGOs about new donation
 */
export const notifyNearbyNGOs = async (
  donationId: string,
  latitude: number,
  longitude: number,
  radiusKm: number = 5
): Promise<void> => {
  try {
    // Get all NGO users
    const ngoSnapshot = await db
      .collection("users")
      .where("role", "==", "ngo")
      .get();

    const nearbyNGOs: string[] = [];

    for (const doc of ngoSnapshot.docs) {
      const ngoData = doc.data();
      if (ngoData.latitude && ngoData.longitude) {
        const distance = calculateDistance(
          latitude,
          longitude,
          ngoData.latitude,
          ngoData.longitude
        );

        if (distance <= radiusKm) {
          nearbyNGOs.push(doc.id);
        }
      }
    }

    // Send notifications to nearby NGOs
    for (const ngoId of nearbyNGOs) {
      await sendNotification(
        ngoId,
        "New Donation Available",
        "A new food donation is available near you!",
        "donation",
        { donationId }
      );
    }
  } catch (error) {
    console.error("Error notifying nearby NGOs:", error);
  }
};

/**
 * Calculate distance between coordinates (in km)
 */
const calculateDistance = (
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number => {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};
