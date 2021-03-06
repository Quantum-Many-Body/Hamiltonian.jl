module VectorSpaces

using ...Prerequisites.Traits: rawtype, efficientoperations, getcontent, hascontent

import ...Interfaces: dimension, rank
import ...Prerequisites.Traits: contentnames

export VectorSpace, EnumerativeVectorSpace, CartesianVectorSpace, NamedVectorSpace

"""
    VectorSpace{B} <: AbstractVector{B}

Abstract vector space.
"""
abstract type VectorSpace{B} <: AbstractVector{B} end
@inline Base.:(==)(vs1::VectorSpace, vs2::VectorSpace) = ==(efficientoperations, vs1, vs2)
@inline Base.isequal(vs1::VectorSpace, vs2::VectorSpace) = isequal(efficientoperations, vs1, vs2)
@inline Base.size(vs::VectorSpace) = (dimension(vs),)
@inline Base.iterate(vs::VectorSpace, state::Integer=1) = state>length(vs) ? nothing : (vs[state], state+1)
@inline Base.issorted(vs::VectorSpace) = false
@inline function Base.findfirst(basis::B, vs::VectorSpace{B}) where B
    if issorted(vs)
        index = invoke(searchsortedfirst, Tuple{Any, Any}, vs, basis)
        return (0<index<=length(vs) && vs[index]==basis) ? index : nothing
    end
    for i = 1:length(vs)
        vs[i]==basis && return i
    end
end
@inline function Base.searchsortedfirst(vs::VectorSpace{B}, basis::B) where B
    issorted(vs) && return invoke(searchsortedfirst, Tuple{Any, Any}, vs, basis)
    for i = 1:length(vs)
        vs[i]==basis && return i
    end
    return length(vs)+1
end
@inline Base.in(basis::B, vs::VectorSpace{B}) where B = isa(findfirst(basis, vs), Integer)

"""
    EnumerativeVectorSpace{B} <: VectorSpace{B}

Abstract enumerative vector space.
"""
abstract type EnumerativeVectorSpace{B} <: VectorSpace{B} end
@inline contentnames(::Type{<:EnumerativeVectorSpace}) = (:table,)
@inline dimension(vs::EnumerativeVectorSpace) = length(getcontent(vs, :table))
@inline Base.getindex(vs::EnumerativeVectorSpace, i::Int) = getcontent(vs, :table)[i]

"""
    CartesianVectorSpace{B} <: VectorSpace{B}

Abstract Cartesian vector space.
"""
abstract type CartesianVectorSpace{B} <: VectorSpace{B} end
@inline dimension(vs::CartesianVectorSpace) = prod(Dims(vs))
@inline Base.getindex(vs::CartesianVectorSpace, i::CartesianIndex) = rawtype(eltype(vs))(i, vs)
@inline Base.getindex(vs::CartesianVectorSpace, i::Int) = getindex(vs, CartesianIndices(Dims(vs))[i])
@inline Base.issorted(vs::CartesianVectorSpace) = true
function Base.iterate(vs::CartesianVectorSpace)
    idx = CartesianIndices(Dims(vs))
    index = iterate(idx)
    isnothing(index) && return nothing
    return rawtype(eltype(vs))(index[1], vs), (idx, index[2])
end
function Base.iterate(vs::CartesianVectorSpace, state)
    index = iterate(state[1], state[2])
    isnothing(index) && return nothing
    return rawtype(eltype(vs))(index[1], vs), (state[1], index[2])
end
@inline function Base.findfirst(basis::B, vs::CartesianVectorSpace{B}) where B
    index, idx = CartesianIndex(basis, vs), CartesianIndices(Dims(vs))
    index∉idx && return nothing
    return LinearIndices(Dims(vs))[index]
end
@inline function Base.searchsortedfirst(vs::CartesianVectorSpace{B}, basis::B) where B
    index, idx = CartesianIndex(basis, vs), CartesianIndices(Dims(vs))
    index∈idx && return LinearIndices(Dims(vs))[index]
    return searchsortedfirst(idx, index)
end
@inline Base.in(basis::B, vs::CartesianVectorSpace{B}) where B = CartesianIndex(basis, vs)∈CartesianIndices(Dims(vs))

"""
    NamedVectorSpace{M, NS, BS<:Tuple, VS<:Tuple{Vararg{AbstractVector}}} <: CartesianVectorSpace{NamedTuple{NS, BS}}

Abstract named vector space.

This is a wrapper of Cartesian indexable vector spaces, each of whose indexable dimensions is associated with a name.

It has four type parameters:
* `M`: mode of the named vector space. It specifies how the indexable dimensions are combined to form the bases of the named vector space, and must take one of the following values:
  - `:⊕`: elements from each indexable dimensions are zipped together to form the bases,
  - `:⊗`: elements from each indexable dimensions are direct producted together to form the bases.
For the `:⊕` mode, all the indexable dimensions should have the same number of elements, and the number of formed bases is equal to this number; for the `:⊗` mode, there are no restriction on the numbers of the indexable dimensions, and the number of the final bases is equal to their product.
* `NS::Tuple{Vararg{Symbol}}`: the names of the indexable dimensions
* `BS<:Tuple`: the eltypes of the indexable dimensions
* `VS<:Tuple{Vararg{AbstractVector}}`: the contents of the indexable dimensions

The subtypes must have the following predefined content:
* `:contents::VS`: storage of the contents of the indexable dimensions
"""
abstract type NamedVectorSpace{M, NS, BS<:Tuple, VS<:Tuple{Vararg{AbstractVector}}} <: CartesianVectorSpace{NamedTuple{NS, BS}} end
@inline contentnames(::Type{<:NamedVectorSpace}) = (:contents,)
@inline rank(::Type{<:NamedVectorSpace{:⊕}}) = 1
@inline rank(::Type{<:NamedVectorSpace{:⊗, NS}}) where NS = length(NS)
@inline Base.Dims(nvs::NamedVectorSpace{:⊕}) = (length(getcontent(nvs, :contents)[1]),)
@inline @generated Base.Dims(nvs::NamedVectorSpace{:⊗}) = Expr(:tuple, [:(length(getcontent(nvs, :contents)[$i])) for i = 1:rank(nvs)]...)
@inline function Base.CartesianIndex(basis::NamedTuple{NS}, nvs::NamedVectorSpace{:⊕, NS}) where NS
    index = findfirst(isequal(basis[1]), getcontent(nvs, :contents)[1])::Int
    for i = 2:length(NS)
        @assert getcontent(nvs, :contents)[i][index] == basis[i] "CartesianIndex error: input basis out of range."
    end
    return CartesianIndex(index)
end
@inline @generated function Base.CartesianIndex(basis::NamedTuple{NS, BS}, nvs::NamedVectorSpace{:⊗, NS, BS}) where {NS, BS<:Tuple}
    return Expr(:call, :CartesianIndex, [:(findfirst(isequal(basis[$i]), getcontent(nvs, :contents)[$i])::Int) for i = 1:length(NS)]...)
end
@inline @generated function Base.NamedTuple(index::CartesianIndex{1}, nvs::NamedVectorSpace{:⊕, NS}) where NS
    return Expr(:tuple, [:($name=getcontent(nvs, :contents)[$i][index[1]]) for (i, name) in enumerate(NS)]...)
end
@inline @generated function Base.NamedTuple(index::CartesianIndex{N}, nvs::NamedVectorSpace{:⊗, NS}) where {N, NS}
    @assert N == length(NS) "NamedTuple error: dismatched input index and rank of named vector space."
    return Expr(:tuple, [:($name=getcontent(nvs, :contents)[$i][index[$i]]) for (i, name) in enumerate(NS)]...)
end

"""
    keys(nvs::NamedVectorSpace) -> Tuple{Vararg{Symbol}}
    keys(::Type{<:NamedVectorSpace{M, NS} where M}) where NS -> Tuple{Vararg{Symbol}}

Get the names of a named vector space.
"""
@inline Base.keys(nvs::NamedVectorSpace) = keys(typeof(nvs))
@inline Base.keys(::Type{<:NamedVectorSpace{M, NS} where M}) where {NS} = NS

"""
    values(nvs::NamedVectorSpace) -> Tuple{Vararg{AbstractVector}}

Get the contents of a named vector space.
"""
@inline Base.values(nvs::NamedVectorSpace) = getcontent(nvs, :contents)

"""
    pairs(nvs::NamedVectorSpace) -> Base.Iterators.Pairs

Get the name-value pairs of a named vector space.
"""
@inline Base.pairs(nvs::NamedVectorSpace) = Base.Generator(=>, nvs|>keys, nvs|>values)

"""
    eltype(nvs::NamedVectorSpace, i::Int)
    eltype(::Type{<:NamedVectorSpace{M, NS, BS} where {M, NS}}, i::Int) where BS

Get the eltype of the ith indexable dimensions of a named vector space.
"""
@inline Base.eltype(nvs::NamedVectorSpace, i::Int) = eltype(nvs|>typeof, i)
@inline Base.eltype(::Type{<:NamedVectorSpace{M, NS, BS} where {M, NS}}, i::Int) where BS = fieldtype(BS, i)

end # module
