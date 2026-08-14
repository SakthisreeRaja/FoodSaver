import { db } from "../index";
import * as functions from "firebase-functions";
import { sendNotification, notifyNearbyNGOs } from "./notifications";

export interface Rating {
  id?: string;
  ratedById: string;
  targetId: string;
  targetType: "donor" | "ngo" | "volunteer";
  rating: number;
  review: string;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Create or update a rating
 */
export const createRating = async (
  ratedById: string,
  targetId: string,
  targetType: "donor" | "ngo" | "volunteer",
  rating: number,
  review: string
): Promise<string> => {
  try {
    if (rating < 1 || rating > 5) {
      throw new Error("Rating must be between 1 and 5");
    }

    // Check if rating already exists
    const existingSnapshot = await db
      .collection("ratings")
      .where("ratedById", "==", ratedById)
      .where("targetId", "==", targetId)
      .get();

    let ratingId: string;

    if (existingSnapshot.empty) {
      // Create new rating
      const ratingRef = db.collection("ratings").doc();
      ratingId = ratingRef.id;

      await ratingRef.set({
        id: ratingId,
        ratedById,
        targetId,
        targetType,
        rating,
        review,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    } else {
      // Update existing rating
      ratingId = existingSnapshot.docs[0].id;
      await db.collection("ratings").doc(ratingId).update({
        rating,
        review,
        updatedAt: new Date(),
      });
    }

    // Update target user's average rating
    await updateUserAverageRating(targetId);

    // Notify the rated user
    const raterDoc = await db.collection("users").doc(ratedById).get();
    const raterName = raterDoc.data()?.displayName || "Someone";

    await sendNotification(
      targetId,
      "New Rating",
      `${raterName} gave you a ${rating} star rating`,
      "rating",
      { ratingId, rating }
    );

    return ratingId;
  } catch (error) {
    console.error("Error creating rating:", error);
    throw error;
  }
};

/**
 * Get ratings for a user
 */
export const getUserRatings = async (userId: string): Promise<Rating[]> => {
  try {
    const snapshot = await db
      .collection("ratings")
      .where("targetId", "==", userId)
      .orderBy("createdAt", "desc")
      .get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
      updatedAt: doc.data().updatedAt?.toDate(),
    } as Rating));
  } catch (error) {
    console.error("Error fetching ratings:", error);
    throw error;
  }
};

/**
 * Get average rating for a user
 */
export const getUserAverageRating = async (userId: string): Promise<number> => {
  try {
    const snapshot = await db
      .collection("ratings")
      .where("targetId", "==", userId)
      .get();

    if (snapshot.empty) return 0;

    const totalRating = snapshot.docs.reduce(
      (sum, doc) => sum + (doc.data().rating || 0),
      0
    );

    return Math.round((totalRating / snapshot.size) * 10) / 10;
  } catch (error) {
    console.error("Error calculating average rating:", error);
    return 0;
  }
};

/**
 * Update user's average rating
 */
export const updateUserAverageRating = async (userId: string): Promise<void> => {
  try {
    const averageRating = await getUserAverageRating(userId);
    await db.collection("users").doc(userId).update({
      averageRating,
      updatedAt: new Date(),
    });
  } catch (error) {
    console.error("Error updating average rating:", error);
  }
};

/**
 * Delete a rating
 */
export const deleteRating = async (ratingId: string): Promise<void> => {
  try {
    const ratingDoc = await db.collection("ratings").doc(ratingId).get();
    if (!ratingDoc.exists) {
      throw new Error("Rating not found");
    }

    const targetId = ratingDoc.data()?.targetId;
    await db.collection("ratings").doc(ratingId).delete();

    // Update user's average rating
    if (targetId) {
      await updateUserAverageRating(targetId);
    }
  } catch (error) {
    console.error("Error deleting rating:", error);
    throw error;
  }
};
