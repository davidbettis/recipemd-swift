import Foundation

/// Errors that can occur when parsing RecipeMD documents.
///
/// `RecipeMDError` provides detailed information about parsing failures,
/// including actionable suggestions for fixing the issue.
///
/// ## Example
///
/// ```swift
/// do {
///     let recipe = try parser.parse(markdown)
/// } catch let error as RecipeMDError {
///     print(error.errorDescription ?? "Unknown error")
///     print("Suggestion: \(error.recoverySuggestion ?? "")")
/// }
/// ```
public enum RecipeMDError: LocalizedError, Sendable, Equatable {
    /// The recipe is missing a title (level 1 heading).
    ///
    /// A valid RecipeMD document must start with a level-1 heading (`# Title`).
    case missingTitle

    /// The recipe is missing the ingredient section divider.
    ///
    /// RecipeMD requires at least one horizontal rule (`---`) to separate
    /// the metadata from the ingredients section.
    case missingIngredientSection

    /// An amount string could not be parsed.
    ///
    /// The associated value contains the invalid amount text.
    case invalidAmount(String)

    /// The document structure is malformed.
    ///
    /// The associated value contains a description of the structural issue.
    case malformedStructure(String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .missingTitle:
            return "Recipe is missing a title"
        case .missingIngredientSection:
            return "Recipe is missing the ingredient section"
        case .invalidAmount(let text):
            return "Invalid amount: '\(text)'"
        case .malformedStructure(let message):
            return "Malformed recipe: \(message)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .missingTitle:
            return "No level-1 heading (# Title) was found in the document."
        case .missingIngredientSection:
            return "No horizontal rule (---) was found to mark the ingredient section."
        case .invalidAmount(let text):
            return "The text '\(text)' could not be parsed as a valid amount."
        case .malformedStructure(let message):
            return message
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .missingTitle:
            return "Add a title at the beginning of the document using a level-1 heading: # Recipe Name"
        case .missingIngredientSection:
            return "Add a horizontal rule (---) after the description to mark the start of ingredients."
        case .invalidAmount:
            return "Use a valid format: integers (2), decimals (1.5), fractions (1/2), or mixed numbers (1 1/2)."
        case .malformedStructure:
            return "Review the RecipeMD specification at https://recipemd.org/specification.html"
        }
    }
}

// MARK: - CustomStringConvertible

extension RecipeMDError: CustomStringConvertible {
    public var description: String {
        errorDescription ?? "Unknown RecipeMD error"
    }
}

// MARK: - CustomDebugStringConvertible

extension RecipeMDError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .missingTitle:
            return "RecipeMDError.missingTitle"
        case .missingIngredientSection:
            return "RecipeMDError.missingIngredientSection"
        case .invalidAmount(let text):
            return "RecipeMDError.invalidAmount(\"\(text)\")"
        case .malformedStructure(let message):
            return "RecipeMDError.malformedStructure(\"\(message)\")"
        }
    }
}
