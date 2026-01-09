# RecipeMD

A Swift library for parsing and generating [RecipeMD](https://recipemd.org)-formatted recipes.

## Features

- Parse RecipeMD Markdown into strongly-typed Swift structures
- Generate RecipeMD Markdown from Swift objects
- Full support for the RecipeMD specification
- Swift 6 strict concurrency support
- Comprehensive documentation

## Requirements

- iOS 17.0+ / macOS 14.0+ / watchOS 10.0+ / tvOS 17.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Add RecipeMD to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/RecipeMD.git", from: "1.0.0")
]
```

Then add it to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["RecipeMD"]
    )
]
```

## Quick Start

### Parsing a Recipe

```swift
import RecipeMD

let markdown = """
# Guacamole

A fresh Mexican dip.

*vegan, Mexican*
**4 Servings**

---

- *2* ripe avocados
- *½ teaspoon* salt
- *1 tablespoon* lime juice

---

Mash avocados in a bowl. Add salt and lime juice, mix well.
"""

let parser = RecipeMDParser()
let recipe = try parser.parse(markdown)

print(recipe.title)       // "Guacamole"
print(recipe.tags)        // ["vegan", "Mexican"]
print(recipe.yields[0])   // 4 Servings
```

### Creating a Recipe

```swift
let recipe = Recipe(
    title: "Guacamole",
    description: "A fresh Mexican dip.",
    tags: ["vegan", "Mexican"],
    yields: [.servings(4)],
    ingredientGroups: [
        IngredientGroup(ingredients: [
            Ingredient(name: "avocados", amount: Amount(2)),
            Ingredient(name: "salt", amount: .fraction(1, 2), unit: "teaspoon"),
            Ingredient(name: "lime juice", amount: Amount(1), unit: "tablespoon")
        ])
    ],
    instructions: "Mash avocados in a bowl. Add salt and lime juice, mix well."
)
```

### Generating Markdown

```swift
let generator = RecipeMDGenerator()
let markdown = generator.generate(recipe)
print(markdown)
```

With Unicode fractions:

```swift
let options = GeneratorOptions(useUnicodeFractions: true)
let markdown = generator.generate(recipe, options: options)
// Outputs "½" instead of "1/2"
```

## RecipeMD Format

A RecipeMD document follows this structure:

```markdown
# Recipe Title

Optional description paragraph.

*tag1, tag2, tag3*
**4 Servings, 500g**

---

- *2 cups* flour
- *1* egg
- salt to taste

## Optional Section

- *200g* chocolate

---

Instructions go here. Can include multiple paragraphs.
```

### Elements

| Element | Required | Format |
|---------|----------|--------|
| Title | Yes | Level 1 heading (`# Title`) |
| Description | No | Paragraphs before tags/yields |
| Tags | No | Italicized list (`*tag1, tag2*`) |
| Yields | No | Bold list (`**4 Servings**`) |
| Ingredients | Yes (structure) | List items after first `---` |
| Ingredient Groups | No | Level 2+ headings |
| Instructions | No | Content after second `---` |

### Amount Formats

RecipeMD supports various amount formats:

- Integers: `2`, `10`
- Decimals: `1.5`, `0.25`
- Fractions: `1/2`, `3/4`
- Mixed numbers: `1 1/2`, `2 3/4`
- Unicode fractions: `½`, `¾`, `1½`
- European decimals: `1,5`

## API Reference

### Core Types

- `Recipe` - The main recipe container
- `Ingredient` - A single ingredient with optional amount/unit
- `IngredientGroup` - A group of ingredients with optional title
- `Amount` - A pair defining the amount and unit of the amount
- `Yield` - A yield specification (e.g., "4 Servings, 200 grams")

### Parser

```swift
let parser = RecipeMDParser()

// Parse with throwing
let recipe = try parser.parse(markdownString)

// Parse with Result
let result = parser.parseWithDiagnostics(markdownString)
switch result {
case .success(let recipe):
    // Use recipe
case .failure(let error):
    print(error.errorDescription)
    print(error.recoverySuggestion)
}
```

### Generator

```swift
let generator = RecipeMDGenerator()

// Generate with default options
let markdown = generator.generate(recipe)

// Generate with options
let options = GeneratorOptions(
    useUnicodeFractions: true,
    ingredientGroupHeadingLevel: 3
)
let markdown = generator.generate(recipe, options: options)
```

### Errors

`RecipeMDError` provides detailed error information:

```swift
do {
    let recipe = try parser.parse(markdown)
} catch let error as RecipeMDError {
    print(error.errorDescription)     // Human-readable description
    print(error.failureReason)        // What went wrong
    print(error.recoverySuggestion)   // How to fix it
}
```

## License

MIT License - see LICENSE file for details.

## Links

- [RecipeMD Specification](https://recipemd.org/specification.html)
- [RecipeMD Website](https://recipemd.org)
