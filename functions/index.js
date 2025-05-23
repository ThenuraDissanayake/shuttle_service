const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore } = require("firebase-admin/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// Cloud function that runs daily at 8:00 PM (20:00)
exports.resetDailyBookingCounts = onSchedule(
  { schedule: "every day 20:00", timeZone: "Asia/Colombo" },
  async (event) => {
    try {
      const db = getFirestore();

      // Get all documents from the driver_bookings collection
      const snapshot = await db.collection("driver_bookings").get();

      // Batch operations for efficiency
      const batch = db.batch();

      snapshot.forEach((doc) => {
        batch.update(doc.ref, {
          bookings_for_morning: 0,
          bookings_for_evening: 0,
        });
      });

      // Commit the batch operation
      await batch.commit();

      console.log(
        `Successfully reset booking counts for ${snapshot.size} drivers at ${new Date().toISOString()}`
      );
    } catch (error) {
      console.error("Error resetting booking counts:", error);
    }
  }
);