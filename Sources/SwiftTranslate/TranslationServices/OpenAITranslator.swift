//
//  Copyright © 2024 Hidden Spectrum, LLC.
//

import Foundation
import OpenAI
import Rainbow
import SwiftStringCatalog


struct OpenAITranslator {
    
    // MARK: Private
    
    private let openAI: OpenAI
    private let model: OpenAIModel
    private let retries: Int

    // MARK: Lifecycle
    
    init(with apiToken: String, model: OpenAIModel, timeoutInterval: Int, retries: Int) {
        self.openAI = OpenAI(configuration: OpenAI.Configuration(token: apiToken, timeoutInterval: TimeInterval(timeoutInterval)))
        self.model = model
        self.retries = retries
    }
    
    // MARK: Helpers
    
    private func chatQuery(for translatableText: String, targetLanguage: Language, comment: String?) -> ChatQuery {
        
        var systemPrompt =
            """
            You are a helpful professional translator designated to translate text from English to the language with ISO 639-1 code: \(targetLanguage.rawValue)
            If the input text contains argument placeholders (%arg, @arg1, %lld, etc), it's important they are preserved in the translated text.
            You should not output anything other than the translated text.
            Avoid using the same word more than once in a row.
            Avoid using the same character more than 3 times in a row.
            Trim extra spaces and the beginning and end of the translated text.
            Put extra attention to Punctuation Marks, Exclamation Marks, Quotation Marks, etc... And try to maintain them as in the original text. So if there is no punctuation mark at the end of a text don't put it in the response. !! Important !!
            Do not provide blank translations. Do not hallucinate. Do not provide translations that are not faithful to the original text.
            Put particular attention to languages that use different characters and symbols than English.
            """
        if let comment {
            systemPrompt += "\nTake into consideration the following context when translating, but do not completely change the translation because of it, it is a comment for the translator: \(comment)\n"
        }
        
        let query: ChatQuery!
        
        switch model {
        case .gpt3_5Turbo: fallthrough
        case .gpt4o: fallthrough
        case .gpt4_1: query = ChatQuery(messages: [ .system(.init(content: systemPrompt)),
                                                    .user(.init(content: .string(translatableText))) ],
                                        model: model.rawValue,
                                        frequencyPenalty: -2,
                                        presencePenalty: -2,
                                        responseFormat: .text
                                    )
        case .o3_mini: fallthrough
        case .o3: fallthrough
        case .o4_mini: query = ChatQuery( messages: [ .system(.init(content: systemPrompt)),
                                                      .user(.init(content: .string(translatableText))) ],
                                          model: model.rawValue,
                                          reasoningEffort: (model == .o3) ? .medium : .high,
                                          responseFormat: .text
                                        )
        }
        
        return query
    }
}

extension OpenAITranslator: TranslationService {
    
    // MARK: Translate
    
    func translate(_ string: String, to targetLanguage: Language, comment: String?) async throws -> String {
        guard !string.isEmpty else {
            return string
        }

        var attempt = 0
        repeat {
            attempt += 1
            do {
                let result = try await openAI.chats(query: chatQuery(for: string, targetLanguage: targetLanguage, comment: comment))
                
                guard let choice = result.choices.first else {
                    print("Warning: No translated text returned from OpenAI. No choices available.")
                    continue
                }

                guard let translatedText = choice.message.content, !translatedText.isEmpty else {
                    print("Warning: No translated text returned from OpenAI. Finish Reason: \(choice.finishReason)")
                    continue
                }
                return translatedText
            } catch {
                print("Error performing OpenAI translation request: \(error). Retrying...")
                continue
            }
        } while attempt < retries

        throw SwiftTranslateError.noTranslationReturned
    }
}

extension String {
    func truncatedRemovingNewlines(to length: Int) -> String {
        let newlinesRemoved = replacingOccurrences(of: "\n", with: " ")
        guard newlinesRemoved.count > length else {
            return self
        }
        return String(newlinesRemoved.prefix(length) + "...")
    }
}
