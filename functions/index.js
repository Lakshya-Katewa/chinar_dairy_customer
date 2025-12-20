const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Sends a notification to a specific user.
 * @param {string} customerId The ID of the customer to notify.
 * @param {string} title The title of the notification.
 * @param {string} body The body text of the notification.
 */
async function sendNotification(customerId, title, body) {
  if (!customerId) {
    console.error("No customerId provided for notification.");
    return;
  }

  // Get the customer's FCM token from Firestore
  const userDoc = await admin.firestore().collection("customers").doc(customerId).get();
  if (!userDoc.exists) {
    console.error(`Customer document not found for ID: ${customerId}`);
    return;
  }
  const fcmToken = userDoc.data().fcmToken;

  if (fcmToken) {
    const payload = {
      notification: {
        title: title,
        body: body,
      },
      token: fcmToken,
    };
    try {
      await admin.messaging().send(payload);
      console.log(`Notification sent successfully to customer: ${customerId}`);
    } catch (error) {
      console.error(`Error sending notification to customer ${customerId}:`, error);
      // Optional: Clean up invalid tokens
      if (error.code === 'messaging/registration-token-not-registered') {
        await userDoc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
      }
    }
  } else {
    console.log(`No FCM token found for customer: ${customerId}`);
  }
}

// 1. Trigger for when a new order is created (v2 syntax)
exports.onOrderCreated = onDocumentCreated("orders/{orderId}", async (event) => {
  const snap = event.data;
  if (!snap) {
    console.log("No data associated with the event");
    return;
  }
  const order = snap.data();
  const title = "Order Placed Successfully! ✅";
  const body = `Your order #${snap.id.substring(0, 6)} for ₹${order.totalAmount.toFixed(2)} has been placed.`;
  return sendNotification(order.customerId, title, body);
});

// 2. Trigger for when an order's status is updated to 'delivered' (v2 syntax)
exports.onOrderUpdated = onDocumentUpdated("orders/{orderId}", async (event) => {
  const newValue = event.data.after.data();
  const previousValue = event.data.before.data();
  const orderId = event.params.orderId;

  // Send notification only when status changes to 'delivered'
  if (newValue.status !== previousValue.status && newValue.status === "delivered") {
    const title = "Order Delivered! 🚚";
    const body = `Your order #${orderId.substring(0, 6)} has been delivered successfully.`;
    return sendNotification(newValue.customerId, title, body);
  }
  return null;
});

// 3. Trigger for when a new subscription is created (v2 syntax)
exports.onSubscriptionCreated = onDocumentCreated("subscriptions/{subId}", async (event) => {
  const snap = event.data;
  if (!snap) {
    console.log("No data associated with the event");
    return;
  }
  const sub = snap.data();
  const title = "Subscription Activated! 🐮";
  const body = `Your ${sub.type} subscription for ${sub.productName} has been created successfully.`;
  return sendNotification(sub.customerId, title, body);
});

// 4. Trigger for when a subscription is cancelled (v2 syntax)
exports.onSubscriptionUpdated = onDocumentUpdated("subscriptions/{subId}", async (event) => {
  const newValue = event.data.after.data();
  const previousValue = event.data.before.data();

  // Send notification only when status changes to 'cancelled'
  if (newValue.status !== previousValue.status && newValue.status === "cancelled") {
    const title = "Subscription Cancelled";
    const body = `Your subscription for ${newValue.productName} has been cancelled. Any remaining balance has been refunded to your wallet.`;
    return sendNotification(newValue.customerId, title, body);
  }
  return null;
});













