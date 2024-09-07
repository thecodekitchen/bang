package bang

import glfw "vendor:glfw"
import "core:math"
import "core:math/linalg"
import "core:fmt"
import "core:time"
import gl "vendor:OpenGL"

Renderer :: struct {
    projection_matrix : matrix[4,4]f32,
    view_matrix : matrix[4,4]f32,
    model_matrix: matrix[4,4]f32,
}



render_scene :: proc(sg: ^SceneGraph, window: glfw.WindowHandle) -> Error {
    // This will be replaced with a skybox later
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    projection := sg.Renderer.projection_matrix
    
    // if update_view_matrix(sg, main_cam) == false {
    //     fmt.println("renderer failed to update view matrix")
    //     return false
    // }
    
    main_cam := get_main_camera(sg)
    if main_cam == nil {
        return error(.NilPtr, "failed to get main camera")
    }
    err := render_objects(sg, &projection, main_cam, window)
    if !ok(err) {
        return error(err.t, "failed to render objects")
    }
    clear_input_manager(sg.InputManager)
    return good()
}

render_objects :: proc(sg: ^SceneGraph, projection: ^matrix[4,4]f32, main_cam: ^Camera, window: glfw.WindowHandle) -> Error {
    for e in sg.Entities {
        if entity_is_camera(sg, e) || entity_is_light(sg, e) {
            // debug_log("found light or camera, continuing")
            continue
        }
        model := update_model_matrix(sg, e)
        view := sg.Renderer.view_matrix
        mesh := get_mesh(sg, e)
        material := get_material(sg, e)
        if mesh == nil {
            m := fmt.tprintf("mesh not found for entity %d", e)
            return error(.NilPtr, m)
        } 
        if material == nil {
            m := fmt.tprintf("material not found for entity %d", e)
            return error(.NilPtr, m)
        }
        err := render_advanced_material(sg, material, &model, &view, projection)
        if  !ok(err) {
            return error(err.t, "failed to render advanced material")
        }

        gl.BindVertexArray(mesh.vao)
        gl.DrawArrays(gl.TRIANGLES, 0, mesh.vertex_count)
    }
    return good()
}

render_basic_material :: proc(material: ^Material, model, view, projection: ^matrix[4,4]f32) -> Error {

    gl.UseProgram(material.shader_program)
    if err := gl.GetError(); err != gl.NO_ERROR {
        m := fmt.tprintf("OpenGL error using shader program: %v\n", err)
        return error(.GL, m )
    }
    gl.UniformMatrix4fv(material.shader_var_locs["model"], 1, gl.FALSE, &model[0, 0])
    if err := gl.GetError(); err != gl.NO_ERROR {
        m := fmt.tprintf("OpenGL error setting model matrix: %v\n", err)
        return error(.GL, m )
    }
    gl.UniformMatrix4fv(material.shader_var_locs["view"], 1, gl.FALSE, &view[0,0])
    if err := gl.GetError(); err != gl.NO_ERROR {
        m := fmt.tprintf("OpenGL error setting view matrix: %v\n", err)
        return error(.GL, m )
    }
    gl.UniformMatrix4fv(material.shader_var_locs["projection"], 1, gl.FALSE, &projection[0,0])
    if err := gl.GetError(); err != gl.NO_ERROR {
        m := fmt.tprintf("OpenGL error setting projection matrix: %v\n", err)
        return error(.GL, m )
    }
    return good()
}

render_advanced_material :: proc(sg: ^SceneGraph, material: ^Material, model, view, projection: ^matrix[4,4]f32) -> Error {
    if material.props == nil {
        return error(.InvalidType, "material props not set")
    }
    
    gl.UseProgram(material.shader_program)
    if err := gl.GetError(); err != gl.NO_ERROR {
        return error(.GL, "OpenGL error using shader program: %v", err)
    }
    
    ambient := material.props.?.ambient
    diffuse := material.props.?.diffuse
    specular := material.props.?.specular
    shininess := material.props.?.shininess
    
    cam_transform := get_main_camera_transform(sg)
    if cam_transform == nil {
        return error(.NilPtr, "Failed to get main camera transform")
    }
    view_pos := cam_transform.position
    
    lights := make([]^Light, len(sg.Components[.Light]))
    defer delete(lights)
    for l, i in sg.Components[.Light] {
        lights[i] = cast(^Light)l
    }
    num_lights := len(lights)
    
    // Set uniforms
    if err := set_uniform(material.shader_var_locs["model"], model^); !ok(err) do return error(err.t, "error setting model uniform")
    if err := set_uniform(material.shader_var_locs["view"], view^); !ok(err) do return error(err.t, "error setting view uniform")
    if err := set_uniform(material.shader_var_locs["projection"], projection^); !ok(err) do return error(err.t, "error setting projection uniform")
    if err := set_uniform(material.shader_var_locs["viewPos"], view_pos); !ok(err) do return error(err.t, "error setting viewPos uniform")
    if err := set_uniform(material.shader_var_locs["diffuseColor"], diffuse); !ok(err) do return error(err.t, "error setting diffuseColor uniform")
    if err := set_uniform(material.shader_var_locs["specularColor"], specular); !ok(err) do return error(err.t, "error setting specularColor uniform")
    if err := set_uniform(material.shader_var_locs["shininess"], shininess); !ok(err) do return error(err.t, "error setting shininess uniform")
    
    // Set light uniforms
    gl.Uniform1i(material.shader_var_locs["numLights"], i32(num_lights))
    if err := gl.GetError(); err != gl.NO_ERROR {
        return error(.GL, "OpenGL error setting numLights uniform: %v", err)
    }

    for l, i in lights {
        light_base := fmt.tprintf("lights[%d]", i)
        position_loc := material.shader_var_locs[fmt.tprintf("%s.position", light_base)]
        color_loc := material.shader_var_locs[fmt.tprintf("%s.color", light_base)]
        intensity_loc := material.shader_var_locs[fmt.tprintf("%s.intensity", light_base)]
        
        // fmt.printf("Light %d: position_loc = %d, color_loc = %d, intensity_loc = %d\n", 
        //            i, position_loc, color_loc, intensity_loc)
        
        if position_loc == -1 || color_loc == -1 || intensity_loc == -1 {
            return error(.GL, "Invalid uniform location for light %d", i)
        }
        
        // fmt.printf("Light %d: position = %v, color = %v, intensity = %f\n", 
        //            i, lights[i].position, lights[i].color, lights[i].intensity)
        if err := set_uniform(material.shader_var_locs[fmt.tprintf("%s.position", light_base)], l.position); !ok(err) do return error(err.t, "error setting light position uniform")
        if err := set_uniform(material.shader_var_locs[fmt.tprintf("%s.color", light_base)], l.color); !ok(err) do return error(err.t, "error setting light color uniform")
        if err := set_uniform(material.shader_var_locs[fmt.tprintf("%s.intensity", light_base)], l.intensity); !ok(err) do return error(err.t, "error setting light intensity uniform")
    }
    
    return good()
}