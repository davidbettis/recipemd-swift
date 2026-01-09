# Product Requirements Document: RecipeMD-swift

## Overview

RecipeMD-swift is a Swift library for parsing and generating recipes in the [RecipeMD format](https://recipemd.org/specification.html). RecipeMD is a CommonMark-based Markdown format that provides a structured, human-readable way to write and share recipes.

## Problem Statement

Developers building recipe applications on Apple platforms need a reliable way to:

- Import recipes from RecipeMD-formatted Markdown files
- Export recipes to a portable, human-readable format
- Validate recipe structure and content

No Swift-native library currently exists for working with the RecipeMD specification.

## Goals

1. **Full Specification Compliance**: Parse and generate all valid RecipeMD documents per the specification
2. **Type Safety**: Provide strongly-typed Swift models for all recipe components
3. **Ergonomic API**: Offer a simple, Swift-idiomatic interface
4. **Performance**: Efficiently handle large recipe collections
5. **Portability**: Support iOS 17+, macOS 14+, watchOS 10+, tvOS 17+

## Non-Goals

- UI components for displaying recipes
- Recipe storage or database functionality
- Network operations for fetching recipes
- Recipe format conversion (e.g., from other formats)

## RecipeMD Format Summary

A RecipeMD document follows this structure:

```markdown
# Recipe Title

Optional description paragraph(s).

*tag1, tag2, tag3*
**4 Servings, 500g**

---

- *1 cup* flour
- *2* eggs
- salt to taste

## Filling

- *200g* cheese

---

Mix ingredients and bake at 350°F for 30 minutes.
```

### Elements

| Element | Required | Format |
|---------|----------|--------|
| Title | Yes | Level 1 heading (`# Title`) |
| Description | No | Paragraphs before tags/yields |
| Tags | No | Italicized comma-separated list (`*tag1, tag2*`) |
| Yields | No | Bold comma-separated amounts (`**4 Servings, 200 g**`) |
| Ingredients | Yes (structure) | List items after first `---` |
| Ingredient Groups | No | Level 2+ headings within ingredients |
| Instructions | No | Content after second `---` |

### Ingredient Format

```
- *<amount> <unit>* <name>
- *<amount>* [<name>](linked-recipe.md)
- <name>
```

Amount formats: integers (`2`), decimals (`1.5`), fractions (`1/2`), mixed (`1 1/2`), unicode (`½`)

## Technical Requirements

### Core Types

```swift
public struct Recipe: Sendable, Equatable, Codable {
    public var title: String
    public var description: String?
    public var tags: [String]
    public var yield: Yield
    public var ingredientGroups: [IngredientGroup]
    public var instructions: String?
}

public struct Yield: Sendable, Equatable, Codable {
    public var amount: [Amount]
}

public struct IngredientGroup: Sendable, Equatable, Codable {
    public var title: String?
    public var ingredients: [Ingredient]
    public var ingredientGroups: [IngredientGroup]
}

public struct Ingredient: Sendable, Equatable, Codable {
    public var name: String
    public var amount: Amount?
    public var link: String?  // URL to linked recipe
}

public struct Amount: Sendable, Equatable, Codable {
    public var amount: Double
    public var unit: String?
}
```

### Parser API

```swift
public struct RecipeMDParser: Sendable {
    public init()

    /// Parse a RecipeMD string into a Recipe
    public func parse(_ markdown: String) throws -> Recipe

    /// Parse with detailed error information
    public func parseWithDiagnostics(_ markdown: String) -> Result<Recipe, RecipeMDError>
}
```

### Generator API

```swift
public struct RecipeMDGenerator: Sendable {
    public init()

    /// Generate RecipeMD markdown from a Recipe
    public func generate(_ recipe: Recipe) -> String

    /// Generate with formatting options
    public func generate(_ recipe: Recipe, options: GeneratorOptions) -> String
}

public struct GeneratorOptions: Sendable {
    public var useUnicodeFractions: Bool = false
    public var ingredientGroupHeadingLevel: Int = 2
}
```

### Error Handling

```swift
public enum RecipeMDError: LocalizedError, Sendable {
    case missingTitle
    case missingIngredientSection
    case invalidAmount(String)
    case malformedStructure(String)

    public var errorDescription: String? { ... }
}
```

## API Design Principles

1. **Immutable by Default**: All types are value types with `var` properties for flexibility
2. **Sendable**: All types conform to `Sendable` for Swift 6 concurrency
3. **Codable**: All types conform to `Codable` for easy serialization
4. **Throwing for Critical Errors**: Parse failures throw; generation always succeeds
5. **Preserve Original Formatting**: `Amount.rawText` retains original representation

## Dependencies

- **swift-markdown** (Apple): CommonMark parsing
- No other external dependencies

## Testing Requirements

- Unit tests for all parsing edge cases
- Unit tests for round-trip (parse → generate → parse)
- Property-based tests for amount parsing
- Minimum 80% code coverage

## Milestones

### M1: Core Parsing
- Recipe model types
- Basic markdown parsing (title, description, instructions)
- Ingredient list parsing

### M2: Full Specification
- Tags and yields parsing
- Ingredient groups (nested headings)
- Amount parsing (all formats)
- Linked ingredients

### M3: Generation
- Markdown generation from Recipe
- Generator options
- Round-trip validation

### M4: Polish
- Error messages and diagnostics
- Documentation
- Performance optimization

## Success Criteria

1. Parses all example recipes from recipemd.org correctly
2. Generated markdown re-parses to equivalent Recipe
3. Clear, actionable error messages for invalid input
4. API documentation with examples
5. Published to Swift Package Index

## References

- [RecipeMD Specification](https://recipemd.org/specification.html)
- [RecipeMD Python Implementation](https://github.com/tstehr/RecipeMD)
- [CommonMark Specification](https://spec.commonmark.org/)
- [swift-markdown](https://github.com/apple/swift-markdown)
