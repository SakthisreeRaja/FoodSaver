import { db } from "../index";
import { sendNotification } from "./notifications";

export interface Pickup {
  id?: string;
  donationId: string;
  donorId: string;
  ngoId: string;
  volunteerId?: string;
  status: "pending" | "confirmed" | "in_transit" | "completed" | "cancelled";
  scheduledTime?: Date;
  completedTime?: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Create a pickup request
 */
export const createPickup = async (
  donationId: string,
  donorId: string,
  ngoId: string,
  scheduledTime?: Date,
  notes?: string
): Promise<string> => {
  try {
    const pickupRef = db.collection("pickups").doc();
    const pickupId = pickupRef.id;

    const pickup: Pickup = {
      id: pickupId,
      donationId,
      donorId,
      ngoId,
      status: "pending",
      scheduledTime: scheduledTime || new Date(Date.now() + 24 * 60 * 60 * 1000),
      notes: notes || "",
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await pickupRef.set(pickup);

    // Notify donor
    await sendNotification(
      donorId,
      "Pickup Scheduled",
      "An NGO has scheduled a pickup for your donation",
      "pickup",
      { pickupId, donationId }
    );

    // Notify NGO
    await sendNotification(
      ngoId,
      "Pickup Created",
      "A new pickup request has been created",
      "pickup",
      { pickupId, donationId }
    );

    return pickupId;
  } catch (error) {
    console.error("Error creating pickup:", error);
    throw error;
  }
};

/**
 * Confirm pickup
 */
export const confirmPickup = async (
  pickupId: string,
  volunteerId: string,
  scheduledTime?: Date
): Promise<void> => {
  try {
    const pickupRef = db.collection("pickups").doc(pickupId);
    const pickupDoc = await pickupRef.get();

    if (!pickupDoc.exists) {
      throw new Error("Pickup not found");
    }

    const pickup = pickupDoc.data();

    await pickupRef.update({
      status: "confirmed",
      volunteerId,
      scheduledTime: scheduledTime || pickup.scheduledTime,
      updatedAt: new Date(),
    });

    // Notify donor and NGO
    await sendNotification(
      pickup.donorId,
      "Pickup Confirmed",
      `Pickup has been confirmed for ${scheduledTime?.toLocaleString() || ""}`,
      "pickup",
      { pickupId }
    );

    await sendNotification(
      pickup.ngoId,
      "Pickup Confirmed",
      "Pickup has been confirmed",
      "pickup",
      { pickupId }
    );

    // Notify volunteer
    await sendNotification(
      volunteerId,
      "Pickup Assignment",
      "You have been assigned a pickup",
      "pickup",
      { pickupId }
    );
  } catch (error) {
    console.error("Error confirming pickup:", error);
    throw error;
  }
};

/**
 * Update pickup status
 */
export const updatePickupStatus = async (
  pickupId: string,
  status: "in_transit" | "completed" | "cancelled"
): Promise<void> => {
  try {
    const pickupRef = db.collection("pickups").doc(pickupId);
    const pickupDoc = await pickupRef.get();

    if (!pickupDoc.exists) {
      throw new Error("Pickup not found");
    }

    const pickup = pickupDoc.data();

    let updateData: any = {
      status,
      updatedAt: new Date(),
    };

    if (status === "completed") {
      updateData.completedTime = new Date();

      // Update donation status
      await db.collection("donations").doc(pickup.donationId).update({
        status: "completed",
      });
    }

    await pickupRef.update(updateData);

    // Notify relevant parties
    const notificationTitle =
      status === "in_transit"
        ? "Pickup In Transit"
        : status === "completed"
          ? "Pickup Completed"
          : "Pickup Cancelled";

    const notificationBody =
      status === "in_transit"
        ? "Your pickup is on its way"
        : status === "completed"
          ? "Pickup has been completed"
          : "Pickup has been cancelled";

    await sendNotification(pickup.donorId, notificationTitle, notificationBody, "pickup", {
      pickupId,
    });
    await sendNotification(pickup.ngoId, notificationTitle, notificationBody, "pickup", {
      pickupId,
    });
  } catch (error) {
    console.error("Error updating pickup status:", error);
    throw error;
  }
};

/**
 * Get pickups by NGO
 */
export const getNGOPickups = async (
  ngoId: string,
  status?: string
): Promise<Pickup[]> => {
  try {
    let query: any = db.collection("pickups").where("ngoId", "==", ngoId);

    if (status) {
      query = query.where("status", "==", status);
    }

    const snapshot = await query.orderBy("createdAt", "desc").get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
      updatedAt: doc.data().updatedAt?.toDate(),
      scheduledTime: doc.data().scheduledTime?.toDate(),
      completedTime: doc.data().completedTime?.toDate(),
    } as Pickup));
  } catch (error) {
    console.error("Error fetching NGO pickups:", error);
    throw error;
  }
};

/**
 * Get pickups by volunteer
 */
export const getVolunteerPickups = async (
  volunteerId: string,
  status?: string
): Promise<Pickup[]> => {
  try {
    let query: any = db.collection("pickups").where("volunteerId", "==", volunteerId);

    if (status) {
      query = query.where("status", "==", status);
    }

    const snapshot = await query.orderBy("createdAt", "desc").get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
      updatedAt: doc.data().updatedAt?.toDate(),
      scheduledTime: doc.data().scheduledTime?.toDate(),
      completedTime: doc.data().completedTime?.toDate(),
    } as Pickup));
  } catch (error) {
    console.error("Error fetching volunteer pickups:", error);
    throw error;
  }
};

/**
 * Get donor's pickups
 */
export const getDonorPickups = async (
  donorId: string,
  status?: string
): Promise<Pickup[]> => {
  try {
    let query: any = db.collection("pickups").where("donorId", "==", donorId);

    if (status) {
      query = query.where("status", "==", status);
    }

    const snapshot = await query.orderBy("createdAt", "desc").get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
      updatedAt: doc.data().updatedAt?.toDate(),
      scheduledTime: doc.data().scheduledTime?.toDate(),
      completedTime: doc.data().completedTime?.toDate(),
    } as Pickup));
  } catch (error) {
    console.error("Error fetching donor pickups:", error);
    throw error;
  }
};
