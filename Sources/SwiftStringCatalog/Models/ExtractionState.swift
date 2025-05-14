//
//  Copyright © 2024 Hidden Spectrum, LLC.
//

import Foundation


public enum ExtractionState: String, Codable {
    case extractedWithValue = "extracted_with_value"
    case manual
    case stale
    case migrated
    case unknown
}
