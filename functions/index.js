const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// 🚀 AUTOMATIC FIRESTORE MULTI-ALERT TRIGGER (v2 Syntax)
exports.ontaskcreatedsendalert = onDocumentCreated("tasks/{taskId}", async (event) => {
    const taskData = event.data.data();
    if (!taskData) return null;

    const taskName = taskData.taskName;
    const userId = taskData.userId;
    const endDateStr = taskData.endDate; // ISO8601 String from Flutter
    const taskId = event.params.taskId;

    if (!endDateStr) return null;
    const dueDate = new Date(endDateStr);

    // 📋 Define your 3 required target notification intervals (in minutes)
    const reminderConfigs = [
        { label: "2 days", minutesBefore: 2 * 24 * 60 }, // 2880 minutes
        { label: "1 day", minutesBefore: 1 * 24 * 60 },  // 1440 minutes
        { label: "1 hour", minutesBefore: 60 }           // 60 minutes
    ];

    // Loop through each requested milestone alert configuration window
    for (const config of reminderConfigs) {
        const alertTime = new Date(dueDate.getTime() - (config.minutesBefore * 60 * 1000));
        const now = new Date();
        const delayMs = alertTime.getTime() - now.getTime();

        // Skip scheduling this specific alert milestone if its execution time has already passed
        if (delayMs <= 0) {
            console.log(`[${config.label}] window for "${taskName}" has already passed. Skipping milestone.`);
            continue;
        }

        // Trigger an execution timeout block for each independent milestone event wrapper
        setTimeout(async () => {
            try {
                // 🔒 SAFETY SYSTEM CHECK: Verify the user hasn't logged out since this task was created
                const userDoc = await admin.firestore().collection("users").doc(userId).get();
                if (!userDoc.exists) return;

                const fcmToken = userDoc.data().fcmToken;
                // If token is missing/deleted because they logged out, stop execution immediately!
                if (!fcmToken) {
                    console.log(`🚫 Notification blocked: User ${userId} has logged out or cleared their token.`);
                    return;
                }

                // Compile and push the cloud message payload packet
                const message = {
                    notification: {
                        title: "Task Reminder!",
                        body: `"${taskName}" is due in ${config.label}. Keep it up!`
                    },
                    data: {
                        taskId: taskId,
                        click_action: "FLUTTER_NOTIFICATION_CLICK"
                    },
                    token: fcmToken
                };

                const response = await admin.messaging().send(message);
                console.log(`Successfully delivered [${config.label}] alert for ${taskName}:`, response);
            } catch (error) {
                console.error(`Error processing scheduled [${config.label}] window notification:`, error);
            }
        }, delayMs);

        console.log(`⏰ Scheduled [${config.label}] warning alert for "${taskName}" in ${delayMs / 1000} seconds.`);
    }

    return null;
});