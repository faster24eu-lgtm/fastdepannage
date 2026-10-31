(function () {
  var header = document.querySelector('.site-header');
  var menuBtn = document.querySelector('.menu-btn');
  if (menuBtn && header) {
    menuBtn.addEventListener('click', function () {
      var open = header.classList.toggle('open');
      menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
  }

  document.querySelectorAll('.dd > button').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var dd = btn.parentElement;
      var open = dd.classList.toggle('open');
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
  });
  document.addEventListener('click', function (e) {
    document.querySelectorAll('.dd.open').forEach(function (dd) {
      if (!dd.contains(e.target)) {
        dd.classList.remove('open');
        dd.querySelector('button').setAttribute('aria-expanded', 'false');
      }
    });
  });

  var y = document.getElementById('annee');
  if (y) y.textContent = new Date().getFullYear();
})();

// WhatsApp mockup: play the conversation when it scrolls into view
(function () {
  var chat = document.querySelector('.chat');
  if (!chat || !('IntersectionObserver' in window)) return;
  if (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var io = new IntersectionObserver(function (entries) {
    if (entries[0].isIntersecting) { chat.classList.add('armed', 'play'); io.disconnect(); }
  }, { threshold: 0.3 });
  io.observe(chat);
})();
