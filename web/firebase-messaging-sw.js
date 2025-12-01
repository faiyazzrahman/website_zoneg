importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCHp48tbETVXBw71JNvLEdBKnjshLWXphI",
  authDomain: "zoneguard-e943a.firebaseapp.com",
  projectId: "zoneguard-e943a",
  storageBucket: "zoneguard-e943a.firebasestorage.app",
  messagingSenderId: "882643778506",
  appId: "1:882643778506:web:6d4b754ad0c4ec8dcb6d33"
});

const messaging = firebase.messaging();
