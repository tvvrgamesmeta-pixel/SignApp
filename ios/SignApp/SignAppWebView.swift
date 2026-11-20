import SwiftUI
import WebKit

struct SignAppWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 8/255, green: 11/255, blue: 20/255, alpha: 1)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        if let url = URL(string: "https://tvvrgamesmeta-pixel.github.io/SignApp/") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}