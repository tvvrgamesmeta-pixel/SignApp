import SwiftUI

@main
struct SignAppApp: App {
    var body: some Scene {
        WindowGroup {
            SignAppWebView()
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
        }
    }
}