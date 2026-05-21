![Sausage — Claude usage tracker for your macOS menu bar](assets/banner.webp)

# Sausage

A lightweight macOS menu bar app that tracks your **Claude Code** token usage in real time — so you always know how much of your 5-hour block you've burned through. Works with any Claude Code plan (Pro, Max 5x, Max 20x).

## Features

- **Live token counter** in the menu bar with color-coded usage ring (green → yellow → red)
- **Current block** — tokens used, estimated cost, time remaining, and model breakdown
- **Today & 7-day sparkline** — quick overview of daily usage patterns
- **Weekly stacked bar chart** — per-day breakdown by model (Opus / Sonnet / Haiku)
- **90-day activity heatmap** — GitHub-style calendar of your usage history
- **Top projects** — which Claude Code projects consumed the most tokens this week
- **Admin API integration** — connect your Anthropic Admin API key to see real API spend data
- **Right-click context menu** — Settings and Quit directly from the icon
- Credentials stored securely in the **macOS Keychain**
- Auto-launches at login via LaunchAgent

---

## Requirements

| Requirement | Notes |
|---|---|
| macOS 14 Sonoma or later | Required for SwiftUI Charts and MenuBarExtra API |
| [Claude Code](https://claude.com/claude-code) installed and used at least once | Sausage reads its local usage logs |
| Any Claude subscription that includes Claude Code | Pro, Max 5x, or Max 20x — see [Plan compatibility](#plan-compatibility) |
| [`ccusage`](https://github.com/ryoppippi/ccusage) CLI | Reads local Claude usage logs — no extra account needed |
| Node.js 18+ | Required by ccusage |

### Plan compatibility

Sausage works with any plan that uses Claude Code's 5-hour usage blocks. Pick your plan in **Settings → Plan** and the token limit auto-fills:

| Plan | Default 5h limit | Tracking | Admin API |
|---|---|---|---|
| **Pro** ($20/mo) | ~4.4M tokens | ✅ Full | ✅ if you have an Admin key |
| **Max 5x** ($100/mo) | ~22M tokens | ✅ Full | ✅ |
| **Max 20x** ($200/mo) | ~88M tokens | ✅ Full | ✅ |
| **Custom** | You set it | ✅ Full | ✅ |
| **Team / Enterprise** | Set as Custom | ✅ Full | ✅ |
| **API only (no Claude Code)** | n/a — no 5h blocks | ⚠️ Limited | ✅ |

The block-limit estimates above are community-derived approximations — Anthropic doesn't publish exact numbers. Adjust the Custom value to match your real-world usage if you see the ring fill too fast or too slow.

---

## Setup

### 1. Install Node.js (if not already installed)

```bash
# With Homebrew
brew install node

# Or download from https://nodejs.org
```

### 2. Install ccusage

```bash
npm install -g ccusage
```

Verify it works:

```bash
ccusage blocks --json
```

You should see JSON output with your recent Claude usage blocks. If not, make sure you've used Claude at least once via Claude.ai or Claude Code.

### 3. Build and run Sausage

```bash
git clone https://github.com/therealpan/sausage.git
cd sausage
bash Scripts/build-app.sh
open dist/Sausage.app
```

### 4. (Optional) Auto-start at login

```bash
bash Scripts/install-launchagent.sh
```

To uninstall the LaunchAgent:

```bash
launchctl unload ~/Library/LaunchAgents/com.piirz.sausage.plist
rm ~/Library/LaunchAgents/com.piirz.sausage.plist
```

---

## Optional: Anthropic Admin API key

The Admin API section unlocks real API spend tracking (token usage billed via the Anthropic API, separate from Claude Max).

**You only need this if you also use the Anthropic API directly** (e.g. for your own apps or scripts).

### How to get an Admin API key

1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Open **Settings → API Keys**
3. Click **Create key**, select **Admin** role
4. Copy the key (starts with `sk-ant-admin01-…`)
5. In Sausage, right-click the icon → **Settings**, paste the key and click **Save**

The key is stored in your macOS Keychain and never leaves your machine.

---

## How it works

Token and session data is read from `ccusage`, a local CLI tool that parses Claude's usage logs stored on your machine at `~/.claude/`. No data is sent to any external server — everything runs locally.

The Admin API feature is fully optional. When configured, Sausage calls the official Anthropic API using your own key to fetch organization-level usage reports.

---

## License

MIT
