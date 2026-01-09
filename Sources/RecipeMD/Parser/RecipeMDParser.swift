import Markdown

/// Parses RecipeMD-formatted Markdown into `Recipe` objects.
public struct RecipeMDParser: Sendable {
    public init() {}

    /// Parses a RecipeMD string into a Recipe.
    /// - Parameter markdown: The RecipeMD-formatted string.
    /// - Returns: The parsed Recipe.
    /// - Throws: `RecipeMDError` if the document is invalid.
    public func parse(_ markdown: String) throws -> Recipe {
        let document = Document(parsing: markdown)
        return try parseDocument(document)
    }

    /// Parses a RecipeMD string with detailed diagnostics.
    /// - Parameter markdown: The RecipeMD-formatted string.
    /// - Returns: A Result containing either the parsed Recipe or an error.
    public func parseWithDiagnostics(_ markdown: String) -> Result<Recipe, RecipeMDError> {
        do {
            let recipe = try parse(markdown)
            return .success(recipe)
        } catch let error as RecipeMDError {
            return .failure(error)
        } catch {
            return .failure(.malformedStructure(error.localizedDescription))
        }
    }

    // MARK: - Private

    private func parseDocument(_ document: Document) throws -> Recipe {
        let children = Array(document.children)

        // Find title (first H1)
        guard let titleIndex = children.firstIndex(where: { ($0 as? Heading)?.level == 1 }),
              let heading = children[titleIndex] as? Heading else {
            throw RecipeMDError.missingTitle
        }
        let title = heading.plainText

        // Find thematic breaks (---)
        let breakIndices = children.enumerated().compactMap { index, child in
            child is ThematicBreak ? index : nil
        }

        guard let firstBreakIndex = breakIndices.first else {
            throw RecipeMDError.missingIngredientSection
        }

        // Parse metadata section: content between title and first break
        let metadataNodes = Array(children[(titleIndex + 1)..<firstBreakIndex])
        let (description, tags, yield) = parseMetadataSection(metadataNodes)

        // Parse ingredients: content between first break and second break (or end)
        let ingredientEndIndex = breakIndices.count > 1 ? breakIndices[1] : children.count
        let ingredientNodes = children[(firstBreakIndex + 1)..<ingredientEndIndex]
        let ingredientGroups = parseIngredients(Array(ingredientNodes))

        // Parse instructions: content after second break (if present)
        var instructions: String?
        if breakIndices.count > 1 {
            let instructionNodes = children[(breakIndices[1] + 1)...]
            instructions = parseInstructions(Array(instructionNodes))
        }

        return Recipe(
            title: title,
            description: description,
            tags: tags,
            yield: yield,
            ingredientGroups: ingredientGroups,
            instructions: instructions
        )
    }

    // MARK: - Metadata Section Parsing

    /// Parses the metadata section (between title and first ---) into description, tags, and yield.
    private func parseMetadataSection(_ nodes: [any Markup]) -> (String?, [String], Yield) {
        var descriptionParts: [String] = []
        var tags: [String] = []
        var yieldAmounts: [Amount] = []

        for node in nodes {
            guard let paragraph = node as? Paragraph else { continue }
            let children = Array(paragraph.children)

            // Check for tags/yields paragraph
            // Can be: single Emphasis (tags), single Strong (yields), or both on consecutive lines
            let (foundTags, foundAmounts, isMetadata) = parseTagsAndYieldsFromParagraph(children)

            if isMetadata {
                if !foundTags.isEmpty { tags = foundTags }
                if !foundAmounts.isEmpty { yieldAmounts = foundAmounts }
                continue
            }

            // Otherwise treat as description
            let text = paragraph.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                descriptionParts.append(text)
            }
        }

        let description = descriptionParts.isEmpty ? nil : descriptionParts.joined(separator: "\n\n")
        return (description, tags, Yield(amount: yieldAmounts))
    }

    /// Parses tags and yields from a paragraph's children.
    /// Returns (tags, yieldAmounts, isMetadataParagraph).
    private func parseTagsAndYieldsFromParagraph(_ children: [any Markup]) -> ([String], [Amount], Bool) {
        var tags: [String] = []
        var amounts: [Amount] = []
        var hasEmphasisOrStrong = false
        var hasOtherContent = false

        for child in children {
            if let emphasis = child as? Emphasis {
                let parsedTags = parseTags(emphasis)
                if !parsedTags.isEmpty {
                    tags = parsedTags
                    hasEmphasisOrStrong = true
                }
            } else if let strong = child as? Strong {
                let parsedAmounts = parseYieldAmounts(strong)
                if !parsedAmounts.isEmpty {
                    amounts = parsedAmounts
                    hasEmphasisOrStrong = true
                }
            } else if child is SoftBreak || child is LineBreak {
                // Ignore line breaks between tags and yields
                continue
            } else if let text = child as? Text {
                // Check if it's just whitespace
                if !text.string.trimmingCharacters(in: .whitespaces).isEmpty {
                    hasOtherContent = true
                }
            } else {
                hasOtherContent = true
            }
        }

        // It's a metadata paragraph if it only contains Emphasis/Strong (tags/yields)
        let isMetadata = hasEmphasisOrStrong && !hasOtherContent
        return (tags, amounts, isMetadata)
    }

    // MARK: - Tags Parsing

    /// Parses tags from an Emphasis node (e.g., *tag1, tag2, tag3*).
    private func parseTags(_ emphasis: Emphasis) -> [String] {
        let text = emphasis.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        // Split by comma and trim each tag
        return text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Yields Parsing

    /// Parses yield amounts from a Strong node (e.g., **4 Servings, 500g**).
    private func parseYieldAmounts(_ strong: Strong) -> [Amount] {
        let text = strong.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        // Split by comma and parse each amount
        return text
            .split(separator: ",")
            .compactMap { parseYieldAmount(String($0).trimmingCharacters(in: .whitespaces)) }
    }

    /// Parses a single yield amount string (e.g., "4 Servings" or "500g").
    private func parseYieldAmount(_ text: String) -> Amount? {
        guard !text.isEmpty else { return nil }

        // Try to parse amount from the beginning
        let (value, rawAmount, remaining) = parseAmountValue(text)

        guard let amountValue = value else {
            // No amount found
            return nil
        }

        let unit = remaining.trimmingCharacters(in: .whitespaces)
        return Amount(amount: amountValue, unit: unit.isEmpty ? nil : unit, rawText: rawAmount)
    }

    // MARK: - Ingredient Parsing

    private func parseIngredients(_ nodes: [any Markup]) -> [IngredientGroup] {
        var groups: [IngredientGroup] = []
        var currentGroup = IngredientGroup()

        for node in nodes {
            if let heading = node as? Heading, heading.level >= 2 {
                // Start a new group if current has ingredients
                if !currentGroup.ingredients.isEmpty {
                    groups.append(currentGroup)
                }
                currentGroup = IngredientGroup(title: heading.plainText)
            } else if let list = node as? UnorderedList {
                currentGroup.ingredients.append(contentsOf: parseIngredientList(list))
            } else if let list = node as? OrderedList {
                currentGroup.ingredients.append(contentsOf: parseOrderedIngredientList(list))
            }
        }

        // Add final group
        if !currentGroup.ingredients.isEmpty || currentGroup.title != nil {
            groups.append(currentGroup)
        }

        return groups
    }

    private func parseIngredientList(_ list: UnorderedList) -> [Ingredient] {
        list.listItems.compactMap { item in
            parseIngredientItem(item)
        }
    }

    private func parseOrderedIngredientList(_ list: OrderedList) -> [Ingredient] {
        list.listItems.compactMap { item in
            parseIngredientItem(item)
        }
    }

    private func parseIngredientItem(_ item: ListItem) -> Ingredient? {
        let itemChildren = Array(item.children)
        guard let paragraph = itemChildren.first as? Paragraph else { return nil }

        let children = Array(paragraph.children)
        var amount: Amount?
        var name: String = ""
        var link: String?

        var index = 0

        // Check for amount in emphasis (italic): *1 cup* or *2*
        if index < children.count, let emphasis = children[index] as? Emphasis {
            let amountText = emphasis.plainText
            amount = parseAmountWithUnit(amountText)
            index += 1
        }

        // Skip whitespace text nodes
        while index < children.count, let text = children[index] as? Text,
              text.string.trimmingCharacters(in: .whitespaces).isEmpty {
            index += 1
        }

        // Check for link or plain text name
        if index < children.count {
            if let linkNode = children[index] as? Link {
                name = linkNode.plainText
                link = linkNode.destination
                index += 1
            } else {
                // Collect remaining text as name
                var nameParts: [String] = []
                while index < children.count {
                    if let text = children[index] as? Text {
                        nameParts.append(text.string)
                    } else if let linkNode = children[index] as? Link {
                        nameParts.append(linkNode.plainText)
                        link = linkNode.destination
                    }
                    index += 1
                }
                name = nameParts.joined().trimmingCharacters(in: .whitespaces)
            }
        }

        guard !name.isEmpty else { return nil }

        return Ingredient(name: name, amount: amount, link: link)
    }

    private func parseAmountWithUnit(_ text: String) -> Amount? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Try to parse amount from the beginning
        let (value, rawAmount, remaining) = parseAmountValue(trimmed)

        guard let amountValue = value else {
            // No valid amount found
            return nil
        }

        let unit = remaining.trimmingCharacters(in: .whitespaces)
        return Amount(amount: amountValue, unit: unit.isEmpty ? nil : unit, rawText: rawAmount)
    }

    private func parseAmountValue(_ text: String) -> (Double?, String, String) {
        var remaining = text
        var totalValue: Double = 0
        var rawParts: [String] = []

        // Handle mixed numbers like "1 1/2" or single values like "1.5" or "1/2"
        while !remaining.isEmpty {
            let trimmed = remaining.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { break }

            // Try to parse a number or fraction at the start
            if let (value, raw, rest) = parseSingleNumber(trimmed) {
                totalValue += value
                rawParts.append(raw)
                remaining = rest

                // Check if next part is also a number (for mixed fractions)
                let nextTrimmed = remaining.trimmingCharacters(in: .whitespaces)
                if nextTrimmed.isEmpty || !nextTrimmed.first!.isNumber && !isUnicodeFraction(nextTrimmed.first!) {
                    break
                }
                remaining = nextTrimmed
            } else {
                break
            }
        }

        if rawParts.isEmpty {
            return (nil, "", text)
        }

        return (totalValue, rawParts.joined(separator: " "), remaining)
    }

    private func parseSingleNumber(_ text: String) -> (Double, String, String)? {
        // Check for unicode fractions first
        if let first = text.first, let value = unicodeFractionValue(first) {
            return (value, String(first), String(text.dropFirst()))
        }

        // Match integer, decimal, or fraction
        var index = text.startIndex
        var hasDecimal = false
        var hasSlash = false
        var slashIndex: String.Index?

        while index < text.endIndex {
            let char = text[index]
            // Check for unicode fractions - they need special handling, not regular number parsing
            if isUnicodeFraction(char) {
                break
            } else if char.isNumber {
                index = text.index(after: index)
            } else if char == "." || char == "," {
                if hasDecimal || hasSlash { break }
                hasDecimal = true
                index = text.index(after: index)
            } else if char == "/" {
                if hasSlash || hasDecimal { break }
                hasSlash = true
                slashIndex = index
                index = text.index(after: index)
            } else {
                break
            }
        }

        guard index > text.startIndex else { return nil }

        let raw = String(text[..<index])
        let remaining = String(text[index...])

        // Parse the value
        if hasSlash, let slashIdx = slashIndex {
            let numeratorStr = String(text[..<slashIdx])
            let denominatorStr = String(text[text.index(after: slashIdx)..<index])
            guard let numerator = Double(numeratorStr),
                  let denominator = Double(denominatorStr),
                  denominator != 0 else {
                return nil
            }
            return (numerator / denominator, raw, remaining)
        } else {
            // Handle comma as decimal separator
            let normalized = raw.replacingOccurrences(of: ",", with: ".")
            guard let value = Double(normalized) else { return nil }
            return (value, raw, remaining)
        }
    }

    private func isUnicodeFraction(_ char: Character) -> Bool {
        unicodeFractionValue(char) != nil
    }

    private func unicodeFractionValue(_ char: Character) -> Double? {
        switch char {
        case "½": return 0.5
        case "⅓": return 1.0 / 3.0
        case "⅔": return 2.0 / 3.0
        case "¼": return 0.25
        case "¾": return 0.75
        case "⅕": return 0.2
        case "⅖": return 0.4
        case "⅗": return 0.6
        case "⅘": return 0.8
        case "⅙": return 1.0 / 6.0
        case "⅚": return 5.0 / 6.0
        case "⅛": return 0.125
        case "⅜": return 0.375
        case "⅝": return 0.625
        case "⅞": return 0.875
        default: return nil
        }
    }

    // MARK: - Instructions Parsing

    private func parseInstructions(_ nodes: [any Markup]) -> String? {
        let parts = nodes.map { node -> String in
            if let paragraph = node as? Paragraph {
                return paragraph.plainText
            } else if let heading = node as? Heading {
                let hashes = String(repeating: "#", count: heading.level)
                return "\(hashes) \(heading.plainText)"
            } else if let list = node as? UnorderedList {
                return list.listItems.enumerated().map { _, item in
                    "- \(item.plainText)"
                }.joined(separator: "\n")
            } else if let list = node as? OrderedList {
                return list.listItems.enumerated().map { idx, item in
                    "\(idx + 1). \(item.plainText)"
                }.joined(separator: "\n")
            } else if node is ThematicBreak {
                return "---"
            }
            return ""
        }

        let result = parts.joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
}

// MARK: - Markup Extensions

private extension Heading {
    var plainText: String {
        children.compactMap { child -> String? in
            if let text = child as? Text {
                return text.string
            } else if let emphasis = child as? Emphasis {
                return emphasis.plainText
            } else if let strong = child as? Strong {
                return strong.plainText
            }
            return nil
        }.joined()
    }
}

private extension Paragraph {
    var plainText: String {
        children.compactMap { child -> String? in
            if let text = child as? Text {
                return text.string
            } else if let emphasis = child as? Emphasis {
                return emphasis.plainText
            } else if let strong = child as? Strong {
                return strong.plainText
            } else if let link = child as? Link {
                return link.plainText
            } else if child is SoftBreak {
                return " "
            } else if child is LineBreak {
                return "\n"
            }
            return nil
        }.joined()
    }
}

private extension Emphasis {
    var plainText: String {
        children.compactMap { ($0 as? Text)?.string }.joined()
    }
}

private extension Strong {
    var plainText: String {
        children.compactMap { ($0 as? Text)?.string }.joined()
    }
}

private extension Link {
    var plainText: String {
        children.compactMap { ($0 as? Text)?.string }.joined()
    }
}

private extension ListItem {
    var plainText: String {
        children.compactMap { child -> String? in
            if let paragraph = child as? Paragraph {
                return paragraph.plainText
            }
            return nil
        }.joined()
    }
}
