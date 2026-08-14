import * as functions from "firebase-functions";
import { db } from "./index";

const axios = require("axios");

const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;

/**
 * Get nearby donations based on coordinates
 */
export const getNearbyDonations = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { latitude, longitude, radiusKm = 5 } = data;

    if (!latitude || !longitude) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Latitude and longitude are required"
      );
    }

    try {
      // Get all available donations
      const snapshot = await db
        .collection("donations")
        .where("status", "==", "available")
        .get();

      const donations = snapshot.docs.map((doc) => doc.data());

      // Filter by distance (simple haversine calculation)
      const nearbyDonations = donations.filter((donation) => {
        if (!donation.latitude || !donation.longitude) return false;

        const distance = calculateDistance(
          latitude,
          longitude,
          donation.latitude,
          donation.longitude
        );

        return distance <= radiusKm;
      });

      // Sort by distance
      const sortedDonations = nearbyDonations.sort((a, b) => {
        const distA = calculateDistance(
          latitude,
          longitude,
          a.latitude,
          a.longitude
        );
        const distB = calculateDistance(
          latitude,
          longitude,
          b.latitude,
          b.longitude
        );
        return distA - distB;
      });

      return {
        success: true,
        donations: sortedDonations,
        count: sortedDonations.length,
      };
    } catch (error) {
      console.error(`Error finding nearby donations: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to find nearby donations"
      );
    }
  }
);

/**
 * Get directions between two points
 */
export const getDirections = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { originLat, originLng, destLat, destLng, mode = "driving" } = data;

    if (
      !originLat ||
      !originLng ||
      !destLat ||
      !destLng ||
      !GOOGLE_MAPS_API_KEY
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters or API key"
      );
    }

    try {
      const response = await axios.get(
        "https://maps.googleapis.com/maps/api/directions/json",
        {
          params: {
            origin: `${originLat},${originLng}`,
            destination: `${destLat},${destLng}`,
            mode,
            key: GOOGLE_MAPS_API_KEY,
          },
        }
      );

      if (response.data.status !== "OK") {
        throw new Error(`Google Maps API error: ${response.data.status}`);
      }

      const route = response.data.routes[0];
      const leg = route.legs[0];

      return {
        success: true,
        distance: leg.distance.text,
        distanceValue: leg.distance.value,
        duration: leg.duration.text,
        durationValue: leg.duration.value,
        polyline: route.overview_polyline.points,
        steps: leg.steps.map((step: any) => ({
          instruction: step.html_instructions,
          distance: step.distance.text,
          duration: step.duration.text,
        })),
      };
    } catch (error) {
      console.error(`Error getting directions: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to get directions"
      );
    }
  }
);

/**
 * Geocode address to coordinates
 */
export const geocodeAddress = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { address } = data;

    if (!address || !GOOGLE_MAPS_API_KEY) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Address is required or API key is missing"
      );
    }

    try {
      const response = await axios.get(
        "https://maps.googleapis.com/maps/api/geocode/json",
        {
          params: {
            address,
            key: GOOGLE_MAPS_API_KEY,
          },
        }
      );

      if (response.data.status !== "OK") {
        throw new Error(`Google Maps API error: ${response.data.status}`);
      }

      const result = response.data.results[0];
      const location = result.geometry.location;

      return {
        success: true,
        latitude: location.lat,
        longitude: location.lng,
        formattedAddress: result.formatted_address,
      };
    } catch (error) {
      console.error(`Error geocoding address: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to geocode address"
      );
    }
  }
);

/**
 * Reverse geocode coordinates to address
 */
export const reverseGeocodeCoordinates = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { latitude, longitude } = data;

    if (!latitude || !longitude || !GOOGLE_MAPS_API_KEY) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Latitude and longitude are required or API key is missing"
      );
    }

    try {
      const response = await axios.get(
        "https://maps.googleapis.com/maps/api/geocode/json",
        {
          params: {
            latlng: `${latitude},${longitude}`,
            key: GOOGLE_MAPS_API_KEY,
          },
        }
      );

      if (response.data.status !== "OK") {
        throw new Error(`Google Maps API error: ${response.data.status}`);
      }

      const result = response.data.results[0];

      return {
        success: true,
        address: result.formatted_address,
        city: extractAddressComponent(result, "locality"),
        state: extractAddressComponent(result, "administrative_area_level_1"),
        country: extractAddressComponent(result, "country"),
        zipCode: extractAddressComponent(result, "postal_code"),
      };
    } catch (error) {
      console.error(`Error reverse geocoding: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to reverse geocode"
      );
    }
  }
);

/**
 * Helper function to extract address components
 */
function extractAddressComponent(result: any, type: string): string {
  const component = result.address_components.find((comp: any) =>
    comp.types.includes(type)
  );
  return component ? component.long_name : "";
}

/**
 * Calculate distance between two coordinates using Haversine formula
 */
export function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth's radius in kilometers
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  return distance;
}

/**
 * Get place details by place ID
 */
export const getPlaceDetails = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { placeId } = data;

    if (!placeId || !GOOGLE_MAPS_API_KEY) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Place ID is required or API key is missing"
      );
    }

    try {
      const response = await axios.get(
        "https://maps.googleapis.com/maps/api/place/details/json",
        {
          params: {
            place_id: placeId,
            key: GOOGLE_MAPS_API_KEY,
          },
        }
      );

      if (response.data.status !== "OK") {
        throw new Error(`Google Places API error: ${response.data.status}`);
      }

      const place = response.data.result;

      return {
        success: true,
        name: place.name,
        address: place.formatted_address,
        latitude: place.geometry.location.lat,
        longitude: place.geometry.location.lng,
        phoneNumber: place.formatted_phone_number || "",
        website: place.website || "",
        rating: place.rating || 0,
      };
    } catch (error) {
      console.error(`Error getting place details: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to get place details"
      );
    }
  }
);
