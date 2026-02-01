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

# Injection script
INJECTION_SCRIPT=$(cat <<EOF
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

      function showConsole(active) {
          let container = document.getElementById('integrated-console-container');
          if (!container && active) {
              container = document.createElement('div');
              container.id = 'integrated-console-container';
              container.style.cssText = "position:absolute;top:0;left:0;width:100%;height:100%;background:#000;z-index:9999;display:flex;flex-direction:column;";
              container.innerHTML = '<iframe src="/console.html" style="flex:1;border:none;background:#000;"></iframe>';
              
              const app = document.querySelector('openclaw-app');
              const main = findInShadows(app?.shadowRoot || document.body, 'main') || 
                           findInShadows(app?.shadowRoot || document.body, '.content-area');
              
              if (main) {
                  main.style.position = 'relative';
                  main.appendChild(container);
              } else {
                  document.body.appendChild(container);
              }
          }
          
          if (container) {
              container.style.display = active ? 'flex' : 'none';
          }

          if (active && location.pathname !== '/console') {
              history.pushState(null, '', '/console');
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
          consoleLink.innerHTML = '<span style="margin-right: 8px;">📟</span> CONSOLE';

          consoleLink.onclick = (e) => {
              e.preventDefault();
              showConsole(true);
              menuContainer.querySelectorAll('a').forEach(a => a.classList.remove('active'));
              consoleLink.classList.add('active');
          };

          menuContainer.insertBefore(consoleLink, chatLink);

          menuContainer.querySelectorAll('a').forEach(a => {
              if (a.id !== 'console-link') {
                  const originalClick = a.onclick;
                  a.onclick = (e) => {
                      showConsole(false);
                      if (originalClick) originalClick.apply(a, [e]);
                  };
              }
          });
      }

      window.addEventListener('popstate', () => {
          showConsole(location.pathname === '/console');
      });

      setInterval(injectMenu, 1000);
  })();
</script>
EOF
)

# Use sed to insert the script before </head>
sed -i "/<\/head>/i $INJECTION_SCRIPT" "$UI_PATH/index.html"

echo "Installation complete. Please restart OpenClaw Gateway."
