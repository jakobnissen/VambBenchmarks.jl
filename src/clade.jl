# Type parameter G here is always Genome - I only make it parametric so I can have
# mutually recursive types b/w Clade and Genome
mutable struct Clade{G}
    name::String
    rank::Int
    ngenomes::Int
    parent::Union{Clade{G}, Nothing}
    children::Union{Vector{Clade{G}}, Vector{G}}

    function Clade(name::String, child::Union{Clade{G}, G}) where G
        (rank, ngenomes) = if child isa G
            (@isinit(child.parent)) && existing_parent_error(name, child.name, child.parent.name)
            (1, 1)
        else
            parent = child.parent
            parent === nothing || existing_parent_error(name, child.name, parent.name)
            (child.rank + 1, child.ngenomes)
        end
        instance = new{G}(name, rank, ngenomes, nothing, [child])
        child.parent = instance
        return instance
    end
end

@noinline function existing_parent_error(child_name, parent_name, other_parent_name)
    error("Attempted to add parent \"$parent_name\" to child \"$child_name\", which already has parent \"$other_parent_name\"")
end

const RANKS = [
    "OTU",
    "Species",
    "Genus",
    "Family",
    "Order",
    "Class",
    "Phylum",
    "Domain",
    "LUCA"
]

function Base.show(io::IO, x::Clade)
    suffix = x.ngenomes == 1 ? "" : "s"
    print(io, RANKS[x.rank + 1], " \"", x.name, "\", ", x.ngenomes, " genome", suffix)
end

function Base.show(io::IO, ::MIME"text/plain", x::Clade)
    if get(io, :compact, false)
        show(io, x)
    else
        buf = IOBuffer()
        AbstractTrees.print_tree(buf, x, maxdepth=3)
        seekstart(buf)
        for (i, line) in zip(1:25, eachline(buf))
            println(io, line)
            i == 25 && print(io, '⋮')
        end
    end
end

AbstractTrees.children(x::Clade) = x.children === nothing ? () : x.children
AbstractTrees.parent(x::Clade) = x.parent
AbstractTrees.treebreadth(x::Clade) = x.ngenomes
nchildren(x::Clade) = length(x.children)
istop(x::Clade) = isnothing(x.parent)
