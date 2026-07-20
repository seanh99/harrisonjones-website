// ============================================================
// Harrison Jones — shared site behavior
// ============================================================

document.addEventListener('DOMContentLoaded', () => {

  /* ---------- Header: line appears on scroll ---------- */
  const header = document.getElementById('siteHeader');
  function onScroll(){
    if (!header) return;
    header.classList.toggle('is-lined', window.scrollY > 8);
  }
  window.addEventListener('scroll', onScroll, { passive:true });
  onScroll();

  /* ---------- Mobile menu ---------- */
  const menuToggle = document.getElementById('menuToggle');
  const mobileMenu = document.getElementById('mobileMenu');
  const mobileClose = document.getElementById('mobileClose');
  function openMenu(){ mobileMenu && mobileMenu.classList.add('is-open'); menuToggle && menuToggle.setAttribute('aria-expanded','true'); }
  function closeMenu(){ mobileMenu && mobileMenu.classList.remove('is-open'); menuToggle && menuToggle.setAttribute('aria-expanded','false'); }
  if (menuToggle) menuToggle.addEventListener('click', openMenu);
  if (mobileClose) mobileClose.addEventListener('click', closeMenu);
  if (mobileMenu) mobileMenu.querySelectorAll('a').forEach(a => a.addEventListener('click', closeMenu));

  /* ---------- Reveal on scroll ---------- */
  const revealEls = document.querySelectorAll('.reveal');
  if (revealEls.length){
    const io = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting){
          entry.target.classList.add('is-visible');
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1 });
    revealEls.forEach(el => io.observe(el));
  }

});

/* ---------- Home hero: crossfade rotation + manual nav ----------
   Slides are injected dynamically (fetched from Supabase) on index.html,
   so this runs on demand via window.initHeroRotation() once they exist,
   rather than automatically on DOMContentLoaded. */
window.initHeroRotation = function initHeroRotation(){
  const slides = document.querySelectorAll('.hero-slide');
  if (slides.length){
    let i = Array.from(slides).findIndex(s => s.classList.contains('is-active'));
    if (i < 0) i = 0;
    const total = slides.length;
    const captionTitle = document.getElementById('heroCaptionTitle');
    const captionIndex = document.getElementById('heroCaptionIndex');
    let timer;

    function show(next){
      slides[i].classList.remove('is-active');
      i = (next + total) % total;
      slides[i].classList.add('is-active');
      if (captionIndex){
        captionIndex.textContent = `${String(i + 1).padStart(2,'0')} / ${String(total).padStart(2,'0')}`;
      }
      if (captionTitle){
        captionTitle.textContent = slides[i].dataset.caption || '';
      }
    }
    function next(){ show(i + 1); }
    function prev(){ show(i - 1); }
    function restart(){
      clearInterval(timer);
      timer = setInterval(next, 8000);
    }
    restart();

    const prevZone = document.querySelector('.hero-nav-zone.is-prev');
    const nextZone = document.querySelector('.hero-nav-zone.is-next');
    if (prevZone) prevZone.addEventListener('click', () => { prev(); restart(); });
    if (nextZone) nextZone.addEventListener('click', () => { next(); restart(); });

    document.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowRight'){ next(); restart(); }
      if (e.key === 'ArrowLeft'){ prev(); restart(); }
    });

    let touchStartX = null;
    const stage = document.querySelector('.hero-stage');
    if (stage){
      stage.addEventListener('touchstart', (e) => { touchStartX = e.touches[0].clientX; }, { passive:true });
      stage.addEventListener('touchend', (e) => {
        if (touchStartX === null) return;
        const dx = e.changedTouches[0].clientX - touchStartX;
        if (Math.abs(dx) > 40){
          if (dx < 0) { next(); restart(); } else { prev(); restart(); }
        }
        touchStartX = null;
      }, { passive:true });
    }

    // Initialize caption for the starting slide
    if (captionIndex) captionIndex.textContent = `${String(i + 1).padStart(2,'0')} / ${String(total).padStart(2,'0')}`;
    if (captionTitle) captionTitle.textContent = slides[i].dataset.caption || '';
  }
};
