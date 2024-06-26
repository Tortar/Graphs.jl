"""
    BFSIterator

`BFSIterator` is used to iterate through graph vertices using a breadth-first search. 
A source node(s) is optionally supplied as an `Int` or an array-like type that can be 
indexed if supplying multiple sources.
    
# Examples
```julia-repl
julia> g = smallgraph(:house)
{5, 6} undirected simple Int64 graph

julia> for node in BFSIterator(g,3)
           display(node)
       end
3
1
4
5
2
```
"""
struct BFSIterator{S,G<:AbstractGraph}
    graph::G
    source::S
    function BFSIterator(graph::G, source::S) where {S,G}
        if any(node -> !has_vertex(graph, node), source)
            error("Some source nodes for the iterator are not in the graph")
        end
        return new{S,G}(graph, source)
    end
end

"""
    BFSVertexIteratorState

`BFSVertexIteratorState` is a struct to hold the current state of iteration
in BFS which is needed for the `Base.iterate()` function. We use two vectors,
one for the current level nodes and one from the next level nodes to visit 
the graph. Since new levels can contains repetitions of already visited nodes, 
we also keep track of that in a `BitVector` so as to skip those nodes.
"""
mutable struct BFSVertexIteratorState
    visited::BitVector
    curr_level::Vector{Int}
    next_level::Vector{Int}
    node_idx::Int
    n_visited::Int
end

Base.IteratorSize(::BFSIterator) = Base.SizeUnknown()
Base.eltype(::Type{BFSIterator{S,G}}) where {S,G} = eltype(G)

"""
    Base.iterate(t::BFSIterator)

First iteration to visit vertices in a graph using breadth-first search.
"""
function Base.iterate(t::BFSIterator{<:Integer})
    visited = falses(nv(t.graph))
    visited[t.source] = true
    state = BFSVertexIteratorState(visited, [t.source], Int[], 0, 0)
    return Base.iterate(t, state)
end

function Base.iterate(t::BFSIterator{<:AbstractArray})
    visited = falses(nv(t.graph))
    curr_level = unique(s for s in t.source)
    sort!(curr_level)
    visited[curr_level] .= true
    state = BFSVertexIteratorState(visited, curr_level, Int[], 0, 0)
    return Base.iterate(t, state)
end

"""
    Base.iterate(t::BFSIterator, state::VertexIteratorState)

Iterator to visit vertices in a graph using breadth-first search.
"""
function Base.iterate(t::BFSIterator, state::BFSVertexIteratorState)
    # we fill nodes in this level
    if state.node_idx == length(state.curr_level)
        state.n_visited += length(state.curr_level)
        state.n_visited == nv(t.graph) && return nothing
        @inbounds for node in state.curr_level
            for adj_node in outneighbors(t.graph, node)
                if !state.visited[adj_node]
                    push!(state.next_level, adj_node)
                    state.visited[adj_node] = true
                end
            end
        end
        length(state.next_level) == 0 && return nothing
        state.curr_level, state.next_level = state.next_level, empty!(state.curr_level)
        sort!(state.curr_level)
        state.node_idx = 0
    end
    # we visit all nodes in this level
    state.node_idx += 1
    @inbounds node = state.curr_level[state.node_idx]
    return (node, state)
end
