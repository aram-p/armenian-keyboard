import SwiftUI
import UIKit

enum KeyboardMetrics {
    static let keyHeight: CGFloat = 44
    static let rowSpacing: CGFloat = 9
    static let keySpacing: CGFloat = 5
    static let sideMargin: CGFloat = 3
    static let topMargin: CGFloat = 8
    static let bottomMargin: CGFloat = 4
    static let rows: CGFloat = 5
    static var height: CGFloat { topMargin + rows * keyHeight + (rows - 1) * rowSpacing + bottomMargin }
    /// Widest row, in letter keys. Every key on a page has the same width.
    static let columns: CGFloat = 11
}

struct KeyboardView: View {
    @ObservedObject var state: KeyboardState
    let globe: (() -> UIView)?

    var body: some View {
        GeometryReader { geo in
            let unit = (geo.size.width - 2 * KeyboardMetrics.sideMargin - (KeyboardMetrics.columns - 1) * KeyboardMetrics.keySpacing) / KeyboardMetrics.columns
            VStack(spacing: KeyboardMetrics.rowSpacing) {
                switch state.page {
                case .letters: letterPage(unit: unit, width: geo.size.width)
                case .symbols: symbolPage(state.layout.symbolRows, unit: unit, width: geo.size.width, switchLabel: "#+=", switchTo: .moreSymbols)
                case .moreSymbols: symbolPage(state.layout.moreSymbolRows, unit: unit, width: geo.size.width, switchLabel: "123", switchTo: .symbols)
                }
                bottomRow
            }
            .padding(.horizontal, KeyboardMetrics.sideMargin)
            .padding(.top, KeyboardMetrics.topMargin)
            .padding(.bottom, KeyboardMetrics.bottomMargin)
        }
        .frame(height: KeyboardMetrics.height)
    }

    // MARK: Pages

    @ViewBuilder
    private func letterPage(unit: CGFloat, width: CGFloat) -> some View {
        let rows = state.layout.letterRows
        ForEach(0..<(rows.count - 1), id: \.self) { index in
            HStack(spacing: KeyboardMetrics.keySpacing) {
                ForEach(rows[index], id: \.self) { key in letterKey(key, unit: unit) }
            }
        }
        if let last = rows.last {
            let side = sideKeyWidth(letters: last.count, unit: unit, width: width)
            HStack(spacing: KeyboardMetrics.keySpacing) {
                shiftKey.frame(width: side)
                Spacer(minLength: 0)
                ForEach(last, id: \.self) { key in letterKey(key, unit: unit) }
                Spacer(minLength: 0)
                deleteKey.frame(width: side)
            }
        }
    }

    @ViewBuilder
    private func symbolPage(_ rows: [[String]], unit: CGFloat, width: CGFloat, switchLabel: String, switchTo: Page) -> some View {
        ForEach(0..<(rows.count - 1), id: \.self) { index in
            HStack(spacing: KeyboardMetrics.keySpacing) {
                ForEach(rows[index], id: \.self) { symbol in characterKey(symbol, unit: unit) }
            }
        }
        if let last = rows.last {
            let side = sideKeyWidth(letters: last.count, unit: unit, width: width)
            HStack(spacing: KeyboardMetrics.keySpacing) {
                KeyButton(style: .special, action: { state.page = switchTo }) {
                    Text(switchLabel).font(.system(size: 15)).lineLimit(1).minimumScaleFactor(0.6)
                }
                .frame(width: side)
                Spacer(minLength: 0)
                ForEach(last, id: \.self) { symbol in characterKey(symbol, unit: unit) }
                Spacer(minLength: 0)
                deleteKey.frame(width: side)
            }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: KeyboardMetrics.keySpacing) {
            KeyButton(style: .special, action: { state.page = state.page == .letters ? .symbols : .letters }) {
                Text(state.page == .letters ? "123" : "ԱԲԳ").font(.system(size: 16))
            }
            .frame(width: 48)
            .accessibilityLabel(state.page == .letters ? "Numbers and punctuation" : "Letters")
            if let globe {
                KeyButton(style: .special, action: {}) { GlobeView(make: globe) }
                    .frame(width: 40)
            }
            if state.page == .letters {
                characterKey(state.layout.spaceLeft, unit: 30)
            }
            KeyButton(style: .letter, action: { state.space() }) {
                Text(state.layout.spaceLabel)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Space")
            if state.page == .letters {
                characterKey(state.layout.spaceRight, unit: 30)
            }
            KeyButton(style: .special, action: { state.newline() }) {
                Text(state.returnLabel).font(.system(size: 16))
            }
            .frame(width: 80)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: Keys

    private func letterKey(_ key: LetterKey, unit: CGFloat) -> some View {
        KeyButton(style: .letter, action: { state.type(key) }) {
            Text(state.isUpper ? key.upper : key.lower).font(.system(size: 22))
        }
        .frame(width: unit)
        .accessibilityLabel(state.isUpper ? key.upper : key.lower)
    }

    private func characterKey(_ symbol: String, unit: CGFloat) -> some View {
        KeyButton(style: .letter, action: { state.type(symbol) }) {
            Text(symbol).font(.system(size: 22))
        }
        .frame(width: unit)
        .accessibilityLabel(symbol)
    }

    private var shiftKey: some View {
        KeyButton(style: state.shift == .off ? .special : .active, action: { state.tapShift() }) {
            Image(systemName: state.shift == .locked ? "capslock.fill" : (state.shift == .once ? "shift.fill" : "shift"))
                .font(.system(size: 18, weight: .medium))
        }
        .accessibilityLabel(state.shift == .locked ? "Caps lock" : "Shift")
    }

    private var deleteKey: some View {
        KeyButton(style: .special, onPress: { state.startDelete() }, onRelease: { state.stopDelete() }) {
            Image(systemName: "delete.left").font(.system(size: 18, weight: .medium))
        }
        .accessibilityLabel("Delete")
    }

    private func sideKeyWidth(letters: Int, unit: CGFloat, width: CGFloat) -> CGFloat {
        let inner = width - 2 * KeyboardMetrics.sideMargin
        // Two side keys, two spacers and the keys between them: letters + 3 gaps.
        let used = CGFloat(letters) * unit + CGFloat(letters + 3) * KeyboardMetrics.keySpacing
        return min(unit * 1.6, (inner - used) / 2)
    }
}

// MARK: - Key

enum KeyStyle { case letter, special, active }

struct KeyButton<Label: View>: View {
    let style: KeyStyle
    var action: () -> Void = {}
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?
    @ViewBuilder var label: () -> Label
    @Environment(\.colorScheme) private var scheme
    @State private var pressed = false

    init(style: KeyStyle, action: @escaping () -> Void = {}, onPress: (() -> Void)? = nil, onRelease: (() -> Void)? = nil, @ViewBuilder label: @escaping () -> Label) {
        self.style = style
        self.action = action
        self.onPress = onPress
        self.onRelease = onRelease
        self.label = label
    }

    var body: some View {
        label()
            .foregroundStyle(style == .active || scheme == .light ? Color.black : Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fill)
                    .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.3), radius: 0, x: 0, y: 1)
            )
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            onPress?()
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        if let onRelease { onRelease() } else { action() }
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { if let onPress { onPress(); onRelease?() } else { action() } }
    }

    private var fill: Color {
        let dark = scheme == .dark
        switch (style, pressed) {
        case (.letter, false): return dark ? Color(white: 0.42) : .white
        case (.letter, true): return dark ? Color(white: 0.30) : Color(red: 0.67, green: 0.69, blue: 0.73)
        case (.special, false): return dark ? Color(white: 0.27) : Color(red: 0.67, green: 0.69, blue: 0.73)
        case (.special, true): return dark ? Color(white: 0.42) : .white
        case (.active, _): return dark ? Color(white: 0.85) : .white
        }
    }
}

/// Hosts the UIKit globe button, which must receive the raw touch events.
struct GlobeView: UIViewRepresentable {
    let make: () -> UIView
    func makeUIView(context: Context) -> UIView { make() }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
