# OpenClaw Terminal Plugin

A native shell console integrated directly into the OpenClaw Gateway Dashboard. Execute commands on your host machine without leaving the browser interface.

## Features
- **Integrated UI:** Access a full-screen terminal directly inside the OpenClaw dashboard.
- **Native Routing:** Uses `/console` path for seamless navigation.
- **Slash Commands:** Execute one-off commands using `/sh <command>` in chat.
- **Secure Uplink:** Uses the existing OpenClaw Gateway WebSocket and authentication.
- **Persistent:** Injected natively into the dashboard menu, always available.

## Installation

### 1. Clone the repository
Clone this repository into your OpenClaw extensions directory:
```bash
cd ~/.openclaw/extensions
git clone https://github.com/DarkPhilosophy/openclaw-terminal-plugin terminal
```

### 2. Install Assets
Run the installation script to inject the console UI and routing logic into your Gateway:
```bash
cd terminal
chmod +x scripts/install.sh
./scripts/install.sh
```

### 3. Enable the Plugin
Enable the plugin in your `~/.openclaw/openclaw.json` or via the dashboard:
```json
{
  "plugins": {
    "entries": {
      "terminal": {
        "enabled": true
      }
    }
  }
}
```

### 4. Restart OpenClaw
Restart your OpenClaw gateway for the changes to take effect:
```bash
openclaw gateway restart
```

## Usage
- **Web Interface:** Click the **📟 CONSOLE** link at the top of your sidebar (above Chat).
- **In Chat:** Type `/sh <command>` (e.g., `/sh screenfetch`) to get quick results in your conversation.
- **Link Alias:** Type `/console` in chat to get a direct link to the web console.

## Credits
Built for the OpenClaw community by **CALYP** & **DarkPhilosophy**. 🦞
