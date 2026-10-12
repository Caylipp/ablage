import SwiftUI
import WidgetKit

@main
struct AblageWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecentWidget()
        OpenAblageControl()
    }
}

// MARK: Zuletzt-Widget

struct RecentEntry: TimelineEntry {
    let date: Date
    let clips: [Clip]
}

struct RecentProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentEntry {
        RecentEntry(date: Date(), clips: [Clip(id: "x", kind: .text, text: String(localized: "Zuletzt kopierter Text"), hash: "x",
                                                createdAt: Date(), usedAt: Date())])
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentEntry>) -> Void) {
        // Aktualisiert wird vor allem per reloadAllTimelines aus App/Tastatur; sonst alle 30 Minuten
        completion(Timeline(entries: [entry()], policy: .after(Date().addingTimeInterval(1800))))
    }

    private func entry() -> RecentEntry {
        RecentEntry(date: Date(), clips: Array(SharedStore().library.filtered().prefix(6)))
    }
}

struct RecentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.philipphoang.ablage.recent", provider: RecentProvider()) { entry in
            RecentWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Ablage – Zuletzt")
        .description("Deine zuletzt kopierten Einträge. Antippen kopiert.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

private func copyURL(_ clip: Clip) -> URL { URL(string: "ablage://copy?id=\(clip.id)")! }

private func summary(_ clip: Clip) -> String {
    clip.title ?? clip.linkTitle ?? clip.text ?? clip.fileName ?? clip.kind.label
}

struct RecentWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RecentEntry

    var body: some View {
        if entry.clips.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "doc.on.clipboard").font(.title2)
                Text("Noch nichts kopiert").font(.caption)
            }
            .foregroundStyle(.secondary)
        } else {
            switch family {
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Label(entry.clips[0].kind.label, systemImage: entry.clips[0].kind.symbol).font(.caption2.weight(.semibold))
                    Text(summary(entry.clips[0])).font(.caption).lineLimit(2)
                }
                .widgetURL(copyURL(entry.clips[0]))
            case .systemSmall:
                SmallCard(clip: entry.clips[0]).widgetURL(copyURL(entry.clips[0]))
            default:
                let n = family == .systemLarge ? 6 : 3
                VStack(alignment: .leading, spacing: 6) {
                    Label("Zuletzt", systemImage: "doc.on.clipboard").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    ForEach(entry.clips.prefix(n)) { clip in
                        Link(destination: copyURL(clip)) { Row(clip: clip) }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

private struct SmallCard: View {
    let clip: Clip
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(clip.kind.label, systemImage: clip.kind.symbol)
                .font(.caption2.weight(.bold)).foregroundStyle(clip.kind.color)
            Text(summary(clip)).font(.footnote).lineLimit(5)
            Spacer(minLength: 0)
            Text(Detect.relative(clip.usedAt)).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Row: View {
    let clip: Clip
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: clip.kind.symbol).font(.caption).foregroundStyle(.white)
                .frame(width: 24, height: 24).background(clip.kind.color, in: RoundedRectangle(cornerRadius: 6))
            Text(summary(clip)).font(.footnote).lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "doc.on.doc").font(.caption2).foregroundStyle(.secondary)
        }
    }
}

// MARK: Steuerzentrale

struct OpenAblageControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.philipphoang.ablage.open") {
            ControlWidgetButton(action: OpenAblageIntent()) {
                Label("Ablage", systemImage: "doc.on.clipboard")
            }
        }
        .displayName("Ablage öffnen")
        .description("Öffnet Ablage und sichert die Zwischenablage.")
    }
}
