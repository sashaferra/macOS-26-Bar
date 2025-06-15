import SwiftUI
import AppKit
import Alamofire
import JavaScriptCore

struct TranslateBar: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var sourceLang: String = "en"
    @State private var targetLang: String = "ja"
    @State private var status: String = ""

    let languages: [String: String] = [
        "en": "English",
        "ja": "Japanese",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "ru": "Russian",
        "zh": "Chinese"
    ]

    var body: some View {
        LiquidGlassStyle {
            VStack(spacing: 12) {
                HStack {
                    Picker("From", selection: $sourceLang) {
                        ForEach(languages.keys.sorted(), id: \.self) { code in
                            Text(languages[code] ?? code).tag(code)
                        }
                    }
                    .labelsHidden()

                    Button(action: {
                        let oldSource = sourceLang
                        sourceLang = targetLang
                        targetLang = oldSource

                        let tempInput = inputText
                        inputText = outputText
                        outputText = tempInput
                    }) {
                        Image(systemName: "arrow.left.arrow.right")
                            .padding(.horizontal)
                    }

                    Picker("To", selection: $targetLang) {
                        ForEach(languages.keys.sorted(), id: \.self) { code in
                            Text(languages[code] ?? code).tag(code)
                        }
                    }
                    .labelsHidden()
                }
                .padding(6)
                .background(.ultraThinMaterial)

                TextEditor(text: $inputText)
                    .frame(height: 80)
                    .padding(6)
                    .background(.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onChange(of: inputText) { oldValue, newValue in
                        if newValue.hasSuffix("\n") {
                            inputText = newValue.trimmingCharacters(in: .newlines)
                            translateText()
                        }
                    }

                TextEditor(text: .constant(outputText))
                    .frame(height: 80)
                    .padding(6)
                    .background(.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(true)

                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 360, height: 320)
        }
    }

    @MainActor
    func translateText() {
        let cleanInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanInput.isEmpty else {
            status = "⚠️ Input is empty"
            return
        }

        let apiKey = ["p7J9xQl", "mA2KzDf", "8R3nbVo", "q5WzLxT", "tHg9MdNs"].joined()
        let urlString = "https://translation.googleapis.com/language/translate/v2"
        print("🔗 Requesting: \(urlString)")

        let parameters: [String: String] = [
            "q": cleanInput,
            "source": sourceLang,
            "target": targetLang,
            "format": "text",
            "key": apiKey
        ]
        print("🧾 Parameters: \(parameters)")

        status = "🌐 Translating..."

        AF.request(urlString, method: .get, parameters: parameters)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    Task { @MainActor in
                        do {
                            let decoded = try JSONDecoder().decode(GoogleTranslateResponse.self, from: data)
                            let result = decoded.data.translations.first?.translatedText ?? ""
                            outputText = result.isEmpty ? inputText : result
                            if targetLang == "ja" {
                                let romaji = convertToRomaji(result)
                                outputText += "\n(\(romaji))"
                            }
                            status = result.isEmpty ? "❓ No translation found, original text copied" : "✅ Translated"
                        } catch {
                            status = "❌ Decode error: \(error.localizedDescription)"
                            print("📦 Raw data: \(String(data: data, encoding: .utf8) ?? "unreadable")")
                        }
                    }
                case .failure(let error):
                    status = "❌ Error: \(error.localizedDescription)"
                    if let data = response.data {
                        print("📦 Response body: \(String(data: data, encoding: .utf8) ?? "n/a")")
                    }
                }
            }
    }

    func convertToRomaji(_ text: String) -> String {
        return RomajiConverter.shared.convert(text)
    }

}


class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Show visible alert at launch
        let alert = NSAlert()
        alert.messageText = "TranslateBar is alive 👻"
        alert.informativeText = "The app launched, even if the globe is shy."
        alert.alertStyle = .informational
        alert.runModal()

        NSApp.setActivationPolicy(.accessory)
        print("💥 AppDelegate launched")
        print("🧠 Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let view = TranslateBar()

            self.popover = NSPopover()
            self.popover.contentSize = NSSize(width: 360, height: 320)
            self.popover.behavior = .transient
            self.popover.contentViewController = NSViewController()
            self.popover.contentViewController?.view = NSHostingView(rootView: view)

            self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = self.statusItem.button {
                print("✅ Status item button initialized: \(String(describing: button))")
                button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Translator")
                button.action = #selector(self.togglePopover(_:))
                button.target = self
            }
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @objc func handleTranslate() {
        print("🌍 Translate menu item clicked")
    }
}

struct LiquidGlassStyle<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            GlassEffectView()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            content
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.025), radius: 3, x: 0, y: 2)
        }
    }
}

struct GlassEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        if #available(macOS 26.0, *) {
            return NSGlassEffectView()
        } else {
            return NSVisualEffectView()
        }
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class RomajiConverter {
    static let shared = RomajiConverter()
    private let context = JSContext()

    init() {
        let js = """
        var tokenizer;
        var ready = false;

        function getReading(text) {
            var tokens = tokenizer.tokenize(text);
            var reading = "";
            for (var i = 0; i < tokens.length; i++) {
                reading += tokens[i].reading || tokens[i].surface_form;
            }
            return reading;
        }

        function katakanaToRomaji(input) {
            const map = {
                'ア':'a','イ':'i','ウ':'u','エ':'e','オ':'o',
                'カ':'ka','キ':'ki','ク':'ku','ケ':'ke','コ':'ko',
                'サ':'sa','シ':'shi','ス':'su','セ':'se','ソ':'so',
                'タ':'ta','チ':'chi','ツ':'tsu','テ':'te','ト':'to',
                'ナ':'na','ニ':'ni','ヌ':'nu','ネ':'ne','ノ':'no',
                'ハ':'ha','ヒ':'hi','フ':'fu','ヘ':'he','ホ':'ho',
                'マ':'ma','ミ':'mi','ム':'mu','メ':'me','モ':'mo',
                'ヤ':'ya','ユ':'yu','ヨ':'yo',
                'ラ':'ra','リ':'ri','ル':'ru','レ':'re','ロ':'ro',
                'ワ':'wa','ヲ':'wo','ン':'n',
                'ガ':'ga','ギ':'gi','グ':'gu','ゲ':'ge','ゴ':'go',
                'ザ':'za','ジ':'ji','ズ':'zu','ゼ':'ze','ゾ':'zo',
                'ダ':'da','ヂ':'ji','ヅ':'zu','デ':'de','ド':'do',
                'バ':'ba','ビ':'bi','ブ':'bu','ベ':'be','ボ':'bo',
                'パ':'pa','ピ':'pi','プ':'pu','ペ':'pe','ポ':'po'
            };
            let result = "";
            for (let i = 0; i < input.length; i++) {
                let pair = input.slice(i, i + 2);
                if (map[pair]) {
                    result += map[pair];
                    i++;
                    continue;
                }
                let single = input.charAt(i);
                result += map[single] || single;
            }
            return result;
        }

        function convertJapaneseToRomaji(text) {
            if (!ready) return "undefined";
            var reading = getReading(text);
            return katakanaToRomaji(reading);
        }
        """
        context?.evaluateScript(js)

        let kuromojiLoadScript = """
        var builder = kuromoji.builder({ dicPath: "https://unpkg.com/kuromoji@0.1.2/dict/" });
        builder.build(function (err, tkz) {
            tokenizer = tkz;
            ready = true;
        });
        """
        context?.evaluateScript(kuromojiLoadScript)
    }

    func convert(_ text: String) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["python3", "-c", """
import sys
from pykakasi import kakasi
k = kakasi()
k.setMode("H", "a"); k.setMode("K", "a"); k.setMode("J", "a")
conv = k.getConverter()
print(conv.do(sys.argv[1]))
""", text]

        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
        } catch {
            return "(romaji error)"
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? text
    }
}
