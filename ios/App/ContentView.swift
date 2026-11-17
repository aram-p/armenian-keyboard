import SwiftUI
import UIKit

struct ContentView: View {
    @State private var text = ""
    @FocusState private var typing: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Type here to try the keyboard", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .focused($typing)
                        .font(.title3)
                } header: {
                    Text("Try it")
                } footer: {
                    Text("Tap the globe key to switch to “Armenian Phonetic”.")
                }

                Section("Turn it on") {
                    Step(number: 1, text: "Open Settings → General → Keyboard → Keyboards.")
                    Step(number: 2, text: "Tap “Add New Keyboard…” and choose “Հայերեն” (Armenian Phonetic).")
                    Step(number: 3, text: "In any app, tap the globe key to switch to it.")
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                }

                Section("Where things are") {
                    Fact(symbol: "character.textbox", text: "Letters sit on the English keys that sound the same: ա on A, բ on B, ք on Q, ռ on R.")
                    Fact(symbol: "textformat.123", text: "Tap 123 for numbers. Armenian punctuation comes first: ։ ՝ ՛ ՞ ՜ « » և.")
                    Fact(symbol: "space", text: "Two quick spaces end the sentence with ։ and the next letter is capitalised.")
                }

                Section("Privacy") {
                    Fact(symbol: "lock.shield", text: "The keyboard does not ask for Full Access. It has no network access and collects nothing; everything you type stays in the app you type into.")
                }
            }
            .navigationTitle("Armenian Keyboard")
        }
    }
}

private struct Step: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.accentColor))
            Text(text)
        }
    }
}

private struct Fact: View {
    let symbol: String
    let text: String

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol).foregroundStyle(Color.accentColor)
        }
    }
}

#Preview {
    ContentView()
}
