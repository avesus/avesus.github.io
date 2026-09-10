/* Progressive enhancement: without JavaScript each link still opens its SVG. */
(() => {
  const links = [...document.querySelectorAll('#gf-radio figure.inspectable-image > a')];
  if (!links.length || typeof HTMLDialogElement === 'undefined') return;
  const viewer = document.createElement('dialog');
  if (typeof viewer.showModal !== 'function') return;
  viewer.className = 'diagram-viewer';
  viewer.setAttribute('aria-labelledby', 'diagram-viewer-title');
  viewer.innerHTML = '<div class="diagram-viewer-bar"><p class="diagram-viewer-title" id="diagram-viewer-title">Diagram</p><div class="diagram-viewer-actions"><button type="button" class="diagram-fullscreen">Full screen</button><button type="button" class="diagram-close" aria-label="Close diagram">Close</button></div></div><img class="diagram-viewer-image" alt=""><a class="diagram-viewer-original" target="_blank" rel="noopener">Open original SVG</a>';
  document.body.append(viewer);
  const picture = viewer.querySelector('img');
  const title = viewer.querySelector('.diagram-viewer-title');
  const original = viewer.querySelector('.diagram-viewer-original');
  const close = viewer.querySelector('.diagram-close');
  const fullscreen = viewer.querySelector('.diagram-fullscreen');
  fullscreen.hidden = !document.fullscreenEnabled || !document.documentElement.requestFullscreen;
  let ownsFullscreen = false;
  let opener;
  const finish = async () => {
    if (ownsFullscreen && document.fullscreenElement) {
      try { await document.exitFullscreen(); } catch { /* Keep Close usable. */ }
    }
    if (viewer.open) viewer.close();
  };
  close.addEventListener('click', finish);
  viewer.addEventListener('cancel', event => { event.preventDefault(); void finish(); });
  viewer.addEventListener('keydown', event => {
    if (event.key !== 'Tab') return;
    const first = fullscreen.hidden ? close : fullscreen;
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault(); original.focus();
    } else if (!event.shiftKey && document.activeElement === original) {
      event.preventDefault(); first.focus();
    }
  });
  viewer.addEventListener('close', () => {
    document.documentElement.classList.remove('gf-diagram-open');
    opener?.focus({preventScroll:true});
  });
  fullscreen.addEventListener('click', async () => {
    try {
      if (ownsFullscreen && document.fullscreenElement) await document.exitFullscreen();
      else if (!document.fullscreenElement) {
        await document.documentElement.requestFullscreen();
        ownsFullscreen = true;
        fullscreen.textContent = 'Exit full screen';
      }
    } catch { /* Full-viewport modal remains available if browser denies fullscreen. */ }
  });
  document.addEventListener('fullscreenchange', () => {
    if (!document.fullscreenElement) ownsFullscreen = false;
    fullscreen.textContent = ownsFullscreen ? 'Exit full screen' : 'Full screen';
  });
  links.forEach((link, index) => {
    const image = link.querySelector('img');
    if (!image) return;
    link.title = 'Enlarge diagram';
    link.setAttribute('aria-haspopup', 'dialog');
    link.addEventListener('click', event => {
      if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
      event.preventDefault();
      opener = link;
      picture.src = link.href;
      picture.alt = image.alt;
      title.textContent = `Diagram ${index + 1} of ${links.length}`;
      original.href = link.href;
      viewer.showModal();
      document.documentElement.classList.add('gf-diagram-open');
      close.focus({preventScroll:true});
    });
  });
})();
