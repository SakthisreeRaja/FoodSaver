import axios from "axios";

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models";

interface FoodAnalysisResult {
  foodType: string;
  freshness: "fresh" | "medium" | "old";
  estimatedExpiry: number; // hours
  nutritionEstimate: string;
  storageRecommendation: string;
  safeForConsumption: boolean;
  warnings: string[];
}

/**
 * Analyze food image using Google Gemini AI
 */
export const analyzeFoodImage = async (
  imageBase64: string,
  mimeType: string = "image/jpeg"
): Promise<FoodAnalysisResult> => {
  try {
    if (!GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY not configured");
    }

    const response = await axios.post(
      `${GEMINI_BASE_URL}/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        contents: [
          {
            parts: [
              {
                inlineData: {
                  mimeType,
                  data: imageBase64,
                },
              },
              {
                text: `Analyze this food image and provide:
1. What type of food is this?
2. How fresh does it look? (fresh/medium/old)
3. Estimated hours until expiry
4. Brief nutrition estimate
5. Storage recommendations
6. Is it safe for consumption?
7. Any warnings or concerns

Respond in JSON format:
{
  "foodType": "",
  "freshness": "",
  "estimatedExpiry": 0,
  "nutritionEstimate": "",
  "storageRecommendation": "",
  "safeForConsumption": true,
  "warnings": []
}`,
              },
            ],
          },
        ],
      }
    );

    const content = response.data.candidates[0].content.parts[0].text;
    
    // Parse JSON from response
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error("Could not parse AI response");
    }

    return JSON.parse(jsonMatch[0]) as FoodAnalysisResult;
  } catch (error) {
    console.error("Gemini AI analysis error:", error);
    throw new Error("Failed to analyze food image");
  }
};

/**
 * Get food recommendations based on available donations
 */
export const getFoodRecommendations = async (
  userDietaryPreferences: string[],
  availableFoods: string[]
): Promise<string[]> => {
  try {
    if (!GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY not configured");
    }

    const response = await axios.post(
      `${GEMINI_BASE_URL}/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        contents: [
          {
            parts: [
              {
                text: `Based on dietary preferences: ${userDietaryPreferences.join(", ")}
Available foods: ${availableFoods.join(", ")}

Recommend top 5 foods from the available list that match the dietary preferences.
Return as JSON array of strings.`,
              },
            ],
          },
        ],
      }
    );

    const content = response.data.candidates[0].content.parts[0].text;
    const jsonMatch = content.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      return availableFoods.slice(0, 5);
    }

    return JSON.parse(jsonMatch[0]) as string[];
  } catch (error) {
    console.error("Recommendations error:", error);
    return availableFoods.slice(0, 5);
  }
};
