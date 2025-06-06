const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Función que se ejecuta diariamente a las 23:00
exports.checkDailyProximity = functions.pubsub
  .schedule('0 23 * * *')
  .timeZone('Europe/Madrid')
  .onRun(async (context) => {
    const db = admin.firestore();
    const messaging = admin.messaging();
    
    try {
      // Obtener todos los encuentros del día actual
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      
      const encountersSnapshot = await db.collection('encounters')
        .where('timestamp', '>=', today)
        .where('timestamp', '<', tomorrow)
        .get();
      
      // Agrupar encuentros por pareja
      const coupleEncounters = {};
      
      encountersSnapshot.forEach(doc => {
        const data = doc.data();
        const user1 = data.user1_id;
        const user2 = data.user2_id;
        const coupleKey = [user1, user2].sort().join('_');
        
        if (!coupleEncounters[coupleKey]) {
          coupleEncounters[coupleKey] = [];
        }
        coupleEncounters[coupleKey].push(data);
      });
      
      // Verificar qué parejas estuvieron juntas y enviar notificaciones
      for (const [coupleKey, encounters] of Object.entries(coupleEncounters)) {
        if (encounters.length > 0) {
          const [user1Id, user2Id] = coupleKey.split('_');
          
          // Verificar que son pareja en la base de datos
          const coupleQuery = await db.collection('parejas')
            .where('id_user1', '==', parseInt(user1Id))
            .where('id_user2', '==', parseInt(user2Id))
            .get();
          
          const coupleQuery2 = await db.collection('parejas')
            .where('id_user1', '==', parseInt(user2Id))
            .where('id_user2', '==', parseInt(user1Id))
            .get();
          
          if (!coupleQuery.empty || !coupleQuery2.empty) {
            // Obtener tokens FCM de ambos usuarios
            const user1Doc = await db.collection('usuarios')
              .where('id_usuario', '==', parseInt(user1Id))
              .get();
            
            const user2Doc = await db.collection('usuarios')
              .where('id_usuario', '==', parseInt(user2Id))
              .get();
            
            if (!user1Doc.empty && !user2Doc.empty) {
              const user1Data = user1Doc.docs[0].data();
              const user2Data = user2Doc.docs[0].data();
              
              // Enviar notificaciones a ambos usuarios
              const message1 = {
                token: user1Data.fcm_token,
                notification: {
                  title: '💕 Momento especial detectado',
                  body: `Has estado con ${user2Data.nombre} hoy. ¿Quieres crear un recuerdo en el calendario?`
                },
                data: {
                  type: 'proximity_detected',
                  partner_id: user2Id,
                  partner_name: user2Data.nombre,
                  encounter_count: encounters.length.toString()
                }
              };
              
              const message2 = {
                token: user2Data.fcm_token,
                notification: {
                  title: '💕 Momento especial detectado',
                  body: `Has estado con ${user1Data.nombre} hoy. ¿Quieres crear un recuerdo en el calendario?`
                },
                data: {
                  type: 'proximity_detected',
                  partner_id: user1Id,
                  partner_name: user1Data.nombre,
                  encounter_count: encounters.length.toString()
                }
              };
              
              // Enviar notificaciones
              if (user1Data.fcm_token) {
                await messaging.send(message1);
              }
              if (user2Data.fcm_token) {
                await messaging.send(message2);
              }
            }
          }
        }
      }
      
      console.log('Proximity check completed successfully');
      return null;
    } catch (error) {
      console.error('Error in proximity check:', error);
      return null;
    }
  });