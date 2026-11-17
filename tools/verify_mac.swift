// Checks that macOS itself accepts the installed layout and that every key,
// on every modifier layer, types exactly what layouts/*.toml says.
//
// Usage: verify_mac <installed .keylayout or .bundle> <expected.json> [input source id]
//
// It registers the file with the Text Input Sources service (the same thing
// macOS does at login) and reads the layout back through UCKeyTranslate.
// It never enables or selects the input source. macOS only picks up a new
// .bundle at the next login, so tools/test_mac.sh tests a loose .keylayout copy.
import Carbon
import Foundation

struct Case: Decodable { let key: String; let code: UInt16; let layer: String; let text: String }
struct Expected: Decodable { let source_id: String; let cases: [Case] }

let modifierBits: [String: UInt32] = [
    "plain": 0, "shift": UInt32(shiftKey >> 8), "caps": UInt32(alphaLock >> 8),
    "option": UInt32(optionKey >> 8), "option_shift": UInt32((optionKey | shiftKey) >> 8),
    "command": UInt32(cmdKey >> 8), "control": UInt32(controlKey >> 8),
]

func property(_ source: TISInputSource, _ key: CFString) -> AnyObject? {
    guard let raw = TISGetInputSourceProperty(source, key) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(raw).takeUnretainedValue()
}

let args = CommandLine.arguments.dropFirst()
guard let bundlePath = args.first, args.count >= 2 else {
    print("usage: verify_mac <keylayout or bundle> <expected.json> [input source id]"); exit(2)
}
let sourceOverride: String? = args.count >= 3 ? Array(args)[2] : nil
let status = TISRegisterInputSource(URL(fileURLWithPath: bundlePath) as CFURL)
if status != noErr { print("TISRegisterInputSource failed: \(status)"); exit(1) }

var failures = 0
for file in [Array(args)[1]] {
    let expected = try! JSONDecoder().decode(Expected.self, from: Data(contentsOf: URL(fileURLWithPath: file)))
    let filter = [kTISPropertyInputSourceID as String: sourceOverride ?? expected.source_id] as CFDictionary
    // Registration takes a few seconds to show up.
    var sources: [TISInputSource] = []
    for _ in 0..<30 where sources.isEmpty {
        sources = (TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource]) ?? []
        if sources.isEmpty { RunLoop.current.run(until: Date().addingTimeInterval(0.5)) }
    }
    guard let source = sources.first else {
        print("FAIL \(sourceOverride ?? expected.source_id): macOS does not list this input source"); failures += 1; continue
    }
    let name = property(source, kTISPropertyLocalizedName) as? String ?? "?"
    let enabled = (property(source, kTISPropertyInputSourceIsEnabled) as? Bool) ?? false
    print("listed: \(sourceOverride ?? expected.source_id) “\(name)” enabled=\(enabled)")
    guard let data = property(source, kTISPropertyUnicodeKeyLayoutData) as? Data else {
        print("FAIL \(expected.source_id): no key layout data (macOS rejected the .keylayout)"); failures += 1; continue
    }
    var checked = 0
    data.withUnsafeBytes { raw in
        let layout = raw.baseAddress!.assumingMemoryBound(to: UCKeyboardLayout.self)
        for c in expected.cases {
            var dead: UInt32 = 0
            var length = 0
            var buffer = [UniChar](repeating: 0, count: 8)
            let err = UCKeyTranslate(layout, c.code, UInt16(kUCKeyActionDown), modifierBits[c.layer]!,
                                     UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit),
                                     &dead, buffer.count, &length, &buffer)
            let got = String(utf16CodeUnits: buffer, count: length)
            checked += 1
            if err != noErr || got != c.text {
                failures += 1
                let show = { (s: String) in s.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " ") }
                print("FAIL key \(c.key) (\(c.code)) \(c.layer): expected \(show(c.text)) got \(show(got)) err=\(err)")
            }
        }
    }
    print("\(expected.source_id): checked \(checked) key/modifier combinations")
}
print(failures == 0 ? "OK" : "\(failures) failure(s)")
exit(failures == 0 ? 0 : 1)
