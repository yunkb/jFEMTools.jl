struct MeshEntity{dim}
  index::Int 
end 
const MeshVertex = MeshEntity{0}
const MeshEdge = MeshEntity{1}
const MeshFace = MeshEntity{2}

#M = dim + 1
struct MeshConectivity
  indices::NTuple
  offsets::NTuple
end

#dim1 = dim+1 (better solutions?)
struct PolytopalMesh2{dim,T,dim1} <: AbstractPolytopalMesh{dim,T}
  entities::NTuple{dim1, Int}
  vertices::Vector{Tensors.Vec{dim, T}} #   NTuple{dim, T}}
  geometry::Dict{NTuple{2,Int},MeshConectivity}
  # Sets
  entitysets::Dict{Int,Dict{String,Set{NTuple{2,Int}}}}
end

#Generic Interface
getfacet(mesh::PolytopalMesh2{dim}, facet) where {dim} = getcellsubentities(mesh,facet.cellidx,dim-1)[facet.idx]
getnfacetvertices(mesh::PolytopalMesh2{dim}, cell_idx, facet_lidx) where {dim} = getnvertices(mesh,getcellsubentities(mesh,cell_idx,dim-1)[facet_lidx])
reference_facet_vertices(mesh::PolytopalMesh2{dim},cell::MeshEntity{dim})  where {dim} = reference_facet_vertices(getCellType(mesh,cell.index))

"Return coordinates keeping orientation"
function getverticescoords(mesh::PolytopalMesh2{d}, edge::EdgeIndex) where {d}
  return [mesh.vertices[i] for i in _local_edgesD(mesh,MeshEntity{d}(edge.cellidx))[edge.idx]]
end

function getverticescoords(mesh::PolytopalMesh2{d}, cell::Int) where {d}
  return getverticescoords(mesh, MeshEntity{d}(cell))
end

getdim(mesh::PolytopalMesh2{dim}) where {dim} = dim

function get_cell_connectivity_list(mesh::PolytopalMesh2{dim}) where {dim}
  _unpack_connectivity(get_connectivity!(mesh,dim,0))
end

getnvertices(mesh::PolytopalMesh2{dim}, entity::MeshEntity{dim}) where {dim} = getnsubentities(mesh,entity,0)
getncellvertices(mesh::PolytopalMesh2{dim}, cell_idx::Int) where {dim} = getnvertices(mesh,MeshEntity{dim}(cell_idx))
getnfacets(mesh::PolytopalMesh2{dim}, cell_idx) where {dim} = getncellsubentities(mesh,cell_idx,dim-1)

function gettopology(mesh::PolytopalMesh2{dim}, cell::MeshEntity{dim}) where {dim}
  topology = Dict{Int,Int}()
  for i in 0:(dim-1)
    push!(topology, i => getncellsubentities(mesh,cell.index,i))
  end
  topology[dim] = 1
  return topology
end

getnedges(mesh::PolytopalMesh2{dim}, cell::MeshEntity{dim}) where {dim} = getncellsubentities(mesh,cell.index,1)
getnfaces(mesh::PolytopalMesh2{dim}, cell::MeshEntity{dim}) where {dim} = getncellsubentities(mesh,cell.index,2)

function reference_edge_vertices(mesh::PolytopalMesh2{dim}, cell::MeshEntity{dim}) where {dim}
  N = getnvertices(mesh,cell)
  return Tuple((i,mod1(i+1,N)) for i in 1:N)
end

getverticesindices(mesh::PolytopalMesh2{dim}, cell::MeshEntity{dim}) where {dim} = getsubentitiesindexes(mesh,cell,0)

#Common API
@inline getnentities(mesh::PolytopalMesh2,d) = mesh.entities[d+1]
function getentities(mesh::PolytopalMesh2, d)
  return [MeshEntity{d}(idx) for idx in 1:getnentities(mesh,d)]
end
getentityset(mesh::PolytopalMesh2, entity::Int, set::String) = mesh.entitysets[entity][set]

getncells(mesh::PolytopalMesh2{dim}) where {dim} = getnentities(mesh,dim)
getnvertices(mesh::PolytopalMesh2) = getnentities(mesh,0)
getvertexset(mesh::PolytopalMesh2, set::String) = getentityset(mesh,0,set)
getedgeset(mesh::PolytopalMesh2, set::String) = getentityset(mesh,1,set)
getfacetset(mesh::PolytopalMesh2{dim}, set::String) where {dim} = getentityset(mesh,dim-1,set)
getcells(mesh::PolytopalMesh2{dim}) where {dim} = getentities(mesh,dim)
getcell(mesh::PolytopalMesh2{dim}, idx::Int) where {dim} = (1<= idx <= getncells(mesh) ? MeshEntity{dim}(idx) : error("cell index out of bounds"))
function getCellType(mesh::PolytopalMesh2{dim}, idx::Int) where {dim}
  return Cell{dim, getncellsubentities(mesh,idx,0), getncellsubentities(mesh,idx,1), getncellsubentities(mesh,idx,2)}
end
getvertices(mesh::PolytopalMesh2) = getentities(mesh,0)
getedges(mesh::PolytopalMesh2) = getentities(mesh,1)
getfacets(mesh::PolytopalMesh2{dim}) where {dim} = getentities(mesh,dim-1)

function getcellsubentities(mesh::PolytopalMesh2{dim},cellidx,entity::Int) where {dim}
  connectivity = get_connectivity!(mesh,dim,entity)
  return [MeshEntity{entity}(idx) for idx in get_entity_indices(connectivity,cellidx)]
end

function getsubentitiesindexes(mesh::PolytopalMesh2,entity::MeshEntity{d1},d2::Int) where {d1}
  connectivity = get_connectivity!(mesh,d1,d2)
  return get_entity_indices(connectivity,entity.index)
end

function getncellsubentities(mesh::PolytopalMesh2{dim},cellidx,entity::Int) where {dim}
  entity == dim && return 1
  connectivity = get_connectivity!(mesh,dim,entity)
  return connectivity.offsets[cellidx+1] - connectivity.offsets[cellidx]
end

function getnsubentities(mesh::PolytopalMesh2,entity::MeshEntity{d1},d2::Int) where {d1}
  connectivity = get_connectivity!(mesh,d1,d2)
  return connectivity.offsets[entity.index+1] - connectivity.offsets[entity.index]
end

getvertexcoords(mesh::PolytopalMesh2, vertex_idx::Int) = mesh.vertices[vertex_idx]

function getverticescoords(mesh::PolytopalMesh2, entity::MeshEntity)
  return [mesh.vertices[i] for i in getverticesidx(mesh, entity)]
end

function getvertexcoords(mesh::PolytopalMesh2, entity::MeshEntity, vidx::Int)
  return mesh.vertices[getverticesidx(mesh, entity)[vidx]]
end
function getnvertices(mesh::PolytopalMesh2,entity::MeshEntity{d}) where{d}
  connectivity = get_connectivity!(mesh,d,0)
  idx = entity.index
  return connectivity.offsets[idx+1] - connectivity.offsets[idx]
end

entityeltype(mesh::PolytopalMesh2, dim) = MeshEntity{dim}

#Internal
function get_entity_name(entity,dim)
  if entity == 0
    return "vertex"
  elseif entity > 0 && entity < dim
    if entity == 1
      return "edge"
    elseif entity == 2
      return "face"
    end
  elseif entity == dim
    return "cell"
  else
    return "dim $entity"
  end
end
@inline get_entity_indices(connectivity, idx) = connectivity.indices[connectivity.offsets[idx]:connectivity.offsets[idx+1]-1]
function getverticesidx(mesh::PolytopalMesh2{dim}, entity::MeshEntity{d}) where {dim,d}
  connectivity = get_connectivity!(mesh,d,0)
  return get_entity_indices(connectivity,entity.index)
end

function getentities(mesh::PolytopalMesh2, d2, d1, entity)
  connectivity = get_connectivity!(mesh,d2,d1)
  return [MeshEntity{d1}(i) for i in get_entity_indices(connectivity,entity.index)]
end

function _pack_connectivity(indices_mat)
  offsets = [1]
  k = 1
  indices = []
  for x in indices_mat
    k = k + size(x,1)
    push!(offsets,k)
    push!(indices,x...)
  end
  MeshConectivity(Tuple(indices), Tuple(offsets))
end

function _unpack_connectivity(connectivity::MeshConectivity)
  return [get_entity_indices(connectivity,i) for i in 1:(size(connectivity.offsets,1)-1)]
end

# Compute d1 -> d2 from d2 -> d1
function _transpose(mesh, d2, d1)
  indices = [Int[] for _ in 1:getnentities(mesh,d1)]
  for entity_j in getentities(mesh,d2)
    for entity_i in getentities(mesh,d2,d1,entity_j)
      push!(indices[entity_i.index], entity_j.index)
    end
  end
  _pack_connectivity(indices)
end

# Compute d1 -> d2 from d1 -> d3 and d3 -> d2
function _intersection(mesh,d1,d2,d3)
  indices = [Int[] for _ in 1:getnentities(mesh,d1)]
  for entity_i in getentities(mesh,d1)
    for entity_k in getentities(mesh,d1,d3,entity_i)
      for entity_j in getentities(mesh,d3,d2,entity_k)
        if (d1 == d2 && entity_i.index != entity_j.index) || 
          (d1 > d2 && all(x in getentities(mesh,d1,0,entity_i) for x in getentities(mesh,d2,0,entity_j)))
          if !(entity_j.index in indices[entity_i.index]) 
            push!(indices[entity_i.index], entity_j.index)
          end
        end
      end
    end
  end
  _pack_connectivity(indices)
end

function _local_edgesD(mesh::PolytopalMesh2{2},cell)
  indices = getverticesidx(mesh,cell)
  N = size(indices,1)
  idx = Tuple((i,mod1(i+1,N)) for i in 1:N)
  return [[indices[x[1]],indices[x[2]]] for x in idx]
end

#Compute D -> d and d -> 0 from D -> 0 and D -> D for 0 < d < D
function _build!(mesh::PolytopalMesh2{D},d) where {D}
  indices1 = [Int[] for _ in 1:getnentities(mesh,D)]
  indices2 = [Int[] for _ in 1:getnentities(mesh,d)]
  if d == 1
    edgesDict = Dict{Set{Int},Int}()
    nextidx = 1 #first edge index
    for cell in getentities(mesh,D)
      Vi = _local_edgesD(mesh, cell)
      for vi in Vi
        token = Base.ht_keyindex2!(edgesDict, Set(vi))
        if token > 0 # reuse edge index
          reuse_idx = edgesDict.vals[token]
          push!(indices1[cell.index], reuse_idx)    #sign is used for orientation
        else
          push!(indices1[cell.index], nextidx)
          indices2[nextidx] = vi
          Base._setindex!(edgesDict, nextidx, Set(vi), -token)
          nextidx += 1
        end
      end
    end
  #TODO if d == 2
  else
    error("Automatic construction of entities of dim $d failed")
  end
  V = _pack_connectivity(indices1)
  push!(mesh.geometry,(D,d)=>V)
  V = _pack_connectivity(indices2)
  push!(mesh.geometry,(d,0)=>V)
end

function get_connectivity!(mesh::PolytopalMesh2{D},d1::Int,d2::Int) where {D}
  if (0 < d1 < D) && !haskey(mesh.geometry,(d1,0))
      _build!(mesh,d1)
  elseif (d1 != d2) && (0 < d2 < D) && !haskey(mesh.geometry,(d2,0))
      _build!(mesh,d2)
  end
  if haskey(mesh.geometry,(d1,d2))
    get(mesh.geometry,(d1,d2),nothing)
  else
    if d1 < d2
      V = get_connectivity!(mesh,d2,d1)
      V = _transpose(mesh,d2,d1)
    else
      d3 = (d1 == 0 && d2 == 0) ? D : 0
      V = get_connectivity!(mesh,d1,d3)
      V = get_connectivity!(mesh,d3,d2)
      V = _intersection(mesh,d1,d2,d3)
    end
    push!(mesh.geometry,(d1,d2)=>V)
    return V
  end
end