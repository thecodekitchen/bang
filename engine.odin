package bang

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "core:fmt"
import "core:time"
import "core:log"
create_bang_window :: proc() -> (glfw.WindowHandle, i32, i32) {
    if !glfw.Init() {
        fmt.println("Failed to initialize GLFW")
        return nil, 0, 0
    }

    // Set OpenGL version
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    width, height := get_monitor_size()
    // Create a window
    window := glfw.CreateWindow(width, height, "Bang Engine", nil, nil)
    if window == nil {
        fmt.println("Failed to create GLFW window")
        return nil, 0, 0
    }

    // Make the window's context current
    glfw.MakeContextCurrent(window)
    gl.load_up_to(3, 3, glfw.gl_set_proc_address)
    return window, width, height
}

create_scene :: proc() -> (glfw.WindowHandle, SceneGraph) {
    window, width, height := create_bang_window()
    sg := SceneGraph{
        Width = width,
        Height = height,
        InputManager = init_input_manager(),
        Systems = map[string]System{
            "gravity" = gravity_system,
        },
    }
    return window, sg
}

get_monitor_size :: proc() -> (width, height: i32) {
    monitor := glfw.GetPrimaryMonitor()
    if monitor == nil {
        return 0, 0 // Error handling
    }
    
    mode := glfw.GetVideoMode(monitor)
    if mode == nil {
        return 0, 0 // Error handling
    }
    
    return mode.width, mode.height
}

run_scene :: proc(window: glfw.WindowHandle, sg: ^SceneGraph, frame_duration: time.Duration) {
    for !glfw.WindowShouldClose(window) {
        pre_frame := time.now()
        glfw.PollEvents()
        // Input
        process_inputs(sg.InputManager, window)
        // fmt.println(fmt.tprintfln("mouse: %v, %v", get_mouse_deltas(sg.InputManager)))
        // Systems
        for name, system in sg.Systems {
            err := system(sg)
            if !ok(err) {
                fmt.printfln("system failed: %s", name)
                glfw.WindowShouldClose(window)
                break
            }
        }
        
        apply_forces(sg)
        
        // clear_input_manager(sg.InputManager)
        // update cameras after systems run so they can react to system-triggered events
        update_cameras(sg)
        // Rendering
        // debug_log(fmt.tprintfln("rendering scene graph: %v", sg))
        err := render_scene(sg, window)
        if !ok(err) {
            fmt.println("failed to render scene")
            glfw.WindowShouldClose(window)
            break
        }
        // debug_log("scene rendered")
        // cap fps
        glfw.SwapBuffers(window)
        
        frame_time := time.diff(pre_frame, time.now())

        sg.FrameTime = frame_time
        if frame_time < frame_duration {
            time.sleep(frame_duration - frame_time)
        }
    }
    cleanup_meshes(sg)
    cleanup_materials(sg)
}