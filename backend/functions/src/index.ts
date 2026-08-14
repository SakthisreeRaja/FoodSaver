import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const db = admin.firestore();
export const auth = admin.auth();

// Export all functions
export * from "./auth";
export * from "./donations";
export * from "./pickups";
export * from "./notifications";
export * from "./users";
export * from "./location";
