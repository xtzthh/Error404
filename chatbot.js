(function() {
  // student note: keep keys out of public repos
  const OPENROUTER_API_KEY = "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";

  // Chatbot HTML Template (Tactical HUD Redesign)
  const chatbotHTML = `
    <button id="openChatBtn" class="cyber-card" style="position:fixed; bottom:30px; right:30px; width:60px; height:60px; border-radius:50%; display:none; align-items:center; justify-content:center; cursor:pointer; z-index:1000; background:rgba(0, 255, 136, 0.1); border: 1px solid var(--neon-green);">
      <div class="corner-br"></div>
      <span style="font-size: 24px;">🤖</span>
    </button>

    <div id="chatbotContainer">
      <div id="chatbotHeader">
        <div style="display:flex; align-items:center; gap:10px;">
          <span class="status-pulse"></span>
          <div style="font-size: 14px; font-weight: 700;">AGRITECH AI</div>
        </div>
        <button id="closeChatBtn">✖</button>
      </div>
    <div id="chatMessages">
        <div class="chat-msg chat-msg-ai"><b>Assistant:</b> Hi! How can I help you today?</div>
      </div>
      <div id="chatInputRow">
        <input id="chatInput" placeholder="Ask me anything..." />
        <button id="sendChatBtn">SEND</button>
      </div>
    </div>

    <div id="aiLoader" style="display:none; position:fixed; inset:0; z-index:100000; background:var(--overlay-bg); align-items:center; justify-content:center;">
      <div class="wrap" style="background: var(--cyber-black); border: 1px solid var(--neon-green); padding: 30px; border-radius: 4px; position: relative;">
        <div class="corner-br"></div>
        <div class="ai-circle" style="border: 2px solid var(--neon-green); border-top-color: transparent; width: 50px; height: 50px; border-radius: 50%; animation: spin 1s linear infinite;"></div>
        <div class="military-tag" style="margin-top: 20px; color: var(--neon-green)">SYNTHESIZING_NEURAL_RESPONSE...</div>
      </div>
    </div>
  `;

  // Inject Chatbot UI
  const container = document.createElement('div');
  container.innerHTML = chatbotHTML;
  document.body.appendChild(container);

  // Chatbot Elements
  const openChatBtn = document.getElementById('openChatBtn');
  const closeChatBtn = document.getElementById('closeChatBtn');
  const chatbotContainer = document.getElementById('chatbotContainer');
  const chatInput = document.getElementById('chatInput');
  const sendChatBtn = document.getElementById('sendChatBtn');
  const chatMessages = document.getElementById('chatMessages');

  // Logic
  const checkLogin = () => {
    if (localStorage.getItem('as_user_role')) {
      openChatBtn.style.display = 'flex';
    }
  };
  
  window.addEventListener('load', checkLogin);
  setInterval(checkLogin, 1000); // Poll for login state changes

  openChatBtn.onclick = () => {
    chatbotContainer.style.display = 'flex';
    openChatBtn.style.display = 'none';
    setTimeout(() => chatbotContainer.classList.add('visible'), 50);
  };

  closeChatBtn.onclick = () => {
    chatbotContainer.classList.remove('visible');
    setTimeout(() => {
      chatbotContainer.style.display = 'none';
      openChatBtn.style.display = 'flex';
    }, 300);
  };

  const appendMessage = (sender, text) => {
    const msg = document.createElement('div');
    msg.className = `chat-msg ${sender === 'OPERATOR' ? 'chat-msg-user' : 'chat-msg-ai'}`;
    msg.innerHTML = `<b>${sender === 'OPERATOR' ? 'You' : 'Assistant'}:</b> ${text}`;
    chatMessages.appendChild(msg);
    chatMessages.scrollTop = chatMessages.scrollHeight;
  };

  const sendChat = async () => {
    const text = chatInput.value.trim();
    if(!text) return;
    appendMessage('OPERATOR', text);
    chatInput.value = '';
    
    const loader = document.getElementById('aiLoader');
    loader.style.display = 'flex';

    try {
      const pageContext = document.title;
      const dashboardState = Array.from(document.querySelectorAll('.card, .metric'))
        .map(el => {
          const label = el.querySelector('.military-tag')?.innerText || 'DATA';
          const value = el.querySelector('.value, .stat-value')?.innerText || 'N/A';
          return `${label}: ${value}`;
        }).join(' | ');

      // Prefer local AgriParam if enabled on backend; fallback to Gemini.
      const getLang = () => {
        const m = document.cookie.match(/googtrans=\/en\/([a-z\-]+)/);
        const code = (m ? m[1] : 'en').toLowerCase();
        return code.startsWith('hi') ? 'hi' : 'en';
      };
      const tryAgriParam = async () => {
        try {
          const st = await fetch('/model-status');
          if (!st.ok) return null;
          const sjson = await st.json();
          if (!(sjson.agriparam && sjson.agriparam.enabled && sjson.agriparam.deps_installed)) return null;

          const context = `CURRENT_SECTOR: ${pageContext}\nTELEMETRY_DATA: ${dashboardState}\nINSTRUCTIONS: Be brief (max 6 lines). Use simple actionable steps for Indian conditions.`;
          const body = {
            query: text,
            context,
            lang: getLang(),
            max_new_tokens: 240
          };

          const r = await fetch('/agri-advice', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
          });
          const j = await r.json().catch(() => ({}));
          if (!r.ok || j.error) return null;
          return j.text || null;
        } catch (_) {
          return null;
        }
      };

      const localReply = await tryAgriParam();
      if (localReply) {
        appendMessage('AGRIASSIST', localReply);
        return;
      }

      const prompt = `You are a helpful agriculture assistant.
CURRENT_SECTOR: ${pageContext}
TELEMETRY_DATA: ${dashboardState}
USER_QUERY: ${text}

INSTRUCTIONS:
- Respond in a clear, friendly tone.
- Use simple language.
- Be brief (max 5 lines).
- Avoid military or command-style language.`;

      const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
          'HTTP-Referer': window.location.href,
          'X-Title': 'AgriTech HUD Chatbot'
        },
        body: JSON.stringify({
          model: 'deepseek/deepseek-r1',
          messages: [{ role: 'user', content: prompt }],
          max_tokens: 300
        })
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error?.message || `HTTP_${res.status}`);
      }
      const data = await res.json();
      const response = data.choices?.[0]?.message?.content?.trim() || 'Sorry, I could not get a response.';
      appendMessage('AGRIASSIST', response);
    } catch (e) {
      appendMessage('SYSTEM', 'Sorry, the assistant is offline right now.');
    } finally {
      loader.style.display = 'none';
    }
  };

  sendChatBtn.onclick = sendChat;
  chatInput.onkeydown = (e) => { if(e.key === 'Enter') sendChat(); };
})();