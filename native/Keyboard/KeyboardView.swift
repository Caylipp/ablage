import SwiftUI

struct KeyboardView: View {
    @ObservedObject var model: KeyboardModel

    var body: some View {
        Group {
            if !model.hasFullAccess {
                NoAccessView(model: model)
            } else if let store = model.store {
                ClipBoardView(model: model, store: store)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            if let t = model.toast {
                Text(t).font(.footnote.weight(.semibold))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 44)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.toast)
    }
}

private enum Tab: String, CaseIterable { case history = "Verlauf", kept = "Angepinnt" }

private struct ClipBoardView: View {
    @ObservedObject var model: KeyboardModel
    @ObservedObject var store: SharedStore
    @State private var tab: Tab = .history
    @State private var kind: ClipKind?
    @State private var board: String?

    private var clips: [Clip] {
        store.library.filtered(kind: kind, pinboard: tab == .kept ? board : nil, keptOnly: tab == .kept)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
                Spacer()
                KeyButton(symbol: "delete.left", label: "Löschen", repeats: true) { model.actions.deleteBackward() }
            }
            .padding(.horizontal, 8).padding(.top, 6)

            chips

            if clips.isEmpty {
                Text(tab == .history ? "Noch nichts kopiert.\nKopiere etwas und öffne diese Tastatur erneut."
                                     : "Noch nichts angepinnt.\nNotizen und Pinnwände legst du in der Ablage-App an.")
                    .font(.footnote).multilineTextAlignment(.center).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(clips) { clip in
                            Button { model.use(clip) } label: {
                                ClipCardView(clip: clip, store: store, compact: true)
                                    .frame(width: 150)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(clip.kind.label) einsetzen")
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxHeight: .infinity)
            }

            HStack(spacing: 6) {
                if model.showGlobe {
                    KeyButton(symbol: "globe", label: "Nächste Tastatur") { model.actions.nextKeyboard() }
                }
                Button { model.actions.insert(" ") } label: {
                    Text("Leerzeichen").font(.subheadline).frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color(uiColor: .systemBackground).opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                KeyButton(symbol: "return", label: "Zeilenumbruch") { model.actions.insert("\n") }
            }
            .padding(.horizontal, 8).padding(.bottom, 4)
        }
        .onChange(of: tab) { _, _ in kind = nil; board = nil }
    }

    @ViewBuilder private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if tab == .kept {
                    Chip(label: "Alle", tint: .accentColor, active: board == nil) { board = nil }
                    ForEach(store.library.pinboards) { p in
                        Chip(label: p.name, tint: Color(hex: p.colorHex), active: board == p.id) { board = board == p.id ? nil : p.id }
                    }
                } else {
                    Chip(label: "Alle", tint: .accentColor, active: kind == nil) { kind = nil }
                    let present = Set(store.library.clips.map(\.kind))
                    ForEach(ClipKind.allCases.filter(present.contains)) { k in
                        Chip(label: k.label, symbol: k.symbol, tint: k.color, active: kind == k) { kind = kind == k ? nil : k }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 28)
    }
}

private struct Chip: View {
    let label: String
    var symbol: String?
    let tint: Color
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let symbol { Image(systemName: symbol).font(.caption2) }
                Text(label).font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10).frame(height: 26)
            .foregroundStyle(active ? .white : .primary)
            .background(active ? tint : Color(uiColor: .systemBackground).opacity(0.8), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Taste im Systemstil; optional mit Dauerfeuer beim Halten (Löschen)
private struct KeyButton: View {
    let symbol: String
    let label: String
    var repeats = false
    let action: () -> Void
    @State private var timer: Timer?

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17))
            .frame(width: 48, height: 40)
            .background(Color(uiColor: .systemGray4), in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .onLongPressGesture(minimumDuration: 0.35, pressing: { down in
                guard repeats else { return }
                if !down { timer?.invalidate(); timer = nil }
            }, perform: {
                guard repeats else { return }
                timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in action() }
            })
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
    }
}

private struct NoAccessView: View {
    @ObservedObject var model: KeyboardModel

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock").font(.title2).foregroundStyle(.secondary)
            Text("Voller Zugriff fehlt").font(.headline)
            Text("Einstellungen → Allgemein → Tastatur → Tastaturen → Ablage → „Vollen Zugriff erlauben“.\nNur so kann die Tastatur deinen Verlauf lesen.")
                .font(.footnote).multilineTextAlignment(.center).foregroundStyle(.secondary)
                .padding(.horizontal)
            if model.showGlobe {
                Button { model.actions.nextKeyboard() } label: { Label("Andere Tastatur", systemImage: "globe") }
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
