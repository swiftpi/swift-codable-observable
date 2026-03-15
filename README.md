# swift-codable-observable

`swift-codable-observable` provides the `@CodableObservable` macro for Swift `@Observable` types that also conform to `Codable`.

The macro generates a `CodingKeys` enum that maps observable backing storage such as `_id` to external keys such as `"id"`. This enables Swift's synthesized `Codable` support to work with `@Observable` models.

Repository: `https://github.com/irvinesoft/swift-codable-observable`

## Installation

Add the package in Xcode with the repository URL:

`https://github.com/irvinesoft/swift-codable-observable`

Or declare it in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/irvinesoft/swift-codable-observable", from: "1.0.0")
]
```

Then add the library product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "CodableObservable", package: "swift-codable-observable")
    ]
)
```

## Usage

Import the library module and apply the macro to an `@Observable` type that conforms to `Codable`:

```swift
import Foundation
import Observation
import CodableObservable

@Observable
@CodableObservable
final class FlagModel: Codable {
    var id: UUID
    var appid: String
}
```

For classes, the macro also adds identity-based `Hashable` conformance. The expansion is similar to:

```swift
enum CodingKeys: String, CodingKey {
    case _id = "id"
    case _appid = "appid"
}

extension FlagModel: Hashable {
    static func == (lhs: FlagModel, rhs: FlagModel) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
```

That generated code allows `JSONDecoder` and `JSONEncoder` to use the observable backing storage while preserving the expected external key names, and lets class instances participate in hashed collections using reference identity.

## Example

```swift
let json = #"{"id":"550E8400-E29B-41D4-A716-446655440000","appid":"demo"}"#
let model = try JSONDecoder().decode(FlagModel.self, from: Data(json.utf8))
```

## Behavior

- Supports classes and structs.
- Adds identity-based `Hashable` conformance for classes.
- Ignores `static` and `class` properties.
- Ignores computed properties.
- Does nothing if `CodingKeys` is already defined.
- Ignores properties whose names already start with `_`.

## Scope

This package is intentionally focused on the current `@Observable` and `Codable` interaction that relies on underscored coding keys. If Swift's observable storage model changes, the implementation may need to evolve toward generating custom `init(from:)` and `encode(to:)` methods instead.
