import * as functions from "firebase-functions";
import { Request, Response } from "express";
import { db, auth } from "./index";

/**
 * Create a new user profile after Firebase Auth signup
 */
export const createUserProfile = functions.auth.user().onCreate(async (user) => {
  try {
    await db.collection("users").doc(user.uid).set({
      uid: user.uid,
      email: user.email || "",
      displayName: user.displayName || "",
      photoURL: user.photoURL || "",
      role: "donor", // Default role
      createdAt: new Date(),
      updatedAt: new Date(),
      phone: "",
      address: "",
      isActive: true,
      fcmTokens: [],
    });
    console.log(`User profile created for ${user.uid}`);
  } catch (error) {
    console.error(`Error creating user profile: ${error}`);
    throw error;
  }
});

/**
 * Delete user data when Firebase Auth user is deleted
 */
export const deleteUserProfile = functions.auth.user().onDelete(async (user) => {
  try {
    await db.collection("users").doc(user.uid).delete();
    console.log(`User profile deleted for ${user.uid}`);
  } catch (error) {
    console.error(`Error deleting user profile: ${error}`);
    throw error;
  }
});

/**
 * Update user profile
 */
export const updateUserProfile = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = context.auth.uid;
    const { displayName, phone, address, photoURL } = data;

    try {
      await db.collection("users").doc(uid).update({
        ...(displayName && { displayName }),
        ...(phone && { phone }),
        ...(address && { address }),
        ...(photoURL && { photoURL }),
        updatedAt: new Date(),
      });

      return { success: true, message: "Profile updated successfully" };
    } catch (error) {
      console.error(`Error updating profile: ${error}`);
      throw new functions.https.HttpsError("internal", "Failed to update profile");
    }
  }
);

/**
 * Get user profile
 */
export const getUserProfile = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = context.auth.uid;

    try {
      const userDoc = await db.collection("users").doc(uid).get();
      if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User profile not found");
      }

      return userDoc.data();
    } catch (error) {
      console.error(`Error getting profile: ${error}`);
      throw new functions.https.HttpsError("internal", "Failed to get profile");
    }
  }
);

/**
 * Change user role (admin only)
 */
export const changeUserRole = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const adminDoc = await db.collection("users").doc(context.auth.uid).get();
    if (adminDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can change roles"
      );
    }

    const { userId, newRole } = data;

    if (!userId || !newRole) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userId and newRole are required"
      );
    }

    try {
      await db.collection("users").doc(userId).update({
        role: newRole,
        updatedAt: new Date(),
      });

      return { success: true, message: "User role updated successfully" };
    } catch (error) {
      console.error(`Error changing role: ${error}`);
      throw new functions.https.HttpsError("internal", "Failed to change role");
    }
  }
);

/**
 * Deactivate account
 */
export const deactivateAccount = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = context.auth.uid;

    try {
      await db.collection("users").doc(uid).update({
        isActive: false,
        updatedAt: new Date(),
      });

      return { success: true, message: "Account deactivated" };
    } catch (error) {
      console.error(`Error deactivating account: ${error}`);
      throw new functions.https.HttpsError("internal", "Failed to deactivate account");
    }
  }
);
);

/**
 * Upgrade user role (admin only)
 */
export const upgradeUserRole = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    // Check if caller is admin
    const callerDoc = await db.collection("users").doc(context.auth.uid).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can upgrade user roles"
      );
    }

    const { userId, role } = data;
    const validRoles = ["donor", "ngo", "volunteer", "admin"];

    if (!validRoles.includes(role)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid role");
    }

    try {
      await db.collection("users").doc(userId).update({
        role,
        updatedAt: new Date(),
      });

      return { success: true, message: `User role updated to ${role}` };
    } catch (error) {
      console.error(`Error upgrading role: ${error}`);
      throw new functions.https.HttpsError("internal", "Failed to upgrade role");
    }
  }
);

/**
 * Register FCM token for push notifications
 */
export const registerFcmToken = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = context.auth.uid;
    const { token } = data;

    if (!token) {
      throw new functions.https.HttpsError("invalid-argument", "Token is required");
    }

    try {
      const userRef = db.collection("users").doc(uid);
      const userDoc = await userRef.get();
      const fcmTokens = userDoc.data()?.fcmTokens || [];

      if (!fcmTokens.includes(token)) {
        await userRef.update({
          fcmTokens: [...fcmTokens, token],
          updatedAt: new Date(),
        });
      }

      return { success: true, message: "FCM token registered" };
    } catch (error) {
      console.error(`Error registering FCM token: ${error}`);
      throw new functions.https.HttpsError("internal", "Failed to register token");
    }
  }
);
