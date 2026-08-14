import { db } from "../index";

export interface AnalyticsData {
  totalDonations: number;
  totalPickups: number;
  totalDonors: number;
  totalNGOs: number;
  foodWastedPrevented: number; // in kg
  donationsByCategory: Record<string, number>;
  pickupsByStatus: Record<string, number>;
  averageRating: number;
  topDonors: Array<{ userId: string; donations: number }>;
  topNGOs: Array<{ ngoId: string; pickups: number }>;
}

/**
 * Get overall platform analytics
 */
export const getPlatformAnalytics = async (): Promise<AnalyticsData> => {
  try {
    const donationSnapshot = await db.collection("donations").get();
    const pickupSnapshot = await db.collection("pickups").get();
    const userSnapshot = await db.collection("users").get();
    const ratingSnapshot = await db.collection("ratings").get();

    let totalFoodWasted = 0;
    let donationsByCategory: Record<string, number> = {};
    let pickupsByStatus: Record<string, number> = {};
    let totalRating = 0;
    let ratingCount = 0;

    // Process donations
    donationSnapshot.forEach((doc) => {
      const data = doc.data();
      const category = data.category || "other";
      donationsByCategory[category] = (donationsByCategory[category] || 0) + 1;

      if (data.quantity) {
        totalFoodWasted += data.quantity;
      }
    });

    // Process pickups
    pickupSnapshot.forEach((doc) => {
      const data = doc.data();
      const status = data.status || "pending";
      pickupsByStatus[status] = (pickupsByStatus[status] || 0) + 1;
    });

    // Process ratings
    ratingSnapshot.forEach((doc) => {
      const data = doc.data();
      totalRating += data.rating || 0;
      ratingCount++;
    });

    // Count users by role
    let totalDonors = 0;
    let totalNGOs = 0;

    userSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.role === "donor") totalDonors++;
      if (data.role === "ngo") totalNGOs++;
    });

    // Get top donors
    const topDonorsSnapshot = await db
      .collectionGroup("donations")
      .groupBy("donorId")
      .limit(5)
      .get();

    const topDonors = await getTopDonors();
    const topNGOs = await getTopNGOs();

    return {
      totalDonations: donationSnapshot.size,
      totalPickups: pickupSnapshot.size,
      totalDonors,
      totalNGOs,
      foodWastedPrevented: Math.round(totalFoodWasted * 100) / 100,
      donationsByCategory,
      pickupsByStatus,
      averageRating: ratingCount > 0 ? totalRating / ratingCount : 0,
      topDonors,
      topNGOs,
    };
  } catch (error) {
    console.error("Error fetching analytics:", error);
    throw error;
  }
};

/**
 * Get top donors
 */
export const getTopDonors = async (
  limit: number = 10
): Promise<Array<{ userId: string; donations: number }>> => {
  try {
    const snapshot = await db.collection("donations").get();
    const donorMap: Record<string, number> = {};

    snapshot.forEach((doc) => {
      const donorId = doc.data().donorId;
      donorMap[donorId] = (donorMap[donorId] || 0) + 1;
    });

    return Object.entries(donorMap)
      .map(([userId, donations]) => ({ userId, donations }))
      .sort((a, b) => b.donations - a.donations)
      .slice(0, limit);
  } catch (error) {
    console.error("Error fetching top donors:", error);
    return [];
  }
};

/**
 * Get top NGOs
 */
export const getTopNGOs = async (
  limit: number = 10
): Promise<Array<{ ngoId: string; pickups: number }>> => {
  try {
    const snapshot = await db.collection("pickups").get();
    const ngoMap: Record<string, number> = {};

    snapshot.forEach((doc) => {
      const ngoId = doc.data().ngoId;
      ngoMap[ngoId] = (ngoMap[ngoId] || 0) + 1;
    });

    return Object.entries(ngoMap)
      .map(([ngoId, pickups]) => ({ ngoId, pickups }))
      .sort((a, b) => b.pickups - a.pickups)
      .slice(0, limit);
  } catch (error) {
    console.error("Error fetching top NGOs:", error);
    return [];
  }
};

/**
 * Get user-specific analytics
 */
export const getUserAnalytics = async (userId: string) => {
  try {
    const donationSnapshot = await db
      .collection("donations")
      .where("donorId", "==", userId)
      .get();

    const pickupSnapshot = await db
      .collection("pickups")
      .where("ngoId", "==", userId)
      .get();

    const ratingSnapshot = await db
      .collection("ratings")
      .where("targetId", "==", userId)
      .get();

    let totalQuantity = 0;
    let donationsByStatus: Record<string, number> = {};

    donationSnapshot.forEach((doc) => {
      const data = doc.data();
      donationsByStatus[data.status] =
        (donationsByStatus[data.status] || 0) + 1;
      totalQuantity += data.quantity || 0;
    });

    let totalRating = 0;
    ratingSnapshot.forEach((doc) => {
      totalRating += doc.data().rating || 0;
    });

    return {
      totalDonations: donationSnapshot.size,
      totalPickups: pickupSnapshot.size,
      totalFoodQuantity: totalQuantity,
      donationsByStatus,
      averageRating:
        ratingSnapshot.size > 0
          ? Math.round((totalRating / ratingSnapshot.size) * 10) / 10
          : 0,
    };
  } catch (error) {
    console.error("Error fetching user analytics:", error);
    throw error;
  }
};
