// WebLLMView.swift
//
// Minimal, complete example of Path 1 from the video: a WKWebView-hosted
// web app that calls Apple's on-device Foundation Models LLM through a
// WKUserContentController bridge.
//
// Your web content (web/index.html in this repo) never touches Foundation
// Models directly -- it posts a message, native Swift code receives it,
// calls the model, and sends the reply back into the page.
//
// Requires: iOS 26+ / macOS 26+ (or later), a device/simulator with Apple
// Intelligence enabled, Xcode 26+.
// Source for this pattern: an Apple DTS engineer's answer on Apple's own
// Developer Forums, thread 833716, "Framework Boundaries" (Jun 2026):
// https://developer.apple.com/forums/thread/833716

import SwiftUI
import WebKit
import FoundationModels

struct WebLLMView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        // "onDeviceLLM" is the name JavaScript uses to reach native code --
        // see web/index.html's webkit.messageHandlers.onDeviceLLM.postMessage(...)
        contentController.add(context.coordinator, name: "onDeviceLLM")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        context.coordinator.webView = webView

        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var webView: WKWebView?

        func userContentController(_ userContentController: WKUserContentController,
                                    didReceive message: WKScriptMessage) {
            guard message.name == "onDeviceLLM", let prompt = message.body as? String else { return }

            Task {
                do {
                    let session = LanguageModelSession()
                    let reply = try await session.respond(to: prompt)
                    await sendToWeb(text: reply.content, isError: false)
                } catch {
                    await sendToWeb(text: "On-device model unavailable: \(error.localizedDescription)", isError: true)
                }
            }
        }

        @MainActor
        private func sendToWeb(text: String, isError: Bool) {
            // Escape for safe embedding in a JS string literal before
            // handing it back to the page.
            let escaped = text
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
            webView?.evaluateJavaScript("onLLMReply('\(escaped)', \(isError))")
        }
    }
}
