"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getTaskPrioritization = void 0;
const https_1 = require("firebase-functions/v2/https");
const genkit_1 = require("genkit");
const google_genai_1 = require("@genkit-ai/google-genai");
// Initialize Genkit with the API Key from your Cloud Secrets
const ai = (0, genkit_1.genkit)({
    plugins: [
        (0, google_genai_1.googleAI)({ apiKey: process.env.GOOGLE_GENAI_API_KEY })
    ],
    model: "googleai/gemini-2.0-flash",
});
exports.getTaskPrioritization = (0, https_1.onCall)({
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
                schema: genkit_1.z.object({
                    recommendedPriorities: genkit_1.z.array(genkit_1.z.object({
                        taskId: genkit_1.z.string(),
                        recommendedPriority: genkit_1.z.string(),
                        reasoning: genkit_1.z.string(),
                    }))
                })
            }
        });
        // This returns the data back to your Flutter app
        return response.output;
    }
    catch (error) {
        // This logs the error in your Firebase Console if something goes wrong
        console.error("AI Error:", error);
        return {
            recommendedPriorities: [],
            error: error instanceof Error ? error.message : String(error)
        };
    }
});
//# sourceMappingURL=index.js.map