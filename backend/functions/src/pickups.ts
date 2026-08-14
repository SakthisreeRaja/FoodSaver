import * as functions from "firebase-functions";
import { db } from "./index";

/**
 * Create a pickup request
 */
export const createPickup = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { donationId, volunteerId, pickupTime, notes } = data;

    if (!donationId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Donation ID is required"
      );
    }

    try {
      const pickupRef = db.collection("pickups").doc();
      await pickupRef.set({
        id: pickupRef.id,
        donationId,
        volunteerId: volunteerId || context.auth.uid,
        ngoId: "", // Will be set when NGO claims
        scheduledTime: pickupTime ? new Date(pickupTime) : null,
        actualPickupTime: null,
        status: "pending", // pending, confirmed, in_transit, completed, cancelled
        notes: notes || "",
        createdAt: new Date(),
        updatedAt: new Date(),
        rating: 0,
        feedback: "",
      });

      // Update donation status
      await db.collection("donations").doc(donationId).update({
        status: "claimed",
        updatedAt: new Date(),
      });

      return {
        success: true,
        message: "Pickup created successfully",
        pickupId: pickupRef.id,
      };
    } catch (error) {
      console.error(`Error creating pickup: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to create pickup"
      );
    }
  }
);

/**
 * Get pending pickups for volunteer
 */
export const getPendingPickups = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    try {
      const snapshot = await db
        .collection("pickups")
        .where("volunteerId", "==", context.auth.uid)
        .where("status", "in", ["pending", "confirmed", "in_transit"])
        .orderBy("scheduledTime", "asc")
        .get();

      const pickups = await Promise.all(
        snapshot.docs.map(async (doc) => {
          const pickup = doc.data();
          const donationDoc = await db
            .collection("donations")
            .doc(pickup.donationId)
            .get();
          return {
            ...pickup,
            donation: donationDoc.data(),
          };
        })
      );

      return { success: true, pickups };
    } catch (error) {
      console.error(`Error fetching pickups: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch pickups"
      );
    }
  }
);

/**
 * Get pickups for NGO
 */
export const getNGOPickups = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { status } = data;

    try {
      let query = db
        .collection("pickups")
        .where("ngoId", "==", context.auth.uid);

      if (status) {
        query = query.where("status", "==", status);
      }

      const snapshot = await query.orderBy("createdAt", "desc").get();

      const pickups = await Promise.all(
        snapshot.docs.map(async (doc) => {
          const pickup = doc.data();
          const donationDoc = await db
            .collection("donations")
            .doc(pickup.donationId)
            .get();
          return {
            ...pickup,
            donation: donationDoc.data(),
          };
        })
      );

      return { success: true, pickups };
    } catch (error) {
      console.error(`Error fetching NGO pickups: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch pickups"
      );
    }
  }
);

/**
 * Update pickup status
 */
export const updatePickupStatus = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { pickupId, status } = data;
    const validStatuses = [
      "pending",
      "confirmed",
      "in_transit",
      "completed",
      "cancelled",
    ];

    if (!validStatuses.includes(status)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid status");
    }

    try {
      const pickupRef = db.collection("pickups").doc(pickupId);
      const pickupDoc = await pickupRef.get();

      if (!pickupDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Pickup not found");
      }

      const updateData: any = {
        status,
        updatedAt: new Date(),
      };

      if (status === "completed") {
        updateData.actualPickupTime = new Date();
      }

      await pickupRef.update(updateData);

      return { success: true, message: "Pickup status updated" };
    } catch (error) {
      console.error(`Error updating pickup: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to update pickup"
      );
    }
  }
);

/**
 * Assign pickup to NGO
 */
export const assignPickupToNGO = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { pickupId, ngoId } = data;

    if (!pickupId || !ngoId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Pickup ID and NGO ID are required"
      );
    }

    try {
      const pickupRef = db.collection("pickups").doc(pickupId);
      await pickupRef.update({
        ngoId,
        status: "confirmed",
        updatedAt: new Date(),
      });

      return { success: true, message: "Pickup assigned to NGO" };
    } catch (error) {
      console.error(`Error assigning pickup: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to assign pickup"
      );
    }
  }
);

/**
 * Rate and review a pickup
 */
export const ratePickup = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { pickupId, rating, feedback } = data;

    if (!pickupId || typeof rating !== "number" || rating < 1 || rating > 5) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid rating or pickup ID"
      );
    }

    try {
      const pickupRef = db.collection("pickups").doc(pickupId);
      await pickupRef.update({
        rating,
        feedback: feedback || "",
        updatedAt: new Date(),
      });

      return { success: true, message: "Pickup rated successfully" };
    } catch (error) {
      console.error(`Error rating pickup: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to rate pickup"
      );
    }
  }
);
