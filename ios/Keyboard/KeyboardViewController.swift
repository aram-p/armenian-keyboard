import SwiftUI
import UIKit

final class KeyboardViewController: UIInputViewController, KeyboardHost {
    private lazy var state = KeyboardState(layout: Layouts.all[0])
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        state.host = self
        let root = KeyboardView(state: state, globe: needsInputModeSwitchKey ? makeGlobeButton : nil)
        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hosting)
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
        let height = view.heightAnchor.constraint(equalToConstant: KeyboardMetrics.height)
        height.priority = .defaultHigh
        height.isActive = true
        heightConstraint = height
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshFromHost()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refreshFromHost()
    }

    private func refreshFromHost() {
        state.returnLabel = Self.returnLabel(for: textDocumentProxy.returnKeyType ?? .default)
        state.updateAutoShift()
    }

    /// The system globe button: tap switches keyboards, long press shows the list.
    private func makeGlobeButton() -> UIView {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "globe"), for: .normal)
        button.tintColor = .label
        button.accessibilityLabel = "Next keyboard"
        button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        return button
    }

    private static func returnLabel(for type: UIReturnKeyType) -> String {
        switch type {
        case .go: return "go"
        case .search, .google, .yahoo: return "search"
        case .send: return "send"
        case .next: return "next"
        case .done: return "done"
        case .join: return "join"
        case .route: return "route"
        default: return "return"
        }
    }

    // MARK: KeyboardHost

    var textBeforeCursor: String { textDocumentProxy.documentContextBeforeInput ?? "" }

    var wantsAutoCapitalization: Bool {
        let type = textDocumentProxy.autocapitalizationType ?? .sentences
        return type == .sentences || type == .words || type == .allCharacters
    }

    func insert(_ text: String) { textDocumentProxy.insertText(text) }

    func deleteBackward() { textDocumentProxy.deleteBackward() }
}
