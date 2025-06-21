const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall} = require("firebase-functions/v2/https");
const {HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

// Función programada que se ejecuta viernes, sábado y domingo a las 23:00
exports.enviarNotificacionProgramada = onSchedule({
  schedule: "30 22 * * 5", // Cron: 22:12 solo viernes
  timeZone: "Europe/Madrid", // Zona horaria de España
}, async (event) => {
  console.log("⏰ Ejecutando notificación programada...");

  try {
    const db = getFirestore();
    const messaging = getMessaging();

    // Obtener todos los tokens de dispositivos registrados
    const tokensDoc = await db.collection("app_settings")
        .doc("device_tokens").get();

    if (!tokensDoc.exists) {
      console.log("❌ No hay tokens registrados");
      return;
    }

    const tokens = tokensDoc.data().tokens || [];

    if (tokens.length === 0) {
      console.log("❌ Lista de tokens vacía");
      return;
    }

    // Mensaje de la notificación
    const message = {
      notification: {
        title: "¡Es hora de recordar! 📱",
        body: "Captura tus momentos especiales del día",
        icon: "default",
      },
      data: {
        type: "scheduled_reminder",
        timestamp: new Date().toISOString(),
      },
    };

    // Enviar notificación a todos los dispositivos
    const responses = await messaging.sendEachForMulticast({
      tokens: tokens,
      ...message,
    });

    console.log(`✅ Notificaciones enviadas: ` +
      `${responses.successCount}/${tokens.length}`);

    // Limpiar tokens inválidos
    if (responses.failureCount > 0) {
      const validTokens = [];
      responses.responses.forEach((resp, idx) => {
        if (resp.success) {
          validTokens.push(tokens[idx]);
        } else {
          console.log(`❌ Token inválido removido: ${tokens[idx]}`);
        }
      });

      // Actualizar la lista con solo tokens válidos
      await db.collection("app_settings").doc("device_tokens").set({
        tokens: validTokens,
        lastUpdated: new Date(),
      });
    }
  } catch (error) {
    console.error("❌ Error enviando notificaciones:", error);
  }
});

// Función programada que se ejecuta viernes, sábado y domingo a las 23:00
exports.enviarNotificacionNocturna = onSchedule({
  schedule: "0 23 * * 5,6,0", // Cron: 23:00 viernes, sábado y domingo
  timeZone: "Europe/Madrid", // Zona horaria de España
}, async (event) => {
  console.log("⏰ Ejecutando notificación programada...");

  try {
    const db = getFirestore();
    const messaging = getMessaging();

    // Obtener todos los tokens de dispositivos registrados
    const tokensDoc = await db.collection("app_settings")
        .doc("device_tokens").get();

    if (!tokensDoc.exists) {
      console.log("❌ No hay tokens registrados");
      return;
    }

    const tokens = tokensDoc.data().tokens || [];

    if (tokens.length === 0) {
      console.log("❌ Lista de tokens vacía");
      return;
    }

    // Mensaje de la notificación
    const message = {
      notification: {
        title: "¡Es hora de recordar! 📱",
        body: "Captura tus momentos especiales del día",
        icon: "default",
      },
      data: {
        type: "scheduled_reminder",
        timestamp: new Date().toISOString(),
      },
    };

    // Enviar notificación a todos los dispositivos
    const responses = await messaging.sendEachForMulticast({
      tokens: tokens,
      ...message,
    });

    console.log(`✅ Notificaciones enviadas: ` +
      `${responses.successCount}/${tokens.length}`);

    // Limpiar tokens inválidos
    if (responses.failureCount > 0) {
      const validTokens = [];
      responses.responses.forEach((resp, idx) => {
        if (resp.success) {
          validTokens.push(tokens[idx]);
        } else {
          console.log(`❌ Token inválido removido: ${tokens[idx]}`);
        }
      });

      // Actualizar la lista con solo tokens válidos
      await db.collection("app_settings").doc("device_tokens").set({
        tokens: validTokens,
        lastUpdated: new Date(),
      });
    }
  } catch (error) {
    console.error("❌ Error enviando notificaciones:", error);
  }
});

// Función para registrar tokens de dispositivos
exports.registrarToken = onCall(async (request) => {
  const {token} = request.data;

  if (!token) {
    throw new HttpsError("invalid-argument", "Token es requerido");
  }

  try {
    const db = getFirestore();
    const tokensRef = db.collection("app_settings").doc("device_tokens");

    // Obtener tokens existentes
    const doc = await tokensRef.get();
    let tokens = [];

    if (doc.exists) {
      tokens = doc.data().tokens || [];
    }

    // Añadir token si no existe
    if (!tokens.includes(token)) {
      tokens.push(token);

      await tokensRef.set({
        tokens: tokens,
        lastUpdated: new Date(),
      });

      console.log(`✅ Token registrado: ${token}`);
    }

    return {success: true, message: "Token registrado correctamente"};
  } catch (error) {
    console.error("❌ Error registrando token:", error);
    throw new HttpsError("internal", "Error interno del servidor");
  }
});
