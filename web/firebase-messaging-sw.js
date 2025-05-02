importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp
({
  apiKey: 'AIzaSyDuCpxL6umN1yYbqUVtKkYp_fgGas6ZRM4',
  appId: '1:253008576813:web:50023b3bdfe2027c3553a4',
  messagingSenderId: '253008576813',
  projectId: 'afa-jandula',
  authDomain: 'afa-jandula.firebaseapp.com',
  databaseURL: 'https://afa-jandula-default-rtdb.europe-west1.firebasedatabase.app',
  storageBucket: 'afa-jandula.firebasestorage.app',
  measurementId: 'G-7BQ9J990JB',
});

const messaging = firebase.messaging();
