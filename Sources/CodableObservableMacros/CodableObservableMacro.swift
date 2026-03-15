import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CodableObservableMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) || declaration.is(StructDeclSyntax.self) else {
            return []
        }

        let alreadyHasCodingKeys = declaration.memberBlock.members.contains { member in
            guard let enumDecl = member.decl.as(EnumDeclSyntax.self) else { return false }
            return enumDecl.name.text == "CodingKeys"
        }
        if alreadyHasCodingKeys {
            return []
        }

        var cases: [String] = []

        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

            let isStaticLike = varDecl.modifiers.contains { modifier in
                let text = modifier.name.text
                return text == "static" || text == "class"
            }
            if isStaticLike {
                continue
            }

            for binding in varDecl.bindings {
                if binding.accessorBlock != nil {
                    continue
                }

                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }

                let name = pattern.identifier.text
                if name.hasPrefix("_") {
                    continue
                }

                cases.append("    case _\(name) = \"\(name)\"")
            }
        }

        guard !cases.isEmpty else {
            return []
        }

        let codingKeysDecl = """
        enum CodingKeys: String, CodingKey {
        \(cases.joined(separator: "\n"))
        }
        """

        return [DeclSyntax(stringLiteral: codingKeysDecl)]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else {
            return []
        }

        let typeName = type.trimmedDescription
        return [
            try ExtensionDeclSyntax(
                """
                extension \(raw: typeName): Hashable {
                    public static func == (lhs: \(raw: typeName), rhs: \(raw: typeName)) -> Bool {
                        lhs === rhs
                    }

                    public func hash(into hasher: inout Hasher) {
                        hasher.combine(ObjectIdentifier(self))
                    }
                }
                """
            )
        ]
    }
}

@main
struct CodableObservablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableObservableMacro.self
    ]
}
