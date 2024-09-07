package bang

foreign import "lib/mesh_loader.lib"

import gl "vendor:OpenGL"
import "core:fmt"
import "core:strings"
import "core:math/linalg"

MaterialData :: struct {
	ambient: [3]f32,
	diffuse: [3]f32,
	specular: [3]f32,
	shininess: f32,
}

MeshData :: struct {
	vertices: [][3]f32,
	indices: []i32,
	texCoords: [][2]f32,
	colors: [][4]f32,
	normals: [][3]f32,
	material: MaterialData
}

blank_material :: proc() -> MaterialData {
	return MaterialData{ambient = [3]f32{0.0, 0.0, 0.0}, diffuse = [3]f32{0.6, 0.6, 0.6}, specular = [3]f32{0.0, 0.0, 0.0}, shininess = 0.0};
}

foreign mesh_loader {
	load_mesh_data :: proc(filename: cstring) -> MeshData ---;
	free_mesh_data :: proc(mesh_data: ^MeshData) ---;
}

Mesh :: struct {
	using base : Component,
	vao: u32,
	vbo: u32,
	ebo: u32,
	vertex_count: i32
}

Vertex :: struct {
    position: linalg.Vector3f32,
    normal: linalg.Vector3f32,
    uv: linalg.Vector2f32,
}

convert_vertices :: proc(input_vertices: [][3]f32) -> []Vertex {
    vertices := make([]Vertex, len(input_vertices))

    for v, i in input_vertices {
        vertices[i] = Vertex{
            position = linalg.Vector3f32{v[0], v[1], v[2]},
            normal = linalg.Vector3f32{0, 1, 0},  // Default normal pointing up
            uv = linalg.Vector2f32{0, 0},         // Default UV coordinate
        }
    }
    return vertices
}

build_mesh_component :: proc (ass_path : string) -> (Mesh, Maybe(MaterialData)) {
	cpath := strings.clone_to_cstring(ass_path)
	mesh_data := load_mesh_data(cpath);
	defer free_mesh_data(&mesh_data)
	mesh := Mesh{
		ctype = .Mesh
	}

	vertices := convert_vertices(mesh_data.vertices)
	mesh.vertex_count = i32(len(vertices))

	vao, vbo, ebo: u32
	// Create OpenGL buffers
    gl.GenVertexArrays(1, &mesh.vao)
    gl.GenBuffers(1, &mesh.vbo)
    gl.GenBuffers(1, &mesh.ebo)
	// fmt.println("successfully created OpenGL buffers")
	
    // Set up vertex data
    gl.BindVertexArray(mesh.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(Vertex), &vertices[0], gl.STATIC_DRAW)
    
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(mesh_data.indices) * size_of(i32), &mesh_data.indices[0], gl.STATIC_DRAW)
    // fmt.println("successfully set up vertex data")
    // Set up vertex attributes
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, position))
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, normal))
    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, uv))
	// fmt.println("successfully set up vertex attributes")

	// only some obj files will include material references, but the assimp loader should parse them if they exist
	if mesh_data.material == blank_material() {
		return mesh, nil
	} else {
		return mesh, mesh_data.material
	}
}

get_mesh :: proc(sg: ^SceneGraph, eid: EntityID) -> ^Mesh { 
	for m in sg.Components[.Mesh] {
		if m.eid == eid {
			return cast(^Mesh)m
		}
	}
	return nil
}

cleanup_meshes :: proc(sg: ^SceneGraph) {
	for &m in sg.Components[.Mesh] {
		mesh := cast(^Mesh)&m
		gl.DeleteVertexArrays(1, &mesh.vao)
        gl.DeleteBuffers(1, &mesh.vbo)
		gl.DeleteBuffers(1, &mesh.ebo)
	}
}