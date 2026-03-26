/// Options for parsing RecipeMD input.
public struct ParserOptions: Sendable {
    /// When enabled, unit text is truncated at the first digit or unicode fraction
    /// character that would indicate the start of a second amount. This handles
    /// non-standard annotations like "1T (15 g) sugar" by parsing the unit as "T"
    /// and discarding the parenthetical.
    ///
    /// Defaults to `false` (strict spec behavior where the full text after the
    /// number is treated as the unit).
    public var discardSupplementalAmounts: Bool

    public init(
        discardSupplementalAmounts: Bool = false
    ) {
        self.discardSupplementalAmounts = discardSupplementalAmounts
    }
}
