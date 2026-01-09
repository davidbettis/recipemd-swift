/// Options for generating RecipeMD output.
public struct GeneratorOptions: Sendable {
    /// Whether to use Unicode fraction characters (e.g., ½ instead of 1/2).
    public var useUnicodeFractions: Bool

    /// The heading level to use for ingredient groups (2-6).
    public var ingredientGroupHeadingLevel: Int

    public init(
        useUnicodeFractions: Bool = false,
        ingredientGroupHeadingLevel: Int = 2
    ) {
        self.useUnicodeFractions = useUnicodeFractions
        self.ingredientGroupHeadingLevel = min(6, max(2, ingredientGroupHeadingLevel))
    }
}

/// Generates RecipeMD-formatted Markdown from `Recipe` objects.
public struct RecipeMDGenerator: Sendable {
    public init() {}

    /// Generates RecipeMD markdown from a Recipe.
    /// - Parameter recipe: The recipe to convert.
    /// - Returns: A RecipeMD-formatted string.
    public func generate(_ recipe: Recipe) -> String {
        generate(recipe, options: GeneratorOptions())
    }

    /// Generates RecipeMD markdown from a Recipe with options.
    /// - Parameters:
    ///   - recipe: The recipe to convert.
    ///   - options: Formatting options.
    /// - Returns: A RecipeMD-formatted string.
    public func generate(_ recipe: Recipe, options: GeneratorOptions) -> String {
        var lines: [String] = []

        // Title
        lines.append("# \(recipe.title)")
        lines.append("")

        // Description
        if let description = recipe.description, !description.isEmpty {
            lines.append(description)
            lines.append("")
        }

        // Tags
        if !recipe.tags.isEmpty {
            lines.append("*\(recipe.tags.joined(separator: ", "))*")
        }

        // Yield
        if recipe.yield.hasAmounts {
            let yieldsText = recipe.yield.amount.map { amount in
                let amountText = options.useUnicodeFractions
                    ? convertToUnicodeFraction(amount.rawText)
                    : amount.rawText
                if let unit = amount.unit {
                    return "\(amountText) \(unit)"
                } else {
                    return amountText
                }
            }.joined(separator: ", ")
            lines.append("**\(yieldsText)**")
        }

        if !recipe.tags.isEmpty || recipe.yield.hasAmounts {
            lines.append("")
        }

        // Ingredient section divider
        lines.append("---")
        lines.append("")

        // Ingredients
        for group in recipe.ingredientGroups {
            formatIngredientGroup(group, lines: &lines, headingLevel: options.ingredientGroupHeadingLevel, options: options)
        }

        // Instructions
        if let instructions = recipe.instructions, !instructions.isEmpty {
            lines.append("---")
            lines.append("")
            lines.append(instructions)
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private

    private func formatIngredientGroup(
        _ group: IngredientGroup,
        lines: inout [String],
        headingLevel: Int,
        options: GeneratorOptions
    ) {
        if let title = group.title {
            let hashes = String(repeating: "#", count: min(6, headingLevel))
            lines.append("\(hashes) \(title)")
            lines.append("")
        }

        for ingredient in group.ingredients {
            lines.append(formatIngredient(ingredient, options: options))
        }

        if !group.ingredients.isEmpty {
            lines.append("")
        }

        // Recursively handle nested groups with incremented heading level
        for nestedGroup in group.ingredientGroups {
            formatIngredientGroup(nestedGroup, lines: &lines, headingLevel: headingLevel + 1, options: options)
        }
    }

    private func formatIngredient(_ ingredient: Ingredient, options: GeneratorOptions) -> String {
        var parts: [String] = []

        // Amount and unit
        if let amount = ingredient.amount {
            let amountText = options.useUnicodeFractions
                ? convertToUnicodeFraction(amount.rawText)
                : amount.rawText

            if let unit = amount.unit {
                parts.append("*\(amountText) \(unit)*")
            } else {
                parts.append("*\(amountText)*")
            }
        }

        // Name (with optional link)
        if let link = ingredient.link {
            parts.append("[\(ingredient.name)](\(link))")
        } else {
            parts.append(ingredient.name)
        }

        return "- \(parts.joined(separator: " "))"
    }

    /// Converts ASCII fractions to Unicode fraction characters.
    private func convertToUnicodeFraction(_ text: String) -> String {
        var result = text

        // Common fractions mapping
        let fractions: [(String, String)] = [
            ("1/2", "½"),
            ("1/3", "⅓"),
            ("2/3", "⅔"),
            ("1/4", "¼"),
            ("3/4", "¾"),
            ("1/5", "⅕"),
            ("2/5", "⅖"),
            ("3/5", "⅗"),
            ("4/5", "⅘"),
            ("1/6", "⅙"),
            ("5/6", "⅚"),
            ("1/8", "⅛"),
            ("3/8", "⅜"),
            ("5/8", "⅝"),
            ("7/8", "⅞")
        ]

        for (ascii, unicode) in fractions {
            result = result.replacingOccurrences(of: ascii, with: unicode)
        }

        // Clean up spacing for mixed numbers (e.g., "1 ½" -> "1½")
        for (_, unicode) in fractions {
            result = result.replacingOccurrences(of: " \(unicode)", with: unicode)
        }

        return result
    }
}
