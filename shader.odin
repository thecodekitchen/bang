package bang

import "core:strings"
import "core:fmt"
import gl "vendor:OpenGL"

load_basic_shader_program :: proc() -> (u32, Error) {
    vertex_src := strings.clone_to_cstring(BasicVertexSrc)
    defer delete(vertex_src)
    fragment_src := strings.clone_to_cstring(BasicFragmentSrc)
    defer delete(fragment_src)

    shader_program := gl.CreateProgram()
    
    vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vertex_shader,1,&vertex_src, nil)
    gl.CompileShader(vertex_shader)
    err := check_shader_compilation(vertex_shader, "vertex")
    if !ok(err) {
        return 0, error("Failed to compile vertex shader", err.t)
    }

    fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(fragment_shader,1,&fragment_src, nil)
    gl.CompileShader(fragment_shader)
    err = check_shader_compilation(fragment_shader, "fragment")
    if !ok(err) {
        return 0, error("Failed to compile fragment shader", err.t)
    }

    gl.AttachShader(shader_program, vertex_shader)
    gl.AttachShader(shader_program, fragment_shader)

    gl.LinkProgram(shader_program)
    check_program_linking(shader_program)

    return shader_program, good()
}

load_advanced_shader_program :: proc() -> (program: u32, err: Error) {
    vertex_src := strings.clone_to_cstring(AdvancedVertexSrc)
    defer delete(vertex_src)
    fragment_src := strings.clone_to_cstring(AdvancedFragmentSrc)
    defer delete(fragment_src)
    
    program = gl.CreateProgram()
    vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
    defer gl.DeleteShader(vertex_shader)
    gl.ShaderSource(vertex_shader, 1, &vertex_src, nil)
    gl.CompileShader(vertex_shader)
    if err = check_shader_compilation(vertex_shader, "Vertex"); !ok(err) {
        return 0, error("Failed to compile vertex shader", err.t)
    }

    fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    defer gl.DeleteShader(fragment_shader)
    gl.ShaderSource(fragment_shader, 1, &fragment_src, nil)
    gl.CompileShader(fragment_shader)
    if err = check_shader_compilation(fragment_shader, "Fragment"); !ok(err) {
        return 0, error("Failed to compile fragment shader", err.t)
    }

    gl.AttachShader(program, vertex_shader)
    gl.AttachShader(program, fragment_shader)

    gl.LinkProgram(program)
    if err = check_program_linking(program); !ok(err) {
        return 0, error("Failed to link shader program", err.t)
    }

    if err = validate_program(program); !ok(err) {
        return 0, error("Shader program validation failed", err.t)
    }

    return program, good()
}

check_shader_compilation :: proc(shader: u32, shader_type: string) -> Error {
    success: i32
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
    if success == 0 {
        info_log: [512]u8
        gl.GetShaderInfoLog(shader, 512, nil, &info_log[0])
        m := fmt.tprintf("%s shader compilation failed: %s", shader_type, string(info_log[:]))
        return error(m, .GL)
    }
    return good()
}

check_program_linking :: proc(program: u32) -> Error {
    success: i32
    gl.GetProgramiv(program, gl.LINK_STATUS, &success)
    if success == 0 {
        info_log: [512]u8
        gl.GetProgramInfoLog(program, 512, nil, &info_log[0])
        m := fmt.tprintf("Shader program linking failed: %s", string(info_log[:]))
        return error(m, .GL)
    }
    return good()
}

validate_program :: proc(program: u32) -> Error {
    gl.ValidateProgram(program)
    status: i32
    gl.GetProgramiv(program, gl.VALIDATE_STATUS, &status)
    if status == 0 {
        info_log: [512]u8
        gl.GetProgramInfoLog(program, 512, nil, &info_log[0])
        m := fmt.tprintf("Shader program validation failed: %s", string(info_log[:]))
        return error(m, .GL)
    }
    return good()
}

set_uniform :: proc(location: i32, value: $T) -> Error {
    when T == f32 {
        gl.Uniform1f(location, value)
    } else when T == [3]f32 {
        gl.Uniform3f(location, value[0], value[1], value[2])
    } else when T == [4]f32 {
        gl.Uniform4f(location, value[0], value[1], value[2], value[3])
    } else when T == matrix[4,4]f32 {
        data := transmute([16]f32)value
        gl.UniformMatrix4fv(location, 1, gl.FALSE, &data[0])
    } else {
        return error("Unsupported uniform type", .InvalidType)
    }
    
    if err := gl.GetError(); err != gl.NO_ERROR {
        return error(fmt.tprintf("OpenGL error setting uniform: %v", err), .GL)
    }
    return good()
}