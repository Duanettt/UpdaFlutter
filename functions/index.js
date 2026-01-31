const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineString} = require("firebase-functions/params");
const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

// Define the API key as a secret parameter
const newsmeshApiKey = defineString("NEWSMESH_API_KEY");

exports.testNotifications = onRequest(async (req, res) => {
  console.log("🔔 Manual test triggered");

  try {
    const db = admin.firestore();
    const messaging = admin.messaging();

    // Get all device tokens
    const tokensSnapshot = await db.collection("device_tokens").get();

    if (tokensSnapshot.empty) {
      console.log("❌ No devices registered");
      res.send("No devices registered in Firestore");
      return;
    }

    console.log(`✅ Found ${tokensSnapshot.size} device(s)`);

    // Get first device's topics
    const firstDoc = tokensSnapshot.docs[0];
    const data = firstDoc.data();
    const topics = data.topics || [];

    console.log(`Device has ${topics.length} topic(s):`, topics);

    if (topics.length === 0) {
      res.send("Device has no topics subscribed");
      return;
    }

    // Send a test notification for the first topic
    const firstTopic = topics[0];
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

/**
 * Scheduled function that checks for new articles every hour
 * and sends notifications to subscribed devices
 */
exports.checkNewArticles = onSchedule("every 1 hours", async (event) => {
  console.log("Starting article check...");

  try {
    const db = admin.firestore();
    const messaging = admin.messaging();

    // Get all device tokens and their subscribed topics
    const tokensSnapshot = await db.collection("device_tokens").get();

    if (tokensSnapshot.empty) {
      console.log("No devices registered");
      return null;
    }

    // Build a map of topicId -> array of device tokens
    const topicSubscriptions = {};

    tokensSnapshot.forEach((doc) => {
      const data = doc.data();
      const token = data.token;
      const topics = data.topics || [];

      topics.forEach((topic) => {
        if (!topicSubscriptions[topic.id]) {
          topicSubscriptions[topic.id] = {
            name: topic.name,
            tokens: [],
          };
        }
        topicSubscriptions[topic.id].tokens.push(token);
      });
    });

    const topicCount = Object.keys(topicSubscriptions).length;
    console.log(`Found ${topicCount} unique topics`);

    // For each topic, check for new articles
    const apiKey = newsmeshApiKey.value();
    const promises = [];

    for (const [topicId, topicData] of
      Object.entries(topicSubscriptions)) {
      promises.push(
          checkTopicAndNotify(
              topicId,
              topicData.name,
              topicData.tokens,
              apiKey,
              messaging,
          ),
      );
    }

    await Promise.all(promises);
    console.log("Article check complete");

    return null;
  } catch (error) {
    console.error("Error in checkNewArticles:", error);
    return null;
  }
});

/**
 * Checks a topic for new articles and sends notifications
 * @param {string} topicId - The topic ID
 * @param {string} topicName - The topic name
 * @param {Array} tokens - Array of FCM tokens to notify
 * @param {string} apiKey - The newsmesh API key
 * @param {object} messaging - Firebase messaging instance
 * @return {Promise<void>}
 */
async function checkTopicAndNotify(
    topicId,
    topicName,
    tokens,
    apiKey,
    messaging,
) {
  try {
    console.log(`Checking topic: ${topicName}`);

    // Call newsmesh API
    const encodedTopic = encodeURIComponent(topicName);
    const url = `https://api.newsmesh.co/v1/search?apiKey=${apiKey}` +
      `&q=${encodedTopic}&limit=5&sortBy=date_descending`;
    const response = await fetch(url);

    if (!response.ok) {
      console.error(
          `API error for topic ${topicName}: ${response.status}`,
      );
      return;
    }

    const data = await response.json();
    const articles = data.data || [];

    if (articles.length === 0) {
      console.log(`No articles found for topic: ${topicName}`);
      return;
    }

    // Get the most recent article
    const latestArticle = articles[0];
    const articleDate = new Date(latestArticle.published_date);
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

    // Only notify if the article is less than 1 hour old
    if (articleDate > oneHourAgo) {
      console.log(
          `New article found for ${topicName}: ${latestArticle.title}`,
      );

      // Send notification to all subscribed devices
      const message = {
        notification: {
          title: `New: ${topicName}`,
          body: latestArticle.title,
        },
        data: {
          topicId: topicId.toString(),
          topicName: topicName,
          articleUrl: latestArticle.link,
        },
        tokens: tokens,
      };

      const result = await messaging.sendMulticast(message);
      console.log(
          `Sent ${result.successCount} notifications for ${topicName}`,
      );

      if (result.failureCount > 0) {
        console.log(`${result.failureCount} notifications failed`);
      }
    } else {
      console.log(
          `Latest article for ${topicName} is older than 1 hour, ` +
          `skipping`,
      );
    }
  } catch (error) {
    console.error(`Error checking topic ${topicName}:`, error);
  }
}
exports.testNotifications = onRequest(async (req, res) => {
  console.log("🔔 Manual test triggered");

  try {
    const db = admin.firestore();
    const messaging = admin.messaging();

    // Get all device tokens
    const tokensSnapshot = await db.collection("device_tokens").get();

    if (tokensSnapshot.empty) {
      console.log("❌ No devices registered");
      res.send("No devices registered in Firestore");
      return;
    }

    console.log(`✅ Found ${tokensSnapshot.size} device(s)`);

    // Get first device's topics
    const firstDoc = tokensSnapshot.docs[0];
    const data = firstDoc.data();
    const topics = data.topics || [];

    console.log(`Device has ${topics.length} topic(s):`, topics);

    if (topics.length === 0) {
      res.send("Device has no topics subscribed");
      return;
    }

    // Send a test notification for the first topic
    const firstTopic = topics[0];
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
