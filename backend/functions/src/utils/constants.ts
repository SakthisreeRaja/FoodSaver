export const FOOD_CATEGORIES = [
  "vegetables",
  "fruits",
  "dairy",
  "bakery",
  "prepared",
  "packaged",
  "other",
];

export const DONATION_STATUS = {
  AVAILABLE: "available",
  CLAIMED: "claimed",
  EXPIRED: "expired",
  COMPLETED: "completed",
};

export const PICKUP_STATUS = {
  PENDING: "pending",
  CONFIRMED: "confirmed",
  IN_TRANSIT: "in_transit",
  COMPLETED: "completed",
  CANCELLED: "cancelled",
};

export const USER_ROLES = {
  DONOR: "donor",
  NGO: "ngo",
  VOLUNTEER: "volunteer",
  ADMIN: "admin",
};

export const DEFAULT_SEARCH_RADIUS = 5; // km
export const MAX_SEARCH_RADIUS = 50; // km

export const PICKUP_WINDOW_HOURS = 24; // Donations expire after 24 hours

export const RATINGS = {
  MIN: 1,
  MAX: 5,
};

export const PAGINATION = {
  DEFAULT_PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 100,
};
