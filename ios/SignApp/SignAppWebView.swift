import SwiftUI
import UniformTypeIdentifiers

private let supabaseURL = URL(string: "https://hxjxekuvgufmnvbyzkre.supabase.co")!
private let supabaseKey = "sb_publishable_QD-uPtgKnglULNGBZMaQ2Q_Hie5DpHx"

@MainActor
final class SignAppModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var signedIn = false
    @Published var selectedName = ""
    @Published var status = "Sign in to upload and sign an IPA."
    @Published var busy = false
    @Published var installURL: URL?
    private var accessToken = UserDefaults.standard.string(forKey: "signapp.accessToken") ?? ""

    init() { signedIn = !accessToken.isEmpty }

    func authenticate(create: Bool) async {
        guard !email.isEmpty, password.count >= 8 else { status = "Enter an email and password with at least 8 characters."; return }
        busy = true
        defer { busy = false }
        let endpoint = supabaseURL.appendingPathComponent("auth/v1").appendingPathComponent(create ? "signup" : "token").appending(queryItems: create ? [] : [URLQueryItem(name: "grant_type", value: "password")])
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["email": email, "password": password])
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["access_token"] as? String else {
                let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["msg"] as? String
                status = message ?? "Authentication failed. Check your details and email confirmation."
                return
            }
            accessToken = token
            UserDefaults.standard.set(token, forKey: "signapp.accessToken")
            signedIn = true
            status = create ? "Account created and signed in." : "Signed in. Choose an IPA."
        } catch { status = error.localizedDescription }
    }

    func signOut() {
        accessToken = ""
        UserDefaults.standard.removeObject(forKey: "signapp.accessToken")
        signedIn = false
        status = "Signed out."
    }

    func uploadAndSign(fileURL: URL) async {
        guard signedIn else { status = "Sign in first."; return }
        busy = true
        installURL = nil
        defer { busy = false }
        do {
            let granted = fileURL.startAccessingSecurityScopedResource()
            defer { if granted { fileURL.stopAccessingSecurityScopedResource() } }
            let fileData = try Data(contentsOf: fileURL)
            guard fileData.count <= 500 * 1024 * 1024 else { status = "IPA must be 500 MB or smaller."; return }
            let boundary = "SignAppBoundary-\(UUID().uuidString)"
            var body = Data()
            body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\nContent-Type: application/octet-stream\r\n\r\n".utf8))
            body.append(fileData)
            body.append(Data("\r\n--\(boundary)--\r\n".utf8))
            var request = URLRequest(url: supabaseURL.appendingPathComponent("functions/v1/upload-ipa"))
            request.httpMethod = "POST"
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            status = "Uploading IPA…"
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let jobId = json["jobId"] as? String else {
                status = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String ?? "Upload failed."
                return
            }
            status = "Upload complete. Waiting for signing…"
            for _ in 0..<120 {
                try await Task.sleep(for: .seconds(5))
                var poll = URLRequest(url: supabaseURL.appendingPathComponent("functions/v1/signing-status").appending(queryItems: [URLQueryItem(name: "jobId", value: jobId)]))
                poll.setValue(supabaseKey, forHTTPHeaderField: "apikey")
                poll.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                let (pollData, _) = try await URLSession.shared.data(for: poll)
                let result = try JSONSerialization.jsonObject(with: pollData) as? [String: Any] ?? [:]
                let state = result["status"] as? String ?? "queued"
                if state == "complete", let link = result["manifestUrl"] as? String, let url = URL(string: link) {
                    installURL = url
                    status = "Signing complete. Tap Install Signed App."
                    return
                }
                if state == "failed" { status = result["error"] as? String ?? "Signing failed."; return }
                status = "Signing: \(state)…"
            }
            status = "Still processing. Check back in a moment."
        } catch { status = error.localizedDescription }
    }
}

struct SignAppWebView: View {
    @StateObject private var model = SignAppModel()
    @State private var showingImporter = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.10, green: 0.15, blue: 0.29), Color(red: 0.03, green: 0.04, blue: 0.08)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "signature").font(.system(size: 25, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 52, height: 52).background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 15))
                        VStack(alignment: .leading, spacing: 2) { Text("SignApp").font(.title2.bold()); Text("NATIVE IPA SIGNER").font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.55)) }
                        Spacer()
                        if model.signedIn { Button("Sign out") { model.signOut() }.font(.caption.weight(.semibold)) }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your apps.").font(.system(size: 38, weight: .bold, design: .rounded))
                        Text("Your device.").font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(.cyan)
                        Text("Import an IPA, sign it with your configured certificate, and install it on your device.").foregroundStyle(.white.opacity(0.65))
                    }.padding(.top, 20)
                    if !model.signedIn {
                        Group {
                            Text("Sign in to SignApp").font(.headline)
                            TextField("Email address", text: $model.email).textInputAutocapitalization(.never).keyboardType(.emailAddress).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                            SecureField("Password", text: $model.password).textFieldStyle(.roundedBorder)
                            HStack {
                                Button("Sign in") { Task { await model.authenticate(create: false) } }.buttonStyle(SignAppButton())
                                Button("Create account") { Task { await model.authenticate(create: true) } }.buttonStyle(SignAppSecondaryButton())
                            }
                        }.padding(18).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Signed in", systemImage: "checkmark.seal.fill").foregroundStyle(.green).font(.headline)
                            Button { showingImporter = true } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.badge.plus").font(.system(size: 34))
                                    Text(model.selectedName.isEmpty ? "Choose IPA from Files" : model.selectedName).font(.headline)
                                    Text("Select an .ipa file").font(.caption).foregroundStyle(.white.opacity(0.55))
                                }.frame(maxWidth: .infinity).padding(.vertical, 28).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [7])))
                            }.disabled(model.busy)
                            if model.busy { ProgressView().tint(.white) }
                            if let url = model.installURL {
                                Button { UIApplication.shared.open(URL(string: "itms-services://?action=download-manifest&url=\(url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url.absoluteString)")!) } label: {
                                    Label("Install Signed App", systemImage: "arrow.down.app.fill").frame(maxWidth: .infinity)
                                }.buttonStyle(SignAppButton())
                            }
                        }.padding(18).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                    }
                    Text(model.status).font(.footnote).foregroundStyle(.white.opacity(0.72)).frame(maxWidth: .infinity, alignment: .leading).padding(15).background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                    Text("Only install apps you own or are authorized to use.").font(.caption2).foregroundStyle(.white.opacity(0.4)).frame(maxWidth: .infinity)
                }.padding(22).padding(.top, 18)
            }
        }
        .preferredColorScheme(.dark)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [UTType(filenameExtension: "ipa") ?? .data], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls): if let url = urls.first { model.selectedName = url.lastPathComponent; Task { await model.uploadAndSign(fileURL: url) } }
            case .failure(let error): model.status = error.localizedDescription
            }
        }
    }
}

struct SignAppButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.font(.headline).foregroundStyle(.white).padding(14).frame(maxWidth: .infinity).background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 12)).opacity(configuration.isPressed ? 0.75 : 1) }
}
struct SignAppSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.font(.subheadline.weight(.semibold)).foregroundStyle(.white).padding(14).frame(maxWidth: .infinity).background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12)).clipShape(RoundedRectangle(cornerRadius: 12)).opacity(configuration.isPressed ? 0.7 : 1) }
}