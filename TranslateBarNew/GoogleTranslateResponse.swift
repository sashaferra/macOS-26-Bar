import Foundation

struct GoogleTranslateResponse: Decodable, @unchecked Sendable {
    struct Translation: Decodable, @unchecked Sendable {
        let translatedText: String
    }

    struct Data: Decodable, @unchecked Sendable {
        let translations: [Translation]
    }

    let data: Data
}
