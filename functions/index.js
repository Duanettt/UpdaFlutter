const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineString} = require("firebase-functions/params");
const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

const gnewsApiKey = defineString("GNEWS_API_KEY");

exports.testNotifications = onRequest(async (req, res) => {
  console.log("📢 Manual test triggered");

  try {
    const db = admin.firestore();
    const messaging = admin.messaging();

    const tokensSnapshot = await db.collection("device_tokens").get();

    if (tokensSnapshot.empty) {
      console.log("❌ No devices registered");
      res.send("No devices registered in Firestore");
      return;
    }

    console.log(`✅ Found ${tokensSnapshot.size} device(s)`);

    const firstDoc = tokensSnapshot.docs[0];
    const data = firstDoc.data();
    const discover = data.discover || [];

    console.log(`Device has ${discover.length} topic(s):`, discover);

    if (discover.length === 0) {
      res.send("Device has no topics subscribed");
      return;
    }

    const firstTopic = discover[0];
    const message = {
      notification: {
        title: `TEST: ${firstTopic.name}`,
        body: "This is a test notification from your Cloud Function!",
      },
      data: {
        topicId: firstTopic.id.toString(),
        topicName: firstTopic.name,
      },
      token: data.token,
    };

    console.log("📤 Sending test notification...");
    const result = await messaging.send(message);
    console.log("✅ Notification sent! Message ID:", result);

    res.send(`Success! Notification sent. Message ID: ${result}`);
  } catch (error) {
    console.error("❌ Error:", error);
    res.status(500).send("Error: " + error.message);
  }
});

exports.checkNewArticles = onSchedule(
    "every 1 hour",
    async (event) => {
      console.log("🔍 Starting article check...");

      try {
        const db = admin.firestore();
        const messaging = admin.messaging();

        const tokensSnapshot = await db.collection("device_tokens").get();

        if (tokensSnapshot.empty) {
          console.log("No devices registered");
          return null;
        }

        const topicSubscriptions = {};

        tokensSnapshot.forEach((doc) => {
          const data = doc.data();
          const token = data.token;
          const discover = data.discover || [];

          discover.forEach((topic) => {
            const topicKey = topic.name.toLowerCase().trim();

            if (!topicSubscriptions[topicKey]) {
              topicSubscriptions[topicKey] = {
                name: topic.name,
                tokens: [],
              };
            }
            topicSubscriptions[topicKey].tokens.push(token);
          });
        });

        const topicCount = Object.keys(topicSubscriptions).length;
        console.log(`Found ${topicCount} unique topics`);

        const apiKey = gnewsApiKey.value();
        const promises = [];

        for (const [topicKey, topicData] of
          Object.entries(topicSubscriptions)) {
          promises.push(
              checkTopicAndNotify(
                  topicKey,
                  topicData.name,
                  topicData.tokens,
                  apiKey,
                  messaging,
                  db,
              ),
          );
        }

        await Promise.all(promises);
        console.log("✅ Article check complete");

        return null;
      } catch (error) {
        console.error("❌ Error in checkNewArticles:", error);
        return null;
      }
    },
);

/**
 * Check topic for new articles and send notifications
 * @param {string} topicKey
 * @param {string} topicName
 * @param {Array} tokens
 * @param {string} apiKey
 * @param {object} messaging
 * @param {object} db
 * @return {Promise<void>}
 */
async function checkTopicAndNotify(
    topicKey,
    topicName,
    tokens,
    apiKey,
    messaging,
    db,
) {
  try {
    console.log(`🔍 Checking topic: ${topicName}`);

    const topicDocRef = db
        .collection("last_notifications")
        .doc(topicKey);
    const topicDoc = await topicDocRef.get();
    const lastData = topicDoc.exists ? topicDoc.data() : null;
    const lastArticleUrl = lastData ? lastData.lastArticleUrl : null;

    const cleanTopic = topicName.replace(/&/g, "AND")
        .replace(/[^\w\s]/g, " ")
        .trim();

    const encodedTopic = encodeURIComponent(`"${cleanTopic}"`);
    const url = `https://gnews.io/api/v4/search?q=${encodedTopic}` +
      `&lang=en&max=5&sortby=publishedAt&apikey=${apiKey}`;

    const response = await fetch(url);

    if (!response.ok) {
      console.error(
          `API error for topic ${topicName}: ${response.status}`,
      );
      return;
    }

    const data = await response.json();
    const articles = data.articles || [];

    if (articles.length === 0) {
      console.log(`No articles found for topic: ${topicName}`);
      return;
    }

    const latestArticle = articles[0];

    const titleLower = latestArticle.title.toLowerCase();
    const topicLower = topicName.toLowerCase();
    const topicWords = topicLower.split(/\s+/);

    const hasTopicMatch = topicWords.some((word) =>
      word.length > 2 && titleLower.includes(word),
    );

    if (!hasTopicMatch) {
      console.log(`❌ Article doesn't match topic ${topicName}, skipping`);
      return;
    }

    if (latestArticle.url === lastArticleUrl) {
      console.log(`No new articles for ${topicName}`);
      return;
    }

    console.log(
        `🆕 New article for ${topicName}: ${latestArticle.title}`,
    );

    const messages = tokens.map((token) => ({
      notification: {
        title: topicName,
        body: latestArticle.title,
      },
      data: {
        topicId: topicKey,
        topicName: topicName,
        articleUrl: latestArticle.url,
      },
      token: token,
    }));

    const result = await messaging.sendEach(messages);
    console.log(
        `✅ Sent ${result.successCount} notifications for ${topicName}`,
    );

    if (result.failureCount > 0) {
      console.log(`⚠️ ${result.failureCount} notifications failed`);

      const tokensToDelete = [];
      result.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          const errorMsg = resp.error ? resp.error.message : "Unknown error";
          console.log(`Failed token ${idx}: ${errorMsg} (${errorCode})`);

          if (errorCode === "messaging/registration-token-not-registered" ||
              errorCode === "messaging/invalid-registration-token") {
            tokensToDelete.push(tokens[idx]);
          }
        }
      });

      if (tokensToDelete.length > 0) {
        const batch = db.batch();
        for (const invalidToken of tokensToDelete) {
          batch.delete(db.collection("device_tokens").doc(invalidToken));
        }
        await batch.commit();
        console.log(`🗑️ Deleted ${tokensToDelete.length} invalid tokens`);
      }
    }

    await topicDocRef.set({
      topicName: topicName,
      lastArticleUrl: latestArticle.url,
      lastArticleTitle: latestArticle.title,
      lastNotificationTime: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error(`❌ Error checking topic ${topicName}:`, error);
  }
}