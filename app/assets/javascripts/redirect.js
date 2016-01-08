if (window.location.pathname === '/queue_redirect') {
  function redirectToQueue() {
    window.location='https://help.epicodus.com';
  }
  setTimeout('redirectToQueue()', 5000);
}
