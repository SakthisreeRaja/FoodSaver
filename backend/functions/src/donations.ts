import * as functions from "firebase-functions";
import { db } from "./index";
import {
  createDonationService,
  claimDonation as claimDonationService,
  getNearbyDonations,
  getDonorDonations,
  updateDonationStatus,
  deleteDonation as deleteDonationService,
} from "./services/donations";
import { analyzeFoodImage } from "./services/geminiAI";

/**
 * Create a new donation listing
 */
export const createDonation = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const {
      foodName,
      description,
      quantity,
      category,
      expiryDate,
      location,
      latitude,
      longitude,
      imageUrl,
    } = data;

    if (!foodName || !description || !location || !latitude || !longitude) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields"
      );
    }

    try {
      const donationId = await createDonationService(context.auth.uid, {
        foodName,
        description,
        quantity: quantity || 1,
        category: category || "other",
        expiryDate,
        location,
        latitude,
        longitude,
        imageUrl,
      });

      return {
        success: true,
        message: "Donation created successfully",
        donationId,
      };
    } catch (error) {
      console.error(`Error creating donation: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to create donation"
      );
    }
  }
);

/**
 * Get all available donations
 */
export const getAvailableDonations = functions.https.onCall(
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
        .where("status", "==", "available")
        .orderBy("createdAt", "desc")
        .limit(100)
        .get();

      const donations = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate(),
        updatedAt: doc.data().updatedAt?.toDate(),
        expiryDate: doc.data().expiryDate?.toDate(),
      }));
      return { success: true, donations };
    } catch (error) {
      console.error(`Error fetching donations: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch donations"
      );
    }
  }
);

/**
 * Get nearby donations
 */
export const getNearby = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { latitude, longitude, radius = 5 } = data;

    if (latitude === undefined || longitude === undefined) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "latitude and longitude are required"
      );
    }

    try {
      const donations = await getNearbyDonations(latitude, longitude, radius);
      return { success: true, donations };
    } catch (error) {
      console.error(`Error fetching nearby donations: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch nearby donations"
      );
    }
  }
);

/**
 * Get donations by donor
 */
export const getDonationsByDonor = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { status } = data;

    try {
      const donations = await getDonorDonations(context.auth.uid, status);
      return { success: true, donations };
    } catch (error) {
      console.error(`Error fetching donor donations: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch donations"
      );
    }
  }
);

/**
 * Claim a donation
 */
export const claimDonation = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { donationId } = data;

    if (!donationId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Donation ID is required"
      );
    }

    try {
      const donationRef = db.collection("donations").doc(donationId);
      const donationDoc = await donationRef.get();

      if (!donationDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Donation not found");
      }

      const donation = donationDoc.data();

      if (donation?.status !== "available") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Donation is no longer available"
        );
      }

      await donationRef.update({
        status: "claimed",
        claimedBy: context.auth.uid,
        claimedAt: new Date(),
        updatedAt: new Date(),
      });

      return { success: true, message: "Donation claimed successfully" };
    } catch (error) {
      console.error(`Error claiming donation: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to claim donation"
      );
    }
  }
);

/**
 * Update donation status
 */
export const updateDonationStatus = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { donationId, status } = data;
    const validStatuses = ["available", "claimed", "completed", "expired"];

    if (!validStatuses.includes(status)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid status");
    }

    try {
      const donationRef = db.collection("donations").doc(donationId);
      const donationDoc = await donationRef.get();

      if (!donationDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Donation not found");
      }

      const donation = donationDoc.data();

      // Only donor or admin can update
      if (
        donation?.donorId !== context.auth.uid &&
        !(await isAdmin(context.auth.uid))
      ) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You cannot update this donation"
        );
      }

      await donationRef.update({
        status,
        updatedAt: new Date(),
      });

      return { success: true, message: "Donation status updated" };
    } catch (error) {
      console.error(`Error updating donation: ${error}`);
      throw new functions.https.HttpsError("internal", "Failed to update donation");
    }
  }
);

/**
 * Delete a donation
 */
export const deleteDonation = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { donationId } = data;

    try {
      const donationRef = db.collection("donations").doc(donationId);
      const donationDoc = await donationRef.get();

      if (!donationDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Donation not found");
      }

      const donation = donationDoc.data();

      // Only donor can delete
      if (donation?.donorId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You cannot delete this donation"
        );
      }

      await donationRef.delete();

      return { success: true, message: "Donation deleted successfully" };
    } catch (error) {
      console.error(`Error deleting donation: ${error}`);
      throw new functions.https.HttpsError("internal", "Failed to delete donation");
    }
  }
);

/**
 * Helper function to check if user is admin
 */
async function isAdmin(uid: string): Promise<boolean> {
  const userDoc = await db.collection("users").doc(uid).get();
  return userDoc.data()?.role === "admin";
}
