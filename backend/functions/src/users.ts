import * as functions from "firebase-functions";
import { db } from "./index";

/**
 * Get all users (admin only)
 */
export const getAllUsers = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    // Check if admin
    const userDoc = await db.collection("users").doc(context.auth.uid).get();
    if (userDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can view all users"
      );
    }

    try {
      const snapshot = await db.collection("users").get();
      const users = snapshot.docs.map((doc) => {
        const data = doc.data();
        // Remove sensitive data
        delete data.fcmTokens;
        return data;
      });

      return { success: true, users, count: users.length };
    } catch (error) {
      console.error(`Error fetching users: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch users"
      );
    }
  }
);

/**
 * Get users by role
 */
export const getUsersByRole = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { role } = data;
    const validRoles = ["donor", "ngo", "volunteer", "admin"];

    if (!validRoles.includes(role)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid role");
    }

    try {
      const snapshot = await db
        .collection("users")
        .where("role", "==", role)
        .where("isActive", "==", true)
        .get();

      const users = snapshot.docs.map((doc) => {
        const data = doc.data();
        delete data.fcmTokens;
        return data;
      });

      return { success: true, users, count: users.length };
    } catch (error) {
      console.error(`Error fetching users by role: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch users"
      );
    }
  }
);

/**
 * Deactivate user
 */
export const deactivateUser = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { userId } = data;

    if (!userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "User ID is required"
      );
    }

    try {
      // Only admin or self can deactivate
      const callerDoc = await db.collection("users").doc(context.auth.uid).get();
      if (callerDoc.data()?.role !== "admin" && userId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You cannot deactivate this user"
        );
      }

      await db.collection("users").doc(userId).update({
        isActive: false,
        updatedAt: new Date(),
      });

      return { success: true, message: "User deactivated successfully" };
    } catch (error) {
      console.error(`Error deactivating user: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to deactivate user"
      );
    }
  }
);

/**
 * Get user statistics
 */
export const getUserStatistics = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    // Check if admin
    const userDoc = await db.collection("users").doc(context.auth.uid).get();
    if (userDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can view statistics"
      );
    }

    try {
      const usersSnapshot = await db.collection("users").get();
      const donorsSnapshot = await db
        .collection("users")
        .where("role", "==", "donor")
        .get();
      const ngosSnapshot = await db
        .collection("users")
        .where("role", "==", "ngo")
        .get();
      const volunteersSnapshot = await db
        .collection("users")
        .where("role", "==", "volunteer")
        .get();

      const donationsSnapshot = await db.collection("donations").get();
      const pickupsSnapshot = await db.collection("pickups").get();

      return {
        success: true,
        statistics: {
          totalUsers: usersSnapshot.size,
          totalDonors: donorsSnapshot.size,
          totalNGOs: ngosSnapshot.size,
          totalVolunteers: volunteersSnapshot.size,
          totalDonations: donationsSnapshot.size,
          totalPickups: pickupsSnapshot.size,
          activeDonations: donationsSnapshot.docs.filter(
            (d) => d.data().status === "available"
          ).length,
          completedPickups: pickupsSnapshot.docs.filter(
            (p) => p.data().status === "completed"
          ).length,
        },
      };
    } catch (error) {
      console.error(`Error getting statistics: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to get statistics"
      );
    }
  }
);

/**
 * Get user donations count
 */
export const getUserDonationsCount = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    try {
      const snapshot = await db
        .collection("donations")
        .where("donorId", "==", context.auth.uid)
        .get();

      const completed = snapshot.docs.filter(
        (d) => d.data().status === "completed"
      ).length;
      const available = snapshot.docs.filter(
        (d) => d.data().status === "available"
      ).length;
      const expired = snapshot.docs.filter(
        (d) => d.data().status === "expired"
      ).length;

      return {
        success: true,
        total: snapshot.size,
        completed,
        available,
        expired,
      };
    } catch (error) {
      console.error(`Error getting donations count: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to get donations count"
      );
    }
  }
);

/**
 * Get volunteer rating and statistics
 */
export const getVolunteerStats = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { volunteerId } = data;
    const uid = volunteerId || context.auth.uid;

    try {
      const pickupsSnapshot = await db
        .collection("pickups")
        .where("volunteerId", "==", uid)
        .get();

      const pickups = pickupsSnapshot.docs.map((d) => d.data());
      const completedPickups = pickups.filter((p) => p.status === "completed");
      const averageRating =
        completedPickups.length > 0
          ? completedPickups.reduce((sum, p) => sum + (p.rating || 0), 0) /
            completedPickups.length
          : 0;

      return {
        success: true,
        stats: {
          totalPickups: pickups.length,
          completedPickups: completedPickups.length,
          averageRating: Math.round(averageRating * 10) / 10,
          successRate:
            pickups.length > 0
              ? Math.round((completedPickups.length / pickups.length) * 100)
              : 0,
        },
      };
    } catch (error) {
      console.error(`Error getting volunteer stats: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to get volunteer stats"
      );
    }
  }
);
