//
//  Copyright © 2024 Hidden Spectrum, LLC.
//

import ArgumentParser
import Foundation
import OpenAI

public enum OpenAIModel: String, ExpressibleByArgument {
    case gpt3_5Turbo = "gpt-3.5-turbo"
    case gpt4o = "gpt-4o"
    // `o3-mini`: small reasoning model providing high intelligence at the same cost and latency targets of o1-mini.
    case o3_mini = "o3-mini"
    case o4_mini = "o4-mini"
    /// `o1`: reasoning model designed to solve hard problems across domains
    case o3 = "o1"
    case gpt4_1 = "gpt-4.1"
}
