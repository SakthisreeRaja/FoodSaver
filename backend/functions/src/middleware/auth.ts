import { Request, Response, NextFunction } from "express";
import { auth, db } from "../index";
import * as functions from "firebase-functions";

export interface AuthenticatedRequest extends Request {
  uid?: string;
  userRole?: string;
  user?: any;
}

/**
 * Middleware to verify Firebase ID token
 */
export const verifyToken = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const token = req.headers.authorization?.split("Bearer ")[1];

    if (!token) {
      return res.status(401).json({ error: "No token provided" });
    }

    const decodedToken = await auth.verifyIdToken(token);
    req.uid = decodedToken.uid;

    // Get user role from Firestore
    const userDoc = await db.collection("users").doc(decodedToken.uid).get();
    if (userDoc.exists) {
      req.userRole = userDoc.data()?.role || "donor";
      req.user = userDoc.data();
    }

    next();
  } catch (error) {
    console.error("Auth middleware error:", error);
    return res.status(401).json({ error: "Unauthorized" });
  }
};

/**
 * Check if user has specific role
 */
export const requireRole = (allowedRoles: string[]) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.uid || !req.userRole) {
      return res.status(401).json({ error: "User not authenticated" });
    }

    if (!allowedRoles.includes(req.userRole)) {
      return res.status(403).json({ error: "Insufficient permissions" });
    }

    next();
  };
};

/**
 * Verify caller is authenticated (for callable functions)
 */
export const verifyAuth = (context: functions.https.CallableContext) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }
  return context.auth.uid;
};
