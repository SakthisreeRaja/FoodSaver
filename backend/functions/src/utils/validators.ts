/**
 * Validate email format
 */
export const isValidEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Validate phone number
 */
export const isValidPhone = (phone: string): boolean => {
  const phoneRegex = /^\+?[\d\s-]{10,}$/;
  return phoneRegex.test(phone);
};

/**
 * Validate coordinates
 */
export const isValidCoordinates = (
  latitude: number,
  longitude: number
): boolean => {
  return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
};

/**
 * Validate required fields
 */
export const validateRequiredFields = (
  data: Record<string, any>,
  requiredFields: string[]
): { valid: boolean; missingFields: string[] } => {
  const missingFields = requiredFields.filter(
    (field) => !data[field] || (typeof data[field] === "string" && !data[field].trim())
  );

  return {
    valid: missingFields.length === 0,
    missingFields,
  };
};

/**
 * Validate food categories
 */
export const isValidFoodCategory = (category: string): boolean => {
  const validCategories = [
    "vegetables",
    "fruits",
    "dairy",
    "bakery",
    "prepared",
    "packaged",
    "other",
  ];
  return validCategories.includes(category.toLowerCase());
};

/**
 * Validate donation status
 */
export const isValidDonationStatus = (status: string): boolean => {
  const validStatuses = ["available", "claimed", "expired", "completed"];
  return validStatuses.includes(status.toLowerCase());
};

/**
 * Validate pickup status
 */
export const isValidPickupStatus = (status: string): boolean => {
  const validStatuses = ["pending", "confirmed", "in_transit", "completed", "cancelled"];
  return validStatuses.includes(status.toLowerCase());
};

/**
 * Validate user role
 */
export const isValidRole = (role: string): boolean => {
  const validRoles = ["donor", "ngo", "volunteer", "admin"];
  return validRoles.includes(role.toLowerCase());
};
