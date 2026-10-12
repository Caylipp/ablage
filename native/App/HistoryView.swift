import SwiftUI

/// Liste von Karten mit Kopieren beim Antippen, Kontextmenü und Wischen zum Löschen.
struct ClipListView: View {
    @EnvironmentObject var store: SharedStore
    @EnvironmentObject var toast: Toast
    let clips: [Clip]
    @State private var detail: Clip?

    var body: some View {
        List {
            ForEach(clips) { clip in
                ClipCardView(clip: clip, store: store)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Pasteboard.write(clip, store: store)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        toast.show("Kopiert")
                    }
                    .contextMenu {
                        Button { detail = clip } label: { Label("Details", systemImage: "info.circle") }
                        Button(role: .destructive) { store.mutate { $0.delete(clip.id) } } label: { Label("Löschen", systemImage: "trash") }
                    }
                    .swipeActions {
                        Button(role: .destructive) { store.mutate { $0.delete(clip.id) } } label: { Label("Löschen", systemImage: "trash") }
                        Button { detail = clip } label: { Label("Details", systemImage: "ellipsis") }.tint(.gray)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            }
        }
        .listStyle(.plain)
        .sheet(item: $detail) { ClipDetailView(clipId: $0.id) }
    }
}

struct HistoryView: View {
    @EnvironmentObject var store: SharedStore
    @EnvironmentObject var toast: Toast
    @State private var query = ""
    @State private var kind: ClipKind?
    @State private var newNote = false

    var body: some View {
        NavigationStack {
            let clips = store.library.filtered(query: query, kind: kind)
            VStack(spacing: 0) {
                kindChips
                if clips.isEmpty {
                    ContentUnavailableView(
                        query.isEmpty && kind == nil ? "Noch nichts kopiert" : "Nichts gefunden",
                        systemImage: query.isEmpty && kind == nil ? "doc.on.clipboard" : "magnifyingglass",
                        description: Text(query.isEmpty && kind == nil
                            ? "Kopiere etwas und öffne die Ablage-Tastatur – oder diese App."
                            : "Andere Suche oder anderen Filter probieren."))
                } else {
                    ClipListView(clips: clips)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Verlauf")
            .searchable(text: $query, prompt: "Verlauf durchsuchen")
            .refreshable { captureManually() }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { newNote = true } label: { Image(systemName: "square.and.pencil") }
                        .accessibilityLabel("Neue Notiz")
                    // PasteButton: Systemknopf, liest ohne „Einsetzen erlauben?“-Dialog
                    PasteButton(payloadType: String.self) { strings in
                        guard let s = strings.first else { return }
                        DispatchQueue.main.async {
                            let (_, isNew) = store.mutate { $0.add($0.textClip(s)) }
                            toast.show(isNew ? "Eingefügt" : "Schon vorhanden – nach oben geholt")
                        }
                    }
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.capsule)
                }
            }
            .sheet(isPresented: $newNote) { NoteEditor() }
        }
    }

    private func captureManually() {
        switch Pasteboard.capture(into: store, force: true) {
        case .added: toast.show("Eingefügt")
        case .moved: toast.show("Schon vorhanden – nach oben geholt")
        case .empty: toast.show("Zwischenablage ist leer")
        default: toast.show("Nichts Neues")
        }
    }

    private var kindChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "Alle", symbol: nil, tint: .accentColor, active: kind == nil) { kind = nil }
                let present = Set(store.library.clips.map(\.kind))
                ForEach(ClipKind.allCases.filter(present.contains)) { k in
                    FilterChip(label: k.label, symbol: k.symbol, tint: k.color, active: kind == k) { kind = kind == k ? nil : k }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
    }
}

struct FilterChip: View {
    let label: String
    let symbol: String?
    let tint: Color
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let symbol { Image(systemName: symbol).font(.caption) }
                Text(label).font(.footnote.weight(.semibold))
            }
            .padding(.horizontal, 12).frame(height: 30)
            .foregroundStyle(active ? .white : .primary)
            .background(active ? tint : Color(uiColor: .tertiarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

struct NoteEditor: View {
    @EnvironmentObject var store: SharedStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("Titel (optional)", text: $title)
                Section {
                    TextEditor(text: $text).frame(minHeight: 200).focused($focused)
                } footer: {
                    PlaceholderBar(text: $text)
                }
            }
            .navigationTitle("Neue Notiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        store.mutate { lib in
                            let (id, _) = lib.add(.init(kind: Detect.kind(text), text: text, hash: Detect.hash(text), isNote: true))
                            let t = title.trimmingCharacters(in: .whitespaces)
                            if !t.isEmpty { lib.update(id) { $0.title = t } }
                        }
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { focused = true }
        }
    }
}

/// Platzhalter für Bausteine einfügen – werden beim Einsetzen/Kopieren ersetzt
struct PlaceholderBar: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Platzhalter für Bausteine – werden beim Einsetzen ersetzt:")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Templates.placeholders, id: \.self) { p in
                        Button(p) { text += p }
                            .font(.caption.monospaced())
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
}
