#Makie
import AbstractPlotting
import AbstractPlotting: Plot, default_theme, plot!, SceneLike, Theme, to_value, Point2f0, poly!


function default_theme(scene::SceneLike, ::Type{<: Plot(Union{PolytopalMesh,PolytopalMesh2})})
     Theme(
        color = :white, strokewidth = 1, strokecolor = :black, colorrange=(0.0,1.0)
     )
 end

 function AbstractPlotting.plot!(p::Plot(Union{PolytopalMesh,PolytopalMesh2}))
     mesh = to_value(p[1])
     coordinates = get_vertices_matrix(mesh);
     connectivity = get_cell_connectivity_list(mesh);
     u = to_value(p[:color])
     for row in 1:getncells(mesh)
     	#read coordinates
     	points = Point2f0[coordinates[node,:] for node in connectivity[row]]#AbstractPlotting.node(:poly, Point2f0[coordinates[node,:] for node in connectivity[row]])
        if typeof(u) <: Array
            node_colors = [u[i] for i in connectivity[row]]
        else
            node_colors = p[:color]
        end
     	poly!(p, points, strokewidth = p[:strokewidth], color = node_colors,
            strokecolor = p[:strokecolor], colorrange = p[:colorrange])
     end
 end