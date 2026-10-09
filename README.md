# foundation-models-web-bridge

Companion code for the video **"Can A Web App Actually Use Apple Intelligence?"** (The AI Briefing Book).

**The short answer:** Apple's Foundation Models framework (the on-device LLM powering Apple Intelligence) has **no JavaScript interface**. Confirmed directly by an Apple DTS engineer on Apple's own Developer Forums:

> "The Foundation Models framework doesn't provide any JavaScript interface, but it seems that you are asking how to run Swift code from web content in `WKWebView`. If that is the case, WebKit provides a mechanism (`WKUserContentController`) for a web app to run your app's native code."
> — Ziqiao Chen, Apple Worldwide Developer Relations, [Developer Forums thread 833716](https://developer.apple.com/forums/thread/833716) (Jun 2026)

This repo has two **real, runnable** bridges — pick the one that matches what you're actually building.

## Path 1 — `wkwebview-bridge/` — wrap it in a native shell

Your web app runs inside a `WKWebView` hosted by a real native app. JavaScript calls `webkit.messageHandlers.onDeviceLLM.postMessage(...)`; native Swift receives it via `WKUserContentController`, calls Foundation Models directly, and sends the reply back into the page with `evaluateJavaScript`.

- Runs on **iPhone, iPad, Mac, Vision Pro** — anywhere `WKWebView` and Foundation Models both exist.
- Requires shipping a real app (Xcode, App Store or TestFlight).
- `WebLLMView.swift` — the native host + bridge
- `web/index.html` — the web content that runs inside it

## Path 2 — `python-local-server/` — run it as a local server

New as of **WWDC 2026**: a Foundation Models SDK for Python (`pip install apple_fm_sdk`) plus a pre-installed `fm` CLI on macOS 27. Run a tiny local HTTP server that calls the on-device model directly, and a **real browser tab** — no native wrapper at all — just `fetch()`s it.

- **macOS only** (the Python SDK doesn't reach iPhone/iPad — that's still Path 1).
- No Xcode, no App Store review — just a script you run yourself.
- `server.py` — a FastAPI server wrapping the SDK
- `web/index.html` — a plain web page that calls it over HTTP

```bash
cd python-local-server
pip install -r requirements.txt
python server.py          # starts on localhost:8000
open web/index.html       # any browser, same Mac
```

## The one thing neither path does

**No public website can reach a random visitor's on-device model.** Both paths need a trusted, same-device context — either an installed app (Path 1) or a locally running server you started yourself (Path 2). If you're building a public-facing website for strangers, you still need a real cloud API; on-device access is strictly a same-device pattern, by design (privacy, not an oversight).

## Sources

- [Apple Developer Forums, thread 833716, "Framework Boundaries"](https://developer.apple.com/forums/thread/833716) — the DTS engineer's answer this whole repo is built on
- [WWDC 2026, session 334](https://developer.apple.com/videos/play/wwdc2026/334) — the Foundation Models Python SDK and `fm` CLI
- [`WKUserContentController` documentation](https://developer.apple.com/documentation/webkit/wkusercontentcontroller)

## Disclaimer

Educational code, not production-hardened. Not affiliated with or endorsed by Apple. API shapes (`apple_fm_sdk`, `fm` CLI) are current as of WWDC 2026 and may change — check Apple's own docs before shipping.
