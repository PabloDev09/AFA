import { onSchedule }           from 'firebase-functions/v2/scheduler';
import { onDocumentUpdated }    from 'firebase-functions/v2/firestore';
import { initializeApp }        from 'firebase-admin/app';
import { getMessaging }         from 'firebase-admin/messaging';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import nodemailer               from 'nodemailer';
import dotenv                   from 'dotenv';

dotenv.config();
initializeApp();

// FIRESTORE & FCM
const messaging = getMessaging();
const db = getFirestore();

// SMTP transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
});

// HTML email container template
function renderEmailContainer(title, description) {
  return `
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${title}</title>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;600&display=swap" rel="stylesheet" />
    <style>
      body { margin:0; padding:0; font-family:'Montserrat', Arial, sans-serif; background:#f9faff; color:#003366; }
      .container { max-width:600px; margin:40px auto; background:#fff; border:1px solid #cce0ff; border-radius:12px; box-shadow:0 4px 12px rgba(0,0,0,0.05); overflow:hidden; }
      .logo-wrap { background:#f5faff; padding:16px; text-align:center; }
      .logo { max-height:60px; }
      .header { background:#003366; color:#fff; padding:20px; text-align:center; font-size:24px; font-weight:600; }
      .content { padding:24px; font-size:16px; line-height:1.6; }
      .button { display:inline-block; background:#0055a5; color:#fff; text-decoration:none; padding:12px 24px; border-radius:4px; font-weight:600; margin-top:16px; }
      .footer { background:#e6ecf8; color:#003366; text-align:center; font-size:12px; padding:16px; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="logo-wrap">
        <img src="https://afa-jandula.web.app/assets/images/logo.png" alt="Logo AFA" class="logo" />
      </div>
      <div class="header">${title}</div>
      <div class="content">
        <center>${description}</center>
      </div>
      <div class="footer">© AFA 2025. Todos los derechos reservados.</div>
    </div>
  </body>
</html>
  `;
}

function isToday(ts) {
  const d = ts.toDate(), now = new Date();
  return d.getDate()===now.getDate() && d.getMonth()===now.getMonth() && d.getFullYear()===now.getFullYear();
}
function formatDate(ts) {
  const d = ts.toDate();
  return `${String(d.getDate()).padStart(2,'0')}/${String(d.getMonth()+1).padStart(2,'0')}/${d.getFullYear()}`;
}

// 1) Push & Email notifications on route updates
export const notificarPushEstadoRecogida = onDocumentUpdated(
  { region:'europe-southwest1', document:'ruta/{rutaId}' },
  async event => {
    const before = event.data.before.data(), after = event.data.after.data(), rutaId = event.data.after.id;
    const fcmToken = after.fcmToken, email = after.mail;
    if (!fcmToken && !email) return console.warn('No FCM token or email for ruta', rutaId);

    const nombre = `${after.name} ${after.surnames}`, direccion = after.address;
    const pushMessages = [], emailMessages = [];

    // helpers to queue
    function queue(title, body) {
      if (fcmToken) pushMessages.push({ token:fcmToken, webpush:{notification:{title,body}}, data:{rutaId,type:title} });
      if (email) {
        let description = `<p>${body}</p>`;
        // añadir enlace en notificaciones de recogida
        if (title.includes('Recogida') || title.includes('Ruta') || title.includes('Conductor')) {
          description += `<p>Recuerda que puedes ver el estado de tu recogida en la app.</p>`;
          description += `<p><a href="https://afa-jandula.web.app/home" class="button">Ver detalles</a></p>`;
        }
        const html = renderEmailContainer(title, description);
        emailMessages.push({ to:email, subject:title, html });
      }
    }

    // events
    if((!before.createdAt||!isToday(before.createdAt)) && after.createdAt && isToday(after.createdAt))
      queue('[AFA] 🚗 Ruta iniciada', `Ruta del ${formatDate(after.createdAt)} ha comenzado.`);
    if(!before.isBeingPicking && after.isBeingPicking)
      queue('[AFA] 🚗 Recogida iniciada', `Hola ${nombre}, el conductor ha iniciado tu recogida en: ${direccion}.`);
    if(before.isBeingPicking && !after.isBeingPicking)
      queue('[AFA] ❌ Recogida cancelada', `Hola ${nombre}, el conductor canceló tu recogida en: ${direccion}.`);
    if(!before.isNear && after.isNear)
      queue('[AFA] 📍 Conductor cerca', `Hola ${nombre}, conductor cerca de: ${direccion}.`);

    if(pushMessages.length) await Promise.all(pushMessages.map(m=>messaging.send(m)));
    if(emailMessages.length) await Promise.all(emailMessages.map(m=>transporter.sendMail({ from:process.env.SMTP_USER, ...m })));
  }
);

export const borrarRutasAntiguas = onSchedule(
  { region: 'europe-west1', schedule: '0 0 * * *', timeZone: 'Europe/Madrid' },
  async () => {
    const hoyTs = Timestamp.now();
    
    const snap = await db.collection('ruta')
                         .where('createdAt', '<', hoyTs)
                         .get();

    if (!snap.empty) {
      const batch = db.batch();
      snap.docs.forEach(d => batch.delete(d.ref));
      await batch.commit();
      console.log(`Deleted ${snap.size} old rutas`);
    }

    snap = await db.collection('ruta_conductor')
                         .where('createdAt', '<', hoyTs)
                         .get();

    if (!snap.empty) {
      const batch = db.batch();
      snap.docs.forEach(d => batch.delete(d.ref));
      await batch.commit();
      console.log(`Deleted ${snap.size} old rutas conductor`);
    }
  }
);

export const borrarCancelacionRutasAntiguas = onSchedule(
  { region: 'europe-west1', schedule: '0 0 * * *', timeZone: 'Europe/Madrid' },
  async () => {

    const hoyTs = Timestamp.now();

    const snap = await db.collection('rutacancelada')
                         .where('cancelDate', '<', hoyTs)
                         .get();

    if (!snap.empty) {
      const batch = db.batch();
      snap.docs.forEach(d => batch.delete(d.ref));
      await batch.commit();
      console.log(`Deleted ${snap.size} cancelled rutas`);
    }
  }
);

// 4) Notify once on cancellation record creation
export const notificarCancelacionRuta = onDocumentUpdated(
  { region:'europe-southwest1', document:'rutacancelada/{rutaCanceladaId}' },
  async event => {
    const before = event.data.before.data(), after = event.data.after.data();
    if(before.cancelDate==null && after.cancelDate) {
      const fecha = formatDate(after.cancelDate), username = after.username;
      const snap = await db.collection('usuarios').where('username','==',username).limit(1).get();
      if(!snap.empty){
        const userEmail = snap.docs[0].data().mail;
        const title = '❌ Recogida cancelada';
        const desc = `Su ruta programada para el ${fecha} ha sido cancelada correctamente.`;
        await transporter.sendMail({
          from:process.env.SMTP_USER,
          to:userEmail,
          subject:title,
          html:renderEmailContainer(title, `<p>${desc}</p><p><a href="https://afa-jandula.web.app/home" class="button">Ver detalles</a></p>`)
        });
        console.log(`Cancel email sent to ${userEmail}`);
      }
    }
  }
);

