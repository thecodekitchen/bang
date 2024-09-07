package bang

import "core:math/linalg"
import gl"vendor:OpenGL"
import "core:fmt"
Material :: struct {
    using base: Component,
    shader_var_locs: map[string]i32,
    props: Maybe(MaterialData),
    shader_program: u32
}

build_basic_material :: proc() -> (Material, Error) {
    program, err := load_basic_shader_program()
    if !ok(err) {
        return Material{}, error(err.t, "Failed to load basic shader program")
    }
    material := Material {
        ctype = .Material,
        shader_program = program
    }
    model_loc := gl.GetUniformLocation(program, "model")
    material.shader_var_locs["model"] = model_loc
    view_loc := gl.GetUniformLocation(program, "view")
    material.shader_var_locs["view"] = view_loc
    projection_loc := gl.GetUniformLocation(program, "projection")
    material.shader_var_locs["projection"] = projection_loc
    return material, good()
}

build_advanced_material :: proc(data: MaterialData) -> (Material, Error) {
    program, err := load_advanced_shader_program()
    if !ok(err) {
        return Material{}, error(err.t, "Failed to load advanced shader program")
    }
    
    material := Material {
        ctype = .Material,
        props = data,
        shader_program = program
    }
    //Vertex shader props
    material.shader_var_locs["model"] = gl.GetUniformLocation(program, "model")
    material.shader_var_locs["view"] = gl.GetUniformLocation(program, "view")
    material.shader_var_locs["projection"] = gl.GetUniformLocation(program, "projection")
    //Fragment shader props
    material.shader_var_locs["lights"] = gl.GetUniformLocation(program, "lights")
    material.shader_var_locs["numLights"] = gl.GetUniformLocation(program, "numLights")
    material.shader_var_locs["viewPos"] = gl.GetUniformLocation(program, "viewPos")
    material.shader_var_locs["diffuseColor"] = gl.GetUniformLocation(program, "diffuseColor")
    material.shader_var_locs["specularColor"] = gl.GetUniformLocation(program, "specularColor")
    material.shader_var_locs["shininess"] = gl.GetUniformLocation(program, "shininess")
    for i in 0..<MAX_LIGHTS {
        light_base := fmt.tprintf("lights[%d]", i)
        light_uniforms := []string{"position", "color", "intensity"}
        
        for lu in light_uniforms {
            uniform_name := fmt.tprintf("%s.%s", light_base, lu)
            location := gl.GetUniformLocation(program, cstring(raw_data(uniform_name)))
            if location == -1 {
                return Material{}, error(.GL, "Failed to get location for uniform", uniform_name)
            }
            material.shader_var_locs[uniform_name] = location
        }
    }
    return material, good()
}

get_material :: proc(sg: ^SceneGraph, eid: EntityID) -> ^Material {
    for m in sg.Components[.Material] {
        if m.eid == eid {
            return cast(^Material)m
        }
    }
    return nil
}

cleanup_materials :: proc(sg: ^SceneGraph) {
    for m in sg.Components[.Material] {
        material := cast(^Material)m
        gl.DeleteProgram(material.shader_program)
    }
} 