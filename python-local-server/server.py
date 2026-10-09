#!/usr/bin/env python3
"""server.py -- Path 2 from the video: run Apple's on-device Foundation
Models LLM as a tiny local HTTP server, and let a REAL browser-based web
app (web/index.html in this repo) fetch() it directly. No WKWebView, no
Swift, no Xcode.

Requires: macOS 26+ (the Foundation Models Python SDK, new at WWDC 2026),
Apple silicon, Apple Intelligence enabled.
    pip install -r requirements.txt
    python server.py
Then open web/index.html in any browser on the SAME Mac.

This only works because the browser, the server, and the model are all on
one machine you control -- see the video/README for why this can't be
exposed to a public website or a random visitor.

Source: developer.apple.com/videos/play/wwdc2026/334 (Foundation Models
SDK for Python, and the `fm` CLI, both new at WWDC 2026).
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import apple_fm_sdk as fm

app = FastAPI(title="on-device-llm-bridge")

# Loosened for local demo purposes only -- fine here because this server
# only ever listens on localhost and is never meant to be exposed publicly.
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

model = fm.SystemLanguageModel()


class PromptRequest(BaseModel):
    prompt: str


@app.get("/health")
def health():
    is_available, reason = model.is_available()
    return {"available": is_available, "reason": reason}


@app.post("/respond")
async def respond(req: PromptRequest):
    is_available, reason = model.is_available()
    if not is_available:
        return {"error": f"on-device model unavailable: {reason}"}
    session = fm.LanguageModelSession(model=model)
    reply = await session.respond(prompt=req.prompt)
    return {"text": reply.content}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
