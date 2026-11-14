# Hoppers

A bunny-themed AI tutor chat app for high school students. Built in SwiftUI (iOS 17+) with URLSession — no third-party packages.

## Put your API key here

The key is **never hardcoded** in Swift. Hoppers reads it in this order:

1. **`Hoppers/Secrets.plist`** ← easiest
2. The generated Info.plist key **`ANTHROPIC_API_KEY`** (Target → Info)

### Option A — Secrets.plist (recommended)

1. In Xcode’s Project Navigator, open `Hoppers/Secrets.plist`.
2. Replace `YOUR_API_KEY_HERE` with your Anthropic API key (starts with `sk-ant-`).
3. Save. Don’t commit a real key.

```
ANTHROPIC_API_KEY = sk-ant-api03-...
```

`Hoppers/Secrets.example.plist` is a backup template if you overwrite the real one.

### Option B — Info.plist (Xcode Info tab)

1. Select the **Hoppers** target.
2. Open the **Info** tab.
3. Find **ANTHROPIC_API_KEY** (already added as `YOUR_API_KEY_HERE`).
4. Paste your key as the value.

If both are set, `Secrets.plist` wins.

## Run it in the iOS Simulator

1. Open **`Hoppers.xcodeproj`** in Xcode 15 or later (Xcode 16+ is fine).
2. Add your API key using Option A or B above.
3. In the scheme toolbar, pick an iPhone simulator (iPhone 16 / 15 / SE all work).
4. Make sure the run destination is an **iPhone simulator**, not My Mac.
5. Press **⌘R** (Product → Run).
6. On the Welcome screen, pick a subject chip (Math is selected by default) and tap **Start Hopping**.
7. Send a question. Hoppers’ ears wiggle while Claude replies.

If the first reply is a bunny-themed error about a missing key, the placeholder wasn’t replaced — check `Secrets.plist` again and rebuild (⌘B, then ⌘R).

## Constants you can change

| What | Where |
| --- | --- |
| System prompt (paste yours here) | `Hoppers/Config/SystemPrompt.swift` → `SystemPrompt.text` |
| Claude model | `Hoppers/Services/ClaudeService.swift` → `ClaudeService.model` |
| Max tokens (currently 500) | `ClaudeService.maxTokens` |

## Demo notes

- Student bubbles are lavender (right); Hoppers bubbles are blush pink (left) with a bunny avatar.
- Every **3 student messages** earns a carrot in the header counter.
- Tap the welcome bunny to make it hop.

Needs a network connection to talk to `https://api.anthropic.com/v1/messages`.
