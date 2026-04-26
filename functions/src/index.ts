import {onCall} from "firebase-functions/v2/https";
import {genkit, z} from "genkit";
import {googleAI} from "@genkit-ai/google-genai";

// Initialize Genkit with the API Key from your Cloud Secrets
const ai = genkit({
  plugins: [
    googleAI({ apiKey: process.env.GOOGLE_GENAI_API_KEY })
  ],
  model: "googleai/gemini-2.0-flash",
});

export const getTaskPrioritization = onCall({
  cors: true,
  invoker: "public",
  // This line grants the function permission to read the key you set in terminal
  secrets: ["GOOGLE_GENAI_API_KEY"]
}, async (request) => {
  try {
    const { currentTasks, currentDateTime } = request.data;

    // Direct instructions to Gemini to process the tasks
    const response = await ai.generate({
      prompt: `You are an AI Task Assistant. I have ${currentTasks.length} tasks for a student.
               Tasks: ${JSON.stringify(currentTasks)}
               Current Time: ${currentDateTime}

               Analyze every task. Return a JSON object with the key 'recommendedPriorities'.
               For each task, provide 'taskId', a 'recommendedPriority' (Critical, High, Medium, or Low),
               and a 'reasoning' explaining the choice.`,
      output: {
        format: 'json',
        schema: z.object({
          recommendedPriorities: z.array(z.object({
            taskId: z.string(),
            recommendedPriority: z.string(),
            reasoning: z.string(),
          }))
        })
      }
    });

    // This returns the data back to your Flutter app
    return response.output;

  } catch (error) {
    // This logs the error in your Firebase Console if something goes wrong
    console.error("AI Error:", error);
    return {
      recommendedPriorities: [],
      error: error instanceof Error ? error.message : String(error)
    };
  }
});