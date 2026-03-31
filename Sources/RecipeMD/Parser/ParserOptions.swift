/// Options for parsing RecipeMD input.
public struct ParserOptions: Sendable {
    /// When enabled, unit text is truncated at the first digit or unicode fraction
    /// character that would indicate the start of a second amount. This handles
    /// non-standard annotations like "1T (15 g) sugar" by parsing the unit as "T"
    /// and discarding the parenthetical.
    ///
    /// Defaults to `false` (strict spec behavior where the full text after the
    /// number is treated as the unit).
    ///
    /// Mutually exclusive with `extractSupplementalAmounts`.
    public var discardSupplementalAmounts: Bool

    /// **Extra**: Not part of the RecipeMD specification.
    ///
    /// When enabled, non-standard annotations like "1 T (15 g) sugar" are parsed
    /// by extracting the supplemental amount ("15 g") into
    /// ``Amount/supplementalAmount``. The primary amount's unit is truncated to
    /// "T", matching the behavior of ``discardSupplementalAmounts``, but the
    /// supplemental value is preserved instead of being discarded.
    ///
    /// Defaults to `false`.
    ///
    /// Mutually exclusive with `discardSupplementalAmounts`.
    public var extractSupplementalAmounts: Bool

    public init(
        discardSupplementalAmounts: Bool = false,
        extractSupplementalAmounts: Bool = false
    ) {
        precondition(
            !(discardSupplementalAmounts && extractSupplementalAmounts),
            "discardSupplementalAmounts and extractSupplementalAmounts are mutually exclusive"
        )
        self.discardSupplementalAmounts = discardSupplementalAmounts
        self.extractSupplementalAmounts = extractSupplementalAmounts
    }
}
