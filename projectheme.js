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