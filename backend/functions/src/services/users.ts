import { db } from "../index";

export interface UserProfile {
  uid: string;
  email: string;
  displayName: string;
  photoURL: string;
  role: "donor" | "ngo" | "volunteer" | "admin";
  phone: string;
  address: string;
  latitude?: number;
  longitude?: number;
  isActive: boolean;
  fcmTokens: string[];
  averageRating?: number;
  totalDonations?: number;
  totalPickups?: number;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Get user profile
 */
export const getUserProfile = async (userId: string): Promise<UserProfile | null> => {
  try {
    const doc = await db.collection("users").doc(userId).get();
    if (!doc.exists) return null;

    return {
      uid: doc.id,
      ...doc.data(),
      createdAt: doc.data()?.createdAt?.toDate(),
      updatedAt: doc.data()?.updatedAt?.toDate(),
    } as UserProfile;
  } catch (error) {
    console.error("Error fetching user profile:", error);
    throw error;
  }
};

/**
 * Update user profile
 */
export const updateUserProfile = async (
  userId: string,
  updates: Partial<UserProfile>
): Promise<void> => {
  try {
    const updateData = {
      ...updates,
      updatedAt: new Date(),
    };

    await db.collection("users").doc(userId).update(updateData);
  } catch (error) {
    console.error("Error updating user profile:", error);
    throw error;
  }
};

/**
 * Add FCM token
 */
export const addFCMToken = async (userId: string, token: string): Promise<void> => {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    const currentTokens = userDoc.data()?.fcmTokens || [];

    if (!currentTokens.includes(token)) {
      await db.collection("users").doc(userId).update({
        fcmTokens: [...currentTokens, token],
      });
    }
  } catch (error) {
    console.error("Error adding FCM token:", error);
    throw error;
  }
};

/**
 * Remove FCM token
 */
export const removeFCMToken = async (userId: string, token: string): Promise<void> => {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    const currentTokens = userDoc.data()?.fcmTokens || [];

    const updatedTokens = currentTokens.filter((t: string) => t !== token);

    await db.collection("users").doc(userId).update({
      fcmTokens: updatedTokens,
    });
  } catch (error) {
    console.error("Error removing FCM token:", error);
    throw error;
  }
};

/**
 * Get all users by role
 */
export const getUsersByRole = async (
  role: "donor" | "ngo" | "volunteer" | "admin"
): Promise<UserProfile[]> => {
  try {
    const snapshot = await db.collection("users").where("role", "==", role).get();

    return snapshot.docs.map((doc) => ({
      uid: doc.id,
      ...doc.data(),
      createdAt: doc.data()?.createdAt?.toDate(),
      updatedAt: doc.data()?.updatedAt?.toDate(),
    } as UserProfile));
  } catch (error) {
    console.error("Error fetching users by role:", error);
    throw error;
  }
};

/**
 * Search users by name or email
 */
export const searchUsers = async (query: string): Promise<UserProfile[]> => {
  try {
    const snapshot = await db
      .collection("users")
      .where("displayName", ">=", query)
      .where("displayName", "<=", query + "\uf8ff")
      .limit(20)
      .get();

    return snapshot.docs.map((doc) => ({
      uid: doc.id,
      ...doc.data(),
      createdAt: doc.data()?.createdAt?.toDate(),
      updatedAt: doc.data()?.updatedAt?.toDate(),
    } as UserProfile));
  } catch (error) {
    console.error("Error searching users:", error);
    throw error;
  }
};

/**
 * Deactivate user account
 */
export const deactivateUser = async (userId: string): Promise<void> => {
  try {
    await db.collection("users").doc(userId).update({
      isActive: false,
      updatedAt: new Date(),
    });
  } catch (error) {
    console.error("Error deactivating user:", error);
    throw error;
  }
};

/**
 * Reactivate user account
 */
export const reactivateUser = async (userId: string): Promise<void> => {
  try {
    await db.collection("users").doc(userId).update({
      isActive: true,
      updatedAt: new Date(),
    });
  } catch (error) {
    console.error("Error reactivating user:", error);
    throw error;
  }
};

/**
 * Change user role
 */
export const changeUserRole = async (
  userId: string,
  newRole: "donor" | "ngo" | "volunteer" | "admin"
): Promise<void> => {
  try {
    await db.collection("users").doc(userId).update({
      role: newRole,
      updatedAt: new Date(),
    });
  } catch (error) {
    console.error("Error changing user role:", error);
    throw error;
  }
};

/**
 * Get nearby users
 */
export const getNearbyUsers = async (
  latitude: number,
  longitude: number,
  role?: string,
  radiusKm: number = 10
): Promise<(UserProfile & { distance: number })[]> => {
  try {
    let query: any = db.collection("users");

    if (role) {
      query = query.where("role", "==", role);
    }

    const snapshot = await query.get();

    const nearby = snapshot.docs
      .map((doc) => {
        const data = doc.data() as UserProfile;
        if (!data.latitude || !data.longitude) return null;

        const distance = calculateDistance(
          latitude,
          longitude,
          data.latitude,
          data.longitude
        );

        return {
          uid: doc.id,
          ...data,
          distance,
          createdAt: data.createdAt,
          updatedAt: data.updatedAt,
        };
      })
      .filter(
        (user): user is UserProfile & { distance: number } =>
          user !== null && user.distance <= radiusKm
      )
      .sort((a, b) => a.distance - b.distance);

    return nearby;
  } catch (error) {
    console.error("Error finding nearby users:", error);
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
