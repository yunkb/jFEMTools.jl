abstract type AbstractCell{dim,V,F} end

# Vertices
struct Vertex{dim,T}
    x::Tensors.Vec{dim, T}
end

@inline get_coordinates(vertex::Vertex) = vertex.x

#--------------- Cells
struct Cell{dim, N, M, L}
    vertices::NTuple{N,Int}
end

#Common cell types
const TriangleCell = Cell{2,3,3,1}
@inline get_cell_name(::TriangleCell) = "Triangle"
@inline reference_edge_vertices(::TriangleCell) = ((2,3),(3,1),(1,2))

const RectangleCell = Cell{2,4,4,1}
@inline get_cell_name(::RectangleCell) = "Rectangle"
@inline reference_edge_vertices(::RectangleCell) = ((1,2),(2,3),(3,4),(4,1))

@inline reference_edge_vertices(::Cell{2,N,N,1})  where {N} = Tuple((i,mod1(i+1,N)) for i in 1:N)

const HexagonCell = Cell{2,6,6,1}
@inline get_cell_name(::HexagonCell) = "Hexagon"

# API
@inline getnvertices(cell::Cell{dim,N}) where {dim,N} = N
@inline getnedges(cell::Cell{dim,N,M}) where {dim,N,M} = M
@inline getnfaces(cell::Cell{dim,N,M,P}) where {dim,N,M,P} = P
gettopology(cell::Cell{1,N,M,P}) where {N,M,P} = Dict(0=>N,1=>M)
gettopology(cell::Cell{2,N,M,P}) where {N,M,P} = Dict(0=>N,1=>M,2=>P)
gettopology(cell::Cell{3,N,M,P}) where {N,M,P} = Dict(0=>N,1=>M,2=>P,3=>1)

# ----------------- Mesh
struct PolytopalMesh{dim,T,C} <: AbstractPolytopalMesh{dim,T}
    cells::Vector{C}
    vertices::Vector{Vertex{dim,T}}
    # Sets
    cellsets::Dict{String,Set{Int}}
    facesets::Dict{String,Set{FaceIndex}}
    edgesets::Dict{String,Set{EdgeIndex}}
    vertexsets::Dict{String,Set{Int}}
end

function PolytopalMesh(cells,
              vertices;
              cellsets::Dict{String,Set{Int}}=Dict{String,Set{Int}}(),
              facesets::Dict{String,Set{FaceIndex}}=Dict{String,Set{FaceIndex}}(),
              edgesets::Dict{String,Set{EdgeIndex}}=Dict{String,Set{EdgeIndex}}(),
              vertexsets::Dict{String,Set{Int}}=Dict{String,Set{Int}}()) where {dim}
    return PolytopalMesh(cells, vertices, cellsets, facesets, edgesets, vertexsets)
end

# Generic Interface
getfacet(mesh::PolytopalMesh, facet) = facet
getdim(mesh::PolytopalMesh{dim}) where {dim} = dim
getncellvertices(mesh::PolytopalMesh, cell_idx::Int) = getnvertices(mesh.cells[cell_idx])
gettopology(mesh::PolytopalMesh, cell::Cell) = gettopology(cell)
getnvertices(mesh::PolytopalMesh, cell::Cell) = getnvertices(cell)
getnegdes(mesh::PolytopalMesh, cell::Cell) = getnedges(cell)

function getcellsubentities(mesh::PolytopalMesh{2},cellidx::Int,element::Int)
  if element == 0
      return mesh.cells[cellidx].vertices
  elseif element == 1
      return Tuple(EdgeIndex(cellidx,i) for i in 1:getnedges(mesh.cells[cellidx]))
  else
      throw("Topology element of order $element not available for cell type")
  end
end

function entityeltype(mesh::PolytopalMesh{2},dim)
    if dim == 0
        return Int
    elseif dim == 1
        return EdgeIndex
    else
        error("mesh $mesh has not entity of dim $dim")
    end
end

reference_edge_vertices(mesh::PolytopalMesh, cell::Cell) = reference_edge_vertices(cell)


# API

@inline getncells(mesh::PolytopalMesh) = length(mesh.cells)
@inline getnvertices(mesh::PolytopalMesh) = length(mesh.vertices)
@inline getverticesidx(mesh::PolytopalMesh, cell_idx) = mesh.cells[cell_idx].vertices
@inline getvertexset(mesh::PolytopalMesh, set::String) = mesh.vertexsets[set]
@inline getedgeset(mesh::PolytopalMesh, set::String) = mesh.edgesets[set]
getcells(mesh::PolytopalMesh) = mesh.cells

"""
function getcoords(mesh, vertex_idx::Int)
Return a Tensor.Vec with the coordinates of vertex with index `vertex_idx`
"""
getvertexcoords(mesh::PolytopalMesh, vertex_idx::Int) = mesh.vertices[vertex_idx].x

"""
    getverticescoords(mesh::PolytopalMesh, cell_idx)
Return a vector with the coordinates of the vertices of cell number `cell`.
"""
function getverticescoords(mesh::PolytopalMesh{dim,T}, cell_idx::Int) where {dim,T}
    N = getnvertices(mesh.cells[cell_idx])
    coords = Vector{Tensors.Vec{dim,T}}(undef, N)
    for (i,j) in enumerate(mesh.cells[cell_idx].vertices)
        coords[i] = mesh.vertices[j].x
    end
    return coords
end

function getvertexcoords(mesh::PolytopalMesh{dim,T}, cell::Cell, vidx::Int) where {dim,T}
    return mesh.vertices[cell.vertices[vidx]].x
end

function getverticescoords(mesh::PolytopalMesh{dim,T}, edge_idx::EdgeIndex) where {dim,T}
    cell = getcells(mesh)[edge_idx.cellidx]
    ref_edge = reference_edge_vertices(typeof(cell))[edge_idx.idx]
    coords = Vector{Tensors.Vec{dim,T}}(undef, 2)
    for i in 1:2
        coords[i] = mesh.vertices[cell.vertices[ref_edge[i]]].x
    end
    return coords
end

function getverticesindices(mesh::PolytopalMesh{dim,T}, edge_idx::EdgeIndex) where {dim,T}
    cell = getcells(mesh)[edge_idx.cellidx]
    ref_edge = reference_edge_vertices(typeof(cell))[edge_idx.idx]
    return [cell.vertices[ref_edge[i]] for i in 1:2]
end

function get_cell_connectivity_list(mesh::PolytopalMesh{dim,T,C}) where {dim,T,C}
    cells_m = Vector()
    for k = 1:getncells(mesh)
        push!(cells_m,mesh.cells[k].vertices)
    end
    cells_m
end

getverticesindices(mesh::PolytopalMesh,cell::Cell) = cell.vertices
