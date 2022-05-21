document.addEventListener('DOMContentLoaded', function () {
  if(document.querySelectorAll('#twofa-checkbox').length) {
    document.getElementById('twofa-checkbox').addEventListener('change', function() {
      document.getElementById('twofa-note').classList.toggle('hide');
      document.getElementById('twofa-note-blank').classList.toggle('hide');
    })
  }
}, false);
