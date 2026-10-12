import SwiftUI

/// Tastenfarben im Stil der Systemtastatur, hell und dunkel
struct KeyStyle {
    let dark: Bool
    var key: Color { dark ? Color(white: 0.42) : .white }
    var function: Color { dark ? Color(white: 0.26) : Color(red: 0.68, green: 0.70, blue: 0.74) }
    var chip: Color { dark ? Color(white: 0.30) : Color.white.opacity(0.85) }
}

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

    private var style: KeyStyle { KeyStyle(dark: model.dark) }

    private var clips: [Clip] {
        store.library.filtered(query: model.query, kind: kind, pinboard: tab == .kept ? board : nil, keptOnly: tab == .kept)
    }

    /// Zuletzt-Bereich: die 3 neuesten Einträge im ungefilterten Verlauf sind breiter
    private var highlightRecent: Bool { tab == .history && kind == nil && !model.searching }

    var body: some View {
        VStack(spacing: 6) {
            topBar
            if model.searching { searchField } else { chips }
            ZStack {
                cards
                if let clip = model.actionClip { ActionPanel(model: model, clip: clip, style: style) }
            }
            .frame(maxHeight: .infinity)
            if model.searching {
                MiniKeyboard(model: model, style: style)
            } else {
                bottomRow
            }
        }
        .padding(.bottom, 4)
        .onChange(of: tab) { _, _ in kind = nil; board = nil; model.actionClip = nil }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { Text(LocalizedStringKey($0.rawValue)).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)
            Spacer()
            KeyButton(symbol: model.searching ? "xmark" : "magnifyingglass", label: "Suchen", style: style) {
                model.searching.toggle()
                model.query = ""
                model.actionClip = nil
            }
            KeyButton(symbol: "delete.left", label: "Löschen", style: style, repeats: true) { model.actions.deleteBackward() }
        }
        .padding(.horizontal, 8).padding(.top, 6)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            Text(model.query.isEmpty ? String(localized: "Suchbegriff tippen") : model.query)
                .foregroundStyle(model.query.isEmpty ? .secondary : .primary)
                .lineLimit(1)
            Spacer()
            if !model.query.isEmpty {
                Button { model.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain)
            }
        }
        .font(.footnote)
        .padding(.horizontal, 10).frame(height: 28)
        .background(style.chip, in: Capsule())
        .padding(.horizontal, 8)
    }

    @ViewBuilder private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if tab == .kept {
                    Chip(label: String(localized: "Alle"), tint: .accentColor, active: board == nil, style: style) { board = nil }
                    ForEach(store.library.pinboards) { p in
                        Chip(label: p.name, tint: Color(hex: p.colorHex), active: board == p.id, style: style) { board = board == p.id ? nil : p.id }
                    }
                } else {
                    Chip(label: String(localized: "Alle"), tint: .accentColor, active: kind == nil, style: style) { kind = nil }
                    let present = Set(store.library.clips.map(\.kind))
                    ForEach(ClipKind.allCases.filter(present.contains)) { k in
                        Chip(label: k.label, symbol: k.symbol, tint: k.color, active: kind == k, style: style) { kind = kind == k ? nil : k }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 28)
    }

    @ViewBuilder private var cards: some View {
        let list = clips
        if list.isEmpty {
            Text(model.searching ? String(localized: "Nichts gefunden")
                 : tab == .history ? String(localized: "Noch nichts kopiert.\nKopiere etwas und öffne diese Tastatur erneut.")
                 : String(localized: "Noch nichts angepinnt.\nNotizen und Pinnwände legst du in der Ablage-App an."))
                .font(.footnote).multilineTextAlignment(.center).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, clip in
                        card(clip, recent: highlightRecent && index < 3)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private func card(_ clip: Clip, recent: Bool) -> some View {
        ClipCardView(clip: clip, store: store, compact: true)
            .frame(width: recent ? 185 : 140)
            .overlay(alignment: .bottomTrailing) {
                if recent {
                    Text("Zuletzt").font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor, in: Capsule()).padding(6)
                } else if clip.expiresAt != nil && !clip.isKept {
                    Image(systemName: "timer").font(.caption2).foregroundStyle(.white)
                        .padding(4).background(.orange, in: Circle()).padding(6)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { model.actionClip = nil; model.use(clip) }
            .onLongPressGesture(minimumDuration: 0.4) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                model.actionClip = clip
            }
            .accessibilityLabel("\(clip.kind.label) einsetzen")
            .accessibilityAddTraits(.isButton)
    }

    private var bottomRow: some View {
        HStack(spacing: 6) {
            if model.showGlobe {
                KeyButton(symbol: "globe", label: "Nächste Tastatur", style: style) { model.actions.nextKeyboard() }
            }
            Button { model.actions.insert(" ") } label: {
                Text("Leerzeichen").font(.subheadline).frame(maxWidth: .infinity, minHeight: 40)
                    .background(style.key, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            KeyButton(symbol: "return", label: "Zeilenumbruch", style: style) { model.actions.insert("\n") }
        }
        .padding(.horizontal, 8)
    }
}

/// Langes Drücken: Einfügen & anpinnen sowie Umwandlungen vor dem Einsetzen
private struct ActionPanel: View {
    @ObservedObject var model: KeyboardModel
    let clip: Clip
    let style: KeyStyle

    private var isText: Bool { clip.kind != .image && clip.kind != .file }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(clip.title ?? clip.text ?? clip.kind.label).font(.caption).lineLimit(1).foregroundStyle(.secondary)
                Spacer()
                Button { model.actionClip = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ActionButton(symbol: "pin.fill", label: String(localized: "Einfügen & anpinnen"), style: style, accent: true) {
                        model.actionClip = nil
                        model.insertAndPin(clip)
                    }
                    if isText {
                        ForEach(Transform.allCases) { t in
                            ActionButton(symbol: t.symbol, label: t.label, style: style) {
                                model.actionClip = nil
                                model.use(clip, transform: t)
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

private struct ActionButton: View {
    let symbol: String
    let label: String
    let style: KeyStyle
    var accent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 16))
                Text(label).font(.caption2).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(width: 92, height: 54)
            .foregroundStyle(accent ? .white : .primary)
            .background(accent ? Color.accentColor : style.key, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

/// Eingebaute Mini-Tastatur für die Suche (eine Tastatur kann keine zweite öffnen)
private struct MiniKeyboard: View {
    @ObservedObject var model: KeyboardModel
    let style: KeyStyle
    private let rows = ["qwertzuiop", "asdfghjklß", "yxcvbnmäöü"]

    var body: some View {
        VStack(spacing: 5) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(Array(row), id: \.self) { ch in
                        Button { model.query.append(ch) } label: {
                            Text(String(ch)).font(.system(size: 16))
                                .frame(maxWidth: .infinity, minHeight: 30)
                                .background(style.key, in: RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            HStack(spacing: 4) {
                Button { model.query.append(" ") } label: {
                    Text("Leerzeichen").font(.footnote).frame(maxWidth: .infinity, minHeight: 30)
                        .background(style.key, in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                SmallKey(symbol: "delete.left", style: style) { if !model.query.isEmpty { model.query.removeLast() } }
                SmallKey(text: String(localized: "Fertig"), style: style) { model.searching = false; model.query = "" }
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct SmallKey: View {
    var text: String?
    var symbol: String?
    let style: KeyStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let symbol { Image(systemName: symbol) } else { Text(text ?? "").font(.footnote) }
            }
            .frame(width: 64, height: 30)
            .background(style.function, in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}

private struct Chip: View {
    let label: String
    var symbol: String?
    let tint: Color
    let active: Bool
    let style: KeyStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let symbol { Image(systemName: symbol).font(.caption2) }
                Text(label).font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10).frame(height: 26)
            .foregroundStyle(active ? .white : .primary)
            .background(active ? tint : style.chip, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Taste im Systemstil; optional mit Dauerfeuer beim Halten (Löschen)
private struct KeyButton: View {
    let symbol: String
    let label: LocalizedStringKey
    let style: KeyStyle
    var repeats = false
    let action: () -> Void
    @State private var timer: Timer?

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17))
            .frame(width: 44, height: 38)
            .background(style.function, in: RoundedRectangle(cornerRadius: 8))
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
            Text("Einstellungen → Allgemein → Tastatur → Tastaturen → Ablage → **Vollen Zugriff erlauben**.\nNur so kann die Tastatur deinen Verlauf lesen.")
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
