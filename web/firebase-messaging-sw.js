/* eslint-disable no-undef */
// FCM background handler for Flutter Web. Replace firebaseConfig with the same values as Firebase Console / lib/firebase_options.dart (web).
// Keep firebase-js version roughly aligned with your firebase_core package (see FlutterFire docs).

importScripts('https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCi-ITm_urwknZ4TRHSvFiEmrS3b7z9V5I',
  authDomain: 'renomada-b1951.firebaseapp.com',
  projectId: 'renomada-b1951',
  storageBucket: 'renomada-b1951.firebasestorage.app',
  messagingSenderId: '191949056172',
  appId: '1:191949056172:web:51853d9965c4733c79d709',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message', payload);
});
