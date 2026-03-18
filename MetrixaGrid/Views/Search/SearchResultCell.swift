import SwiftUI

struct SearchResultCell: View {
    let result: SearchResult
    let query: String
    let projectName: String    // only populated for .measurement results

    var body: some View {
        HStack(spacing: 14) {
            iconView
            VStack(alignment: .leading, spacing: 3) {
                titleView
                subtitleView
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textTertiary)
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Icon

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconColor.opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
        }
    }

    private var iconName: String {
        switch result.kind {
        case .measurement: return "ruler"
        case .project:     return "folder"
        case .recent(let e): return e.type.icon
        }
    }

    private var iconColor: Color {
        switch result.kind {
        case .measurement: return .accentCyan
        case .project:     return .accentMint
        case .recent(let e): return e.type.color
        }
    }

    // MARK: - Title (with highlights)

    @ViewBuilder
    private var titleView: some View {
        switch result.kind {
        case .measurement(let m):
            HighlightedText(text: m.title, query: query)
        case .project(let p):
            HighlightedText(text: p.name, query: query)
        case .recent(let e):
            Text(e.title)
                .font(AppFont.standard(14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }

    // MARK: - Subtitle

    @ViewBuilder
    private var subtitleView: some View {
        switch result.kind {
        case .measurement(let m):
            HStack(spacing: 4) {
                Text(m.fullDisplay)
                    .foregroundColor(.textSecondary)
                if !projectName.isEmpty {
                    Text("·")
                        .foregroundColor(.textTertiary)
                    Text(projectName)
                        .foregroundColor(.accentCyan)
                }
            }
            .font(AppFont.standard(11))
            .lineLimit(1)

        case .project(let p):
            Text(p.description.isEmpty ? "No description" : p.description)
                .font(AppFont.standard(11))
                .foregroundColor(.textSecondary)
                .lineLimit(1)

        case .recent(let e):
            Text(e.detail)
                .font(AppFont.standard(11))
                .foregroundColor(.textSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Highlighted Text

/// Renders text with query matches highlighted in accent cyan + bold.
struct HighlightedText: View {
    let text: String
    let query: String

    var body: some View {
        buildText()
            .font(AppFont.standard(14, weight: .medium))
            .lineLimit(1)
    }

    private func buildText() -> Text {
        guard !query.isEmpty else {
            return Text(text).foregroundColor(.white)
        }
        let nsText = text as NSString
        var composite = Text("")
        var lastEnd = 0

        var searchRange = NSRange(location: 0, length: nsText.length)
        while searchRange.location < nsText.length {
            let found = nsText.range(of: query, options: .caseInsensitive, range: searchRange)
            guard found.location != NSNotFound else { break }

            // Text before match
            let preRange = NSRange(location: lastEnd, length: found.location - lastEnd)
            if preRange.length > 0 {
                let pre = nsText.substring(with: preRange)
                composite = composite + Text(pre).foregroundColor(.white)
            }

            // Matched text
            let matchStr = nsText.substring(with: found)
            composite = composite + Text(matchStr).foregroundColor(.accentCyan).bold()

            lastEnd = found.location + found.length
            let newLoc = lastEnd
            let newLen = nsText.length - newLoc
            if newLen <= 0 { break }
            searchRange = NSRange(location: newLoc, length: newLen)
        }

        // Remaining tail
        if lastEnd < nsText.length {
            let tail = nsText.substring(from: lastEnd)
            composite = composite + Text(tail).foregroundColor(.white)
        }

        return composite
    }
}
