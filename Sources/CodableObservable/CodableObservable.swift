@attached(member, names: named(CodingKeys))
@attached(extension, conformances: Hashable, names: named(==), named(hash(into:)))
public macro CodableObservable() = #externalMacro(
    module: "CodableObservableMacros",
    type: "CodableObservableMacro"
)
