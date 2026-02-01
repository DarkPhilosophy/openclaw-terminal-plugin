#!/bin/bash

# OpenClaw Terminal Plugin Installer
# Injects the console integration into the OpenClaw Gateway Control UI.

set -e

# Detect OpenClaw location
OC_ROOT=$(npm root -g)/openclaw
if [ ! -d "$OC_ROOT" ]; then
    echo "Error: OpenClaw not found at $OC_ROOT"
    exit 1
fi

UI_PATH="$OC_ROOT/dist/control-ui"
PLUGIN_NAME="terminal"

echo "Installing Terminal Plugin assets..."
cp assets/console.html "$UI_PATH/console.html"

echo "Injecting native routing logic into OpenClaw Dashboard..."
# Create a backup of the original index.html if not already exists
if [ ! -f "$UI_PATH/index.html.bak" ]; then
    cp "$UI_PATH/index.html" "$UI_PATH/index.html.bak"
fi

# Injection script using a Fixed Overlay approach for seamless integration
INJECTION_SCRIPT=$(cat <<EOF
<style>
  #integrated-console-overlay {
    position: fixed;
    top: 0;
    left: 260px;
    right: 0;
    bottom: 0;
    background: #000;
    z-index: 1000;
    display: none;
    flex-direction: column;
  }
  #integrated-console-overlay.active {
    display: flex;
  }
  .console-iframe {
    flex: 1;
    border: none;
    background: #000;
  }
  @media (max-width: 768px) {
    #integrated-console-overlay {
      left: 0;
    }
  }
</style>
<script>
  (function() {
      function findInShadows(root, selector) {
          if (!root) return null;
          const found = root.querySelector(selector);
          if (found) return found;
          const all = root.querySelectorAll('*');
          for (const el of all) {
              if (el.shadowRoot) {
                  const res = findInShadows(el.shadowRoot, selector);
                  if (res) return res;
              }
          }
          return null;
      }

      function findChatLink(root) {
          const allLinks = root.querySelectorAll('a');
          for (const a of allLinks) {
              const text = a.textContent.trim().toLowerCase();
              if (text === 'chat' || a.href.includes('/chat')) return a;
          }
          const all = root.querySelectorAll('*');
          for (const el of all) {
              if (el.shadowRoot) {
                  const found = findChatLink(el.shadowRoot);
                  if (found) return found;
              }
          }
          return null;
      }

      function updateConsoleState() {
          const isActive = location.pathname === '/console';
          let overlay = document.getElementById('integrated-console-overlay');
          
          if (isActive && !overlay) {
              overlay = document.createElement('div');
              overlay.id = 'integrated-console-overlay';
              overlay.innerHTML = '<iframe src="/console.html" class="console-iframe"></iframe>';
              document.body.appendChild(overlay);
          }
          
          if (overlay) {
              overlay.classList.toggle('active', isActive);
              const app = document.querySelector('openclaw-app');
              const sidebar = findInShadows(app?.shadowRoot, 'aside') || findInShadows(app?.shadowRoot, '.sidebar');
              if (sidebar) {
                  overlay.style.left = sidebar.offsetWidth + 'px';
              }
          }
      }

      function injectMenu() {
          if (document.querySelector('#console-link')) return;

          const chatLink = findChatLink(document.body);
          if (!chatLink) return;

          const menuContainer = chatLink.parentElement;
          const consoleLink = document.createElement('a');
          consoleLink.id = 'console-link';
          consoleLink.href = '/console';
          consoleLink.className = chatLink.className;
          consoleLink.style.cssText = chatLink.style.cssText;
          consoleLink.style.color = '#00ff00';
          consoleLink.style.borderLeft = '4px solid #00ff00';
          consoleLink.style.fontWeight = 'bold';
          consoleLink.innerHTML = '<span style="margin-right: 8px;">📟</span> CONSOLE';

          consoleLink.onclick = (e) => {
              e.preventDefault();
              history.pushState(null, '', '/console');
              updateConsoleState();
              menuContainer.querySelectorAll('a').forEach(a => {
                  a.classList.remove('active');
                  a.style.backgroundColor = '';
              });
              consoleLink.classList.add('active');
              consoleLink.style.backgroundColor = 'rgba(0, 255, 0, 0.1)';
          };

          menuContainer.insertBefore(consoleLink, chatLink);

          menuContainer.querySelectorAll('a').forEach(a => {
              if (a.id !== 'console-link') {
                  a.addEventListener('click', () => {
                      setTimeout(updateConsoleState, 10);
                  });
              }
          });
      }

      window.addEventListener('popstate', updateConsoleState);
      
      const appCheck = setInterval(() => {
          const app = document.querySelector('openclaw-app');
          if (app && app.shadowRoot) {
              updateConsoleState();
              clearInterval(appCheck);
          }
      }, 500);

      setInterval(() => {
          injectMenu();
          if (location.pathname !== '/console' && document.getElementById('integrated-console-overlay')?.classList.contains('active')) {
              updateConsoleState();
          }
      }, 1000);
  })();
</script>
EOF
)

# Use sed to insert the script before </head>
sed -i "/<\/head>/i $INJECTION_SCRIPT" "$UI_PATH/index.html"

echo "Installation complete. Please restart OpenClaw Gateway."
