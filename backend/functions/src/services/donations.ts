import { db } from "../index";
import * as functions from "firebase-functions";
import { sendNotification, notifyNearbyNGOs } from "./notifications";
import { PICKUP_WINDOW_HOURS } from "../utils/constants";

export interface Donation {
  id?: string;
  donorId: string;
  foodName: string;
  description: string;
  quantity: number;
  category: string;
  expiryDate?: Date;
  location: string;
  latitude: number;
  longitude: number;
  imageUrl: string;
  status: "available" | "claimed" | "expired" | "completed";
  claimedBy?: string;
  claimedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Create a new donation
 */
export const createDonationService = async (
  donorId: string,
  data: {
    foodName: string;
    description: string;
    quantity: number;
    category: string;
    expiryDate?: string;
    location: string;
    latitude: number;
    longitude: number;
    imageUrl?: string;
  }
): Promise<string> => {
  try {
    const donationRef = db.collection("donations").doc();
    const donationId = donationRef.id;

    const donation: Donation = {
      id: donationId,
      donorId,
      foodName: data.foodName,
      description: data.description,
      quantity: data.quantity,
      category: data.category,
      expiryDate: data.expiryDate
        ? new Date(data.expiryDate)
        : new Date(Date.now() + PICKUP_WINDOW_HOURS * 60 * 60 * 1000),
      location: data.location,
      latitude: data.latitude,
      longitude: data.longitude,
      imageUrl: data.imageUrl || "",
      status: "available",
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await donationRef.set(donation);

    // Notify nearby NGOs
    await notifyNearbyNGOs(donationId, data.latitude, data.longitude);

    return donationId;
  } catch (error) {
    console.error("Error creating donation:", error);
    throw error;
  }
};

/**
 * Claim a donation
 */
export const claimDonation = async (
  donationId: string,
  ngoId: string
): Promise<void> => {
  try {
    const donationRef = db.collection("donations").doc(donationId);
    const donationDoc = await donationRef.get();

    if (!donationDoc.exists) {
      throw new Error("Donation not found");
    }

    const donation = donationDoc.data();

    if (donation.status !== "available") {
      throw new Error("Donation is no longer available");
    }

    // Update donation status
    await donationRef.update({
      status: "claimed",
      claimedBy: ngoId,
      claimedAt: new Date(),
      updatedAt: new Date(),
    });

    // Notify donor
    await sendNotification(
      donation.donorId,
      "Donation Claimed",
      "Your donation has been claimed by an NGO",
      "donation",
      { donationId }
    );

    // Create a pickup request
    const pickupRef = db.collection("pickups").doc();
    await pickupRef.set({
      id: pickupRef.id,
      donationId,
      donorId: donation.donorId,
      ngoId,
      status: "pending",
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  } catch (error) {
    console.error("Error claiming donation:", error);
    throw error;
  }
};

/**
 * Get donations by location (nearby)
 */
export const getNearbyDonations = async (
  latitude: number,
  longitude: number,
  radiusKm: number = 5,
  limit: number = 20
): Promise<(Donation & { distance: number })[]> => {
  try {
    const snapshot = await db
      .collection("donations")
      .where("status", "==", "available")
      .get();

    const donations = snapshot.docs
      .map((doc) => {
        const data = doc.data() as Donation;
        const distance = calculateDistance(
          latitude,
          longitude,
          data.latitude,
          data.longitude
        );
        return { ...data, distance };
      })
      .filter((d) => d.distance <= radiusKm)
      .sort((a, b) => a.distance - b.distance)
      .slice(0, limit);

    return donations;
  } catch (error) {
    console.error("Error fetching nearby donations:", error);
    throw error;
  }
};

/**
 * Get donor's donations
 */
export const getDonorDonations = async (
  donorId: string,
  status?: string
): Promise<Donation[]> => {
  try {
    let query: any = db
      .collection("donations")
      .where("donorId", "==", donorId);

    if (status) {
      query = query.where("status", "==", status);
    }

    const snapshot = await query.orderBy("createdAt", "desc").get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
      updatedAt: doc.data().updatedAt?.toDate(),
      expiryDate: doc.data().expiryDate?.toDate(),
    } as Donation));
  } catch (error) {
    console.error("Error fetching donor donations:", error);
    throw error;
  }
};

/**
 * Update donation status
 */
export const updateDonationStatus = async (
  donationId: string,
  status: string
): Promise<void> => {
  try {
    await db.collection("donations").doc(donationId).update({
      status,
      updatedAt: new Date(),
    });
  } catch (error) {
    console.error("Error updating donation status:", error);
    throw error;
  }
};

/**
 * Delete a donation
 */
export const deleteDonation = async (donationId: string): Promise<void> => {
  try {
    await db.collection("donations").doc(donationId).delete();
  } catch (error) {
    console.error("Error deleting donation:", error);
    throw error;
  }
};

/**
 * Calculate distance between coordinates
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
