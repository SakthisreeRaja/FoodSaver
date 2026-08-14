// Payment services have been removed from this project
// Focus: Core donation, pickup, and volunteer management only
export {};

/**
 * Handle Stripe webhook for payment success
 */
export const handleStripeWebhook = functions.https.onRequest(
  async (req, res) => {
    const sig = req.headers["stripe-signature"] as string;
    const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET || "";

    if (!sig || !endpointSecret) {
      return res.status(400).send("Missing signature or endpoint secret");
    }

    let event;

    try {
      event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
    } catch (err: any) {
      console.error(`Webhook signature verification failed: ${err.message}`);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    try {
      if (event.type === "payment_intent.succeeded") {
        const paymentIntent = event.data.object;
        const { donationId, userId } = paymentIntent.metadata;

        // Save transaction record
        await db.collection("transactions").add({
          userId,
          donationId,
          paymentIntentId: paymentIntent.id,
          amount: paymentIntent.amount / 100,
          currency: paymentIntent.currency,
          status: "succeeded",
          createdAt: new Date(),
        });

        // Update donation with payment info
        const donationRef = db.collection("donations").doc(donationId);
        await donationRef.update({
          paymentStatus: "paid",
          paymentIntentId: paymentIntent.id,
          updatedAt: new Date(),
        });
      }

      res.json({ received: true });
    } catch (error) {
      console.error(`Webhook processing error: ${error}`);
      res.status(500).send("Internal server error");
    }
  }
);

/**
 * Get transaction history
 */
export const getTransactionHistory = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    try {
      const snapshot = await db
        .collection("transactions")
        .where("userId", "==", context.auth.uid)
        .orderBy("createdAt", "desc")
        .limit(50)
        .get();

      const transactions = snapshot.docs.map((doc) => doc.data());
      return { success: true, transactions };
    } catch (error) {
      console.error(`Error fetching transactions: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch transactions"
      );
    }
  }
);

/**
 * Refund payment
 */
export const refundPayment = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { paymentIntentId, reason } = data;

    if (!paymentIntentId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Payment Intent ID is required"
      );
    }

    try {
      const refund = await stripe.refunds.create({
        payment_intent: paymentIntentId,
        reason: reason || "requested_by_customer",
      });

      // Update transaction record
      await db
        .collection("transactions")
        .where("paymentIntentId", "==", paymentIntentId)
        .get()
        .then((snapshot) => {
          snapshot.docs.forEach((doc) => {
            doc.ref.update({ status: "refunded", refundId: refund.id });
          });
        });

      return {
        success: true,
        message: "Refund processed successfully",
        refundId: refund.id,
      };
    } catch (error) {
      console.error(`Error processing refund: ${error}`);
      throw new functions.https.HttpsError("internal", "Failed to process refund");
    }
  }
);
