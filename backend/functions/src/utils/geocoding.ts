import axios from "axios";

const NOMINATIM_BASE = "https://nominatim.openstreetmap.org";

/**
 * Get coordinates from address using OpenStreetMap
 */
export const getCoordinatesFromAddress = async (
  address: string
): Promise<{ latitude: number; longitude: number } | null> => {
  try {
    const response = await axios.get(`${NOMINATIM_BASE}/search`, {
      params: {
        q: address,
        format: "json",
        limit: 1,
      },
      headers: {
        "User-Agent": "FoodSaver/1.0",
      },
    });

    if (response.data && response.data.length > 0) {
      const result = response.data[0];
      return {
        latitude: parseFloat(result.lat),
        longitude: parseFloat(result.lon),
      };
    }

    return null;
  } catch (error) {
    console.error("Geocoding error:", error);
    return null;
  }
};

/**
 * Get address from coordinates using OpenStreetMap
 */
export const getAddressFromCoordinates = async (
  latitude: number,
  longitude: number
): Promise<string | null> => {
  try {
    const response = await axios.get(`${NOMINATIM_BASE}/reverse`, {
      params: {
        lat: latitude,
        lon: longitude,
        format: "json",
      },
      headers: {
        "User-Agent": "FoodSaver/1.0",
      },
    });

    if (response.data && response.data.address) {
      return response.data.display_name || "";
    }

    return null;
  } catch (error) {
    console.error("Reverse geocoding error:", error);
    return null;
  }
};

/**
 * Calculate distance between two coordinates (in km)
 */
export const calculateDistance = (
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number => {
  const R = 6371; // Earth's radius in km
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

/**
 * Find nearby locations
 */
export const findNearby = (
  userLat: number,
  userLon: number,
  locations: Array<{ latitude: number; longitude: number; [key: string]: any }>,
  radiusKm: number = 5
) => {
  return locations
    .map((location) => ({
      ...location,
      distance: calculateDistance(
        userLat,
        userLon,
        location.latitude,
        location.longitude
      ),
    }))
    .filter((location) => location.distance <= radiusKm)
    .sort((a, b) => a.distance - b.distance);
};
