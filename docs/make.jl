push!(LOAD_PATH,"../src/")

using Documenter
using DocumenterTools
using QuantumLattices

makedocs(
    format=     Documenter.HTML(
                    prettyurls= !("local" in ARGS),
                    canonical=  "https://quantum-many-body.github.io/QuantumLattices.jl/latest/",
                    assets=     ["assets/favicon.ico"],
                    analytics=  "UA-89508993-1",
                    ),
    clean=      false,
    sitename=   "QuantumLattices.jl",
    pages=      [
                "Home"      =>  "index.md",
                "Tutorials" =>  [
                    "Unitcell Description" => [
                        "tutorials/UnitcellDescription/Introduction.md",
                        "tutorials/UnitcellDescription/SpatialInfoOfAUnitcell.md",
                        "tutorials/UnitcellDescription/InternalDegreesOfFreedom.md",
                        "tutorials/UnitcellDescription/CouplingsAmongDifferentDegreesOfFreedom.md",
                        "tutorials/UnitcellDescription/GeneratorOfOperators.md",
                    ],
                    "Engine App Interface" => [
                        "tutorials/EngineAppInterface/Introduction.md",
                    ]
                ],
                "Manual"    =>  [
                    "man/Interfaces.md",
                    "Prerequisites" => [
                        "man/Prerequisites/Introduction.md",
                        "man/Prerequisites/Traits.md",
                        "man/Prerequisites/CompositeStructures.md",
                        "man/Prerequisites/SimpleTrees.md",
                        "man/Prerequisites/NamedVectors.md",
                        ],
                    "Mathematics" => [
                        "man/Mathematics/Introduction.md",
                        "man/Mathematics/Combinatorics.md",
                        "man/Mathematics/VectorSpaces.md",
                        "man/Mathematics/AlgebraOverFields.md",
                        "man/Mathematics/QuantumNumbers.md",
                        ],
                    "Essentials" => [
                        "man/Essentials/Introduction.md",
                        "man/Essentials/Spatials.md",
                        "man/Essentials/DegreesOfFreedom.md",
                        "man/Essentials/Terms.md",
                        "man/Essentials/FockPackage.md",
                        "man/Essentials/SpinPackage.md",
                        "man/Essentials/Frameworks.md",
                        ],
                    ],
                "Developer Documentation"   =>  [
                    "developer/CodeStyle.md",
                    ]
                ]
)

deploydocs(
    repo=       "github.com/Quantum-Many-Body/QuantumLattices.jl.git",
    target=     "build",
    deps=       nothing,
    make=       nothing,
)
