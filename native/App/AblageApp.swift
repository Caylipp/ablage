import SwiftUI

@main
struct AblageApp: App {
    @StateObject private var store = SharedStore()
    @StateObject private var toast = Toast()
    @Environment(\.scenePhase) private var phase
    @State private var tab = ProcessInfo.processInfo.arguments.contains("-SetupTab") ? 2 : 0

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-KeyboardDemo") {
                KeyboardDemo(store: store)
            } else { tabs }
            #else
            tabs
            #endif
        }
    }

    private var tabs: some View {
            TabView(selection: $tab) {
                HistoryView().tabItem { Label("Verlauf", systemImage: "clock") }.tag(0)
                PinboardsView().tabItem { Label("Angepinnt", systemImage: "pin") }.tag(1)
                SettingsView().tabItem { Label("Einrichtung", systemImage: "gearshape") }.tag(2)
            }
            .environmentObject(store)
            .environmentObject(toast)
            .overlay(alignment: .bottom) { ToastView(toast: toast).padding(.bottom, 70) }
            .onChange(of: phase) { _, p in
                guard p == .active else { return }
                store.reload()
                if store.library.settings.autoCapture { Pasteboard.capture(into: store) }
                if Screenshots.importNew(into: store) > 0 { toast.show("Bildschirmfoto übernommen") }
            }
            .onOpenURL { url in handle(url) }
            .onAppear {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-SeedDemo") { DemoData.seed(store) }
                #endif
            }
    }

    /// ablage://add?text=… (Kurzbefehl)
    private func handle(_ url: URL) {
        guard url.host == "add",
              let text = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "text" })?.value,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        store.mutate { $0.add(.init(kind: Detect.kind(text), text: text, hash: Detect.hash(text))) }
        toast.show("Aus Kurzbefehl gesichert")
    }
}

final class Toast: ObservableObject {
    @Published var text: String?
    private var work: DispatchWorkItem?

    func show(_ t: LocalizedStringResource) {
        text = String(localized: t)
        work?.cancel()
        let w = DispatchWorkItem { [weak self] in self?.text = nil }
        work = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: w)
    }
}

struct ToastView: View {
    @ObservedObject var toast: Toast
    var body: some View {
        Group {
            if let t = toast.text {
                Text(t).font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(.thickMaterial, in: Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: toast.text)
    }
}
