/// One letter key: what it types without and with Shift.
struct LetterKey: Hashable {
    let lower: String
    let upper: String

    init(_ lower: String, _ upper: String) {
        self.lower = lower
        self.upper = upper
    }
}

/// A touch layout, generated from layouts/*.toml by tools/build.py.
struct KeyboardLayout {
    let id: String
    let name: String
    let shortName: String
    let letterRows: [[LetterKey]]
    let symbolRows: [[String]]
    let moreSymbolRows: [[String]]
    let spaceLabel: String
    let spaceLeft: String
    let spaceRight: String
    let doubleSpace: String
    let sentenceEnders: [String]
}
