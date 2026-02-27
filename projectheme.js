function() {
  let translatorInitialized = false;

  function getCurrentLanguage() {
    const match = document.cookie.match(/(?:^|;\s*)googtrans=\/en\/([a-z\-]+)/i);
    const code = (match && match[1] ? match[1] : 'en').toLowerCase();
    if (code.startsWith('hi')) return 'hi';
    if (code.startsWith('mr')) return 'mr';
    return 'en';
  }

  function setLanguage(lang) {
    const safeLang = ['en', 'hi', 'mr'].includes(lang) ? lang : 'en';
    const value = `/en/${safeLang}`;
    document.cookie = `googtrans=${value};path=/`;
    document.cookie = `googtrans=${value};path=/;domain=${location.hostname}`;
    localStorage.setItem('as_lang', safeLang);
    location.reload();
  }

  function bindExistingLanguageSelect() {
    const select = document.getElementById('langSelect');
    if (!select) return;
    select.setAttribute('translate', 'no');
    select.classList.add('notranslate');
    Array.from(select.options || []).forEach((opt) => {
      opt.setAttribute('translate', 'no');
      opt.classList.add('notranslate');
    });
    if (select.options[0]) select.options[0].text = 'EN';
    if (select.options[1]) select.options[1].text = 'HI';
    if (select.options[2]) select.options[2].text = 'MR';
    select.value = getCurrentLanguage();
    select.onchange = (e) => setLanguage(e.target.value);
  }
  function injectLanguageSwitcher() {
    if (document.getElementById('globalLangSwitch')) return;
    const box = document.createElement('div');
    box.id = 'globalLangSwitch';
    box.className = 'cyber-card';
    box.setAttribute('translate', 'no');
    box.classList.add('notranslate');
    box.style.cssText = [
      'position:fixed',
      'top:18px',
      'right:18px',
      'z-index:1001',
      'width:46px',
      'height:46px',
      'padding:0',
      'border-radius:50%',
      'display:flex',
      'align-items:center',
      'justify-content:center',
      'overflow:hidden'
    ].join(';');
    box.innerHTML = `
      <select id="globalLangSelect" class="notranslate" translate="no" aria-label="Language selector" style="width:100%;height:100%;background:transparent;border:none;outline:none;cursor:pointer;color:var(--text-primary);font-family:'Roboto Mono', monospace;font-size:11px;font-weight:700;line-height:1;text-align:center;text-align-last:center;appearance:none;-webkit-appearance:none;padding:0 8px;">
        <option value="en">EN</option>
        <option value="hi">HI</option>
        <option value="mr">MR</option>
      </select>
    `;
    document.body.appendChild(box);

    const select = document.getElementById('globalLangSelect');
    if (!select) return;
    select.value = getCurrentLanguage();
    select.onchange = (e) => setLanguage(e.target.value);
  }

  function initGoogleTranslator() {
    if (translatorInitialized || document.getElementById('google_translate_element')) return;
    translatorInitialized = true;

    const holder = document.createElement('div');
    holder.id = 'google_translate_element';
    holder.style.display = 'none';
    document.body.appendChild(holder);

    window.googleTranslateElementInit = function() {
      if (!window.google || !window.google.translate) return;
      new window.google.translate.TranslateElement(
        { pageLanguage: 'en', includedLanguages: 'en,hi,mr', autoDisplay: false },
        'google_translate_element'
      );
    };