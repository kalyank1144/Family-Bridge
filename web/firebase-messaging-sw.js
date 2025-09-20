/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

try {
  if (!firebase.apps.length) {
    firebase.initializeApp({
      apiKey: self.FIREBASE_API_KEY,
      authDomain: self.FIREBASE_AUTH_DOMAIN,
      projectId: self.FIREBASE_PROJECT_ID,
      messagingSenderId: self.FIREBASE_SENDER_ID,
      appId: self.FIREBASE_APP_ID,
    });
  }
  const messaging = firebase.messaging();
  messaging.onBackgroundMessage((payload) => {
    const title = payload.notification?.title || 'FamilyBridge';
    const body = payload.notification?.body || '';
    const options = { body, icon: '/icons/Icon-192.png', data: payload.data };
    self.registration.showNotification(title, options);
  });
} catch (e) {
}
