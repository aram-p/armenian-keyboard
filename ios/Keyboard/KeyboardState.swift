import Foundation
import UIKit

enum ShiftState {
    case off, once, locked
}

enum Page {
    case letters, symbols, moreSymbols
}

/// What the keyboard needs from the host text field.
protocol KeyboardHost: AnyObject {
    var textBeforeCursor: String { get }
    var wantsAutoCapitalization: Bool { get }
    func insert(_ text: String)
    func deleteBackward()
}

/// Shift, page and typing rules. Kept free of UIKit views so it is easy to reason about.
final class KeyboardState: ObservableObject {
    @Published var shift: ShiftState = .off
    @Published var page: Page = .letters
    @Published var returnLabel = "return"

    let layout: KeyboardLayout
    weak var host: KeyboardHost?
    private var lastShiftTap = Date.distantPast
    private var lastSpace = Date.distantPast
    private var deleteTimer: Timer?

    init(layout: KeyboardLayout) {
        self.layout = layout
    }

    var isUpper: Bool { shift != .off }

    func type(_ key: LetterKey) {
        host?.insert(isUpper ? key.upper : key.lower)
        if shift == .once { shift = .off }
    }

    func type(_ text: String) {
        host?.insert(text)
        updateAutoShift()
    }

    func tapShift() {
        let now = Date()
        switch shift {
        case .off:
            shift = .once
        case .once:
            shift = now.timeIntervalSince(lastShiftTap) < 0.35 ? .locked : .off
        case .locked:
            shift = .off
        }
        lastShiftTap = now
    }

    func space() {
        guard let host else { return }
        let before = host.textBeforeCursor
        let now = Date()
        // A quick double space ends the sentence, like on the system keyboard.
        if now.timeIntervalSince(lastSpace) < 0.6, before.hasSuffix(" "),
           let previous = before.dropLast().last, previous.isLetter || previous.isNumber {
            host.deleteBackward()
            host.insert(layout.doubleSpace)
            lastSpace = .distantPast
        } else {
            host.insert(" ")
            lastSpace = now
        }
        updateAutoShift()
    }

    func newline() {
        host?.insert("\n")
        updateAutoShift()
    }

    func startDelete() {
        deleteOnce()
        deleteTimer?.invalidate()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
            self?.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
                self?.deleteOnce()
            }
        }
    }

    func stopDelete() {
        deleteTimer?.invalidate()
        deleteTimer = nil
        updateAutoShift()
    }

    private func deleteOnce() {
        host?.deleteBackward()
    }

    /// Capitalise the first letter of a sentence when the text field asks for it.
    func updateAutoShift() {
        guard shift != .locked, let host else { return }
        guard host.wantsAutoCapitalization else {
            if shift == .once { shift = .off }
            return
        }
        let before = host.textBeforeCursor
        let trimmed = before.trimmingCharacters(in: .whitespaces)
        let atSentenceStart = trimmed.isEmpty
            || before.hasSuffix("\n")
            || (before.hasSuffix(" ") && layout.sentenceEnders.contains { trimmed.hasSuffix($0) })
        shift = atSentenceStart ? .once : .off
    }
}
