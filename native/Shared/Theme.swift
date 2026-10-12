import SwiftUI

extension ClipKind {
    var color: Color {
        switch self {
        case .text: Color(hex: "#3D7BFD")
        case .link: Color(hex: "#2FB36B")
        case .image: Color(hex: "#9B5CF6")
        case .color: Color(hex: "#F59E0B")
        case .email: Color(hex: "#14B8A6")
        case .phone: Color(hex: "#EC4899")
        case .code: Color(hex: "#64748B")
        case .file: Color(hex: "#E5484D")
        }
    }

    /// SF Symbols im Linien-Stil (keine Emoji)
    var symbol: String {
        switch self {
        case .text: "text.alignleft"
        case .link: "link"
        case .image: "photo"
        case .color: "drop"
        case .email: "envelope"
        case .phone: "phone"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .file: "doc"
        }
    }
}

let pinboardColors = ["#E5484D", "#F59E0B", "#2FB36B", "#14B8A6", "#3D7BFD", "#9B5CF6", "#EC4899", "#64748B"]

extension Color {
    /// #RGB, #RRGGBB, #RRGGBBAA; sonst nil
    init?(cssHex raw: String) {
        var s = raw.trimmingCharacters(in: .whitespaces)
        guard s.hasPrefix("#") else { return nil }
        s.removeFirst()
        if s.count == 3 || s.count == 4 { s = s.map { "\($0)\($0)" }.joined() }
        guard s.count == 6 || s.count == 8, let v = UInt64(s, radix: 16) else { return nil }
        let a = s.count == 8 ? Double(v & 0xFF) / 255 : 1
        let rgb = s.count == 8 ? v >> 8 : v
        self.init(.sRGB, red: Double((rgb >> 16) & 0xFF) / 255, green: Double((rgb >> 8) & 0xFF) / 255,
                  blue: Double(rgb & 0xFF) / 255, opacity: a)
    }

    init(hex: String) { self = Color(cssHex: hex) ?? .gray }
}

/// Kartenkopf + Inhalt, gemeinsam für App-Liste und Tastatur
struct ClipCardView: View {
    let clip: Clip
    let store: SharedStore
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: clip.kind.symbol).font(.caption.weight(.semibold))
                Text(clip.title ?? clip.kind.label).font(.caption.weight(.semibold)).lineLimit(1)
                Spacer(minLength: 4)
                Text(Detect.relative(clip.usedAt)).font(.caption2).opacity(0.85).lineLimit(1).fixedSize()
                if clip.isKept { Image(systemName: "pin.fill").font(.caption2) }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(clip.kind.color)

            content
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: compact ? .infinity : nil, alignment: .topLeading)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder private var content: some View {
        switch clip.kind {
        case .image:
            if let url = store.url(for: clip.thumbFile ?? clip.imageFile), let img = UIImage(contentsOfFile: url.path) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: compact ? 90 : 160, maxHeight: compact ? .infinity : 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        case .color:
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8).fill(Color(cssHex: clip.text ?? "") ?? .gray)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                Text(clip.text ?? "").font(.system(.footnote, design: .monospaced))
            }
        case .link:
            VStack(alignment: .leading, spacing: 2) {
                Text(Detect.domain(clip.text ?? "")).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(clip.text ?? "").font(.caption).foregroundStyle(ClipKind.link.color).lineLimit(compact ? 3 : 2)
            }
        case .code:
            Text(clip.text ?? "").font(.system(.caption, design: .monospaced)).lineLimit(compact ? 6 : 8)
        case .file:
            Label(clip.fileName ?? "Datei", systemImage: "doc").font(.subheadline)
        default:
            Text(clip.text ?? "").font(compact ? .footnote : .subheadline).lineLimit(compact ? 6 : 6)
        }
    }
}
