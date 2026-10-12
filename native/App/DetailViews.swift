import SwiftUI

struct ClipDetailView: View {
    @EnvironmentObject var store: SharedStore
    @EnvironmentObject var toast: Toast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let clipId: String
    @State private var text = ""
    @State private var title = ""
    @State private var newBoard = false

    private var clip: Clip? { store.library.clips.first { $0.id == clipId } }

    var body: some View {
        NavigationStack {
            if let clip {
                Form {
                    Section {
                        HStack {
                            Label(clip.kind.label, systemImage: clip.kind.symbol).foregroundStyle(clip.kind.color)
                            Spacer()
                            Text("\(Detect.describe(clip)) · \(Detect.relative(clip.createdAt))").foregroundStyle(.secondary).font(.footnote)
                        }
                        TextField("Titel (optional)", text: $title)
                    }
                    Section {
                        switch clip.kind {
                        case .image:
                            if let url = store.url(for: clip.imageFile), let img = UIImage(contentsOfFile: url.path) {
                                Image(uiImage: img).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        case .file:
                            Label(clip.fileName ?? "Datei", systemImage: "doc")
                        default:
                            if clip.kind == .color, let c = Color(cssHex: clip.text ?? "") {
                                RoundedRectangle(cornerRadius: 10).fill(c).frame(height: 80)
                            }
                            TextEditor(text: $text)
                                .font(clip.kind == .code ? .system(.body, design: .monospaced) : .body)
                                .frame(minHeight: 160)
                        }
                    }
                    Section {
                        Button { Pasteboard.write(clip, store: store); toast.show("Kopiert") } label: { Label("Kopieren", systemImage: "doc.on.doc") }
                        if let item = shareItem(clip) {
                            ShareLink(item: item) { Label("Teilen", systemImage: "square.and.arrow.up") }
                        }
                        if let url = openTarget(clip) {
                            Button { openURL(url) } label: { Label("Öffnen", systemImage: "arrow.up.right.square") }
                        }
                        Toggle(isOn: Binding(get: { clip.isNote }, set: { v in store.mutate { $0.update(clip.id) { $0.isNote = v } } })) {
                            Label("Als Notiz behalten", systemImage: "pin")
                        }
                    }
                    Section("Pinnwände") {
                        ForEach(store.library.pinboards) { p in
                            Button { store.mutate { $0.togglePin(clip.id, p.id) } } label: {
                                HStack {
                                    Circle().fill(Color(hex: p.colorHex)).frame(width: 12, height: 12)
                                    Text(p.name).foregroundStyle(.primary)
                                    Spacer()
                                    if clip.pinboardIds.contains(p.id) { Image(systemName: "checkmark") }
                                }
                            }
                        }
                        Button { newBoard = true } label: { Label("Neue Pinnwand", systemImage: "plus") }
                    }
                    Section {
                        Button(role: .destructive) {
                            store.mutate { $0.delete(clip.id) }
                            dismiss()
                        } label: { Label("Löschen", systemImage: "trash") }
                    }
                }
                .navigationTitle(clip.title ?? clip.kind.label)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fertig") { save(clip); dismiss() }
                    }
                }
                .onAppear { text = clip.text ?? ""; title = clip.title ?? "" }
                .sheet(isPresented: $newBoard) { PinboardEditView(board: nil) }
            } else {
                ContentUnavailableView("Eintrag gelöscht", systemImage: "trash")
            }
        }
    }

    private func save(_ clip: Clip) {
        store.mutate { lib in
            if clip.kind != .image, clip.kind != .file, text != clip.text,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lib.editText(clip.id, text)
            }
            let t = title.trimmingCharacters(in: .whitespaces)
            lib.update(clip.id) { $0.title = t.isEmpty ? nil : t }
        }
    }

    private func shareItem(_ clip: Clip) -> URL? {
        switch clip.kind {
        case .image, .file: store.url(for: clip.imageFile)
        default: nil
        }
    }

    private func openTarget(_ clip: Clip) -> URL? {
        let t = (clip.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        switch clip.kind {
        case .link: return Detect.url(t)
        case .email: return URL(string: "mailto:\(t)")
        case .phone: return URL(string: "tel:\(t.filter { $0.isNumber || $0 == "+" })")
        default: return nil
        }
    }
}

/// Tab „Angepinnt“: Notizen und Pinnwände – genau das, was die Tastatur im zweiten Tab zeigt.
struct PinboardsView: View {
    @EnvironmentObject var store: SharedStore
    @State private var board: String?
    @State private var editing: Pinboard?
    @State private var creating = false
    @State private var newNote = false

    var body: some View {
        NavigationStack {
            let clips = store.library.filtered(pinboard: board, keptOnly: true)
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "Alle", symbol: nil, tint: .accentColor, active: board == nil) { board = nil }
                        ForEach(store.library.pinboards) { p in
                            FilterChip(label: p.name, symbol: nil, tint: Color(hex: p.colorHex), active: board == p.id) {
                                board = board == p.id ? nil : p.id
                            }
                            .contextMenu {
                                Button { editing = p } label: { Label("Bearbeiten", systemImage: "pencil") }
                                Button(role: .destructive) {
                                    if board == p.id { board = nil }
                                    store.mutate { $0.deletePinboard(p.id) }
                                } label: { Label("Löschen", systemImage: "trash") }
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                }
                if clips.isEmpty {
                    ContentUnavailableView("Noch nichts angepinnt", systemImage: "pin",
                        description: Text("Lege eine Notiz an oder hefte im Verlauf einen Eintrag an eine Pinnwand (Karte nach links wischen → Details)."))
                } else {
                    ClipListView(clips: clips)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Angepinnt")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { newNote = true } label: { Image(systemName: "square.and.pencil") }.accessibilityLabel("Neue Notiz")
                    Button { creating = true } label: { Image(systemName: "folder.badge.plus") }.accessibilityLabel("Neue Pinnwand")
                }
            }
            .sheet(isPresented: $creating) { PinboardEditView(board: nil) }
            .sheet(item: $editing) { PinboardEditView(board: $0) }
            .sheet(isPresented: $newNote) { NoteEditor() }
        }
    }
}

struct PinboardEditView: View {
    @EnvironmentObject var store: SharedStore
    @Environment(\.dismiss) private var dismiss
    let board: Pinboard?
    @State private var name = ""
    @State private var color = pinboardColors[0]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name, z. B. Arbeit", text: $name)
                Section("Farbe") {
                    HStack {
                        ForEach(pinboardColors, id: \.self) { c in
                            Circle().fill(Color(hex: c)).frame(width: 32, height: 32)
                                .overlay { if c == color { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white) } }
                                .onTapGesture { color = c }
                        }
                    }
                }
            }
            .navigationTitle(board == nil ? "Neue Pinnwand" : "Pinnwand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        store.mutate { lib in
                            if let board, let i = lib.pinboards.firstIndex(where: { $0.id == board.id }) {
                                lib.pinboards[i].name = n
                                lib.pinboards[i].colorHex = color
                            } else {
                                lib.pinboards.append(Pinboard(id: Library.newId(), name: n, colorHex: color, createdAt: Date()))
                            }
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = board?.name ?? ""
                color = board?.colorHex ?? pinboardColors[store.library.pinboards.count % pinboardColors.count]
            }
        }
        .presentationDetents([.medium])
    }
}
