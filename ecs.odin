package bang

import "core:slice"
import "core:fmt"
import "core:log"
import "core:time"
import glfw"vendor:glfw"

EntityID :: distinct u64
System :: proc(^SceneGraph) -> Error
CUSTOM_START :: 500
SceneGraph :: struct {
    Width: i32,
    Height: i32,
    Renderer: Renderer,
    InputManager: ^InputManager,
    FrameTime: time.Duration,
    Entities: [dynamic]EntityID,
    Components: #sparse [ComponentType][dynamic]^Component,
    CustomComponents: map[string]u64,
    Systems: map[string]System
}

Component :: struct {
    eid : EntityID,
    ename: string,
    ctype: ComponentType
}

ComponentType :: enum {
    Mesh,
    Material,
    Transform,
    Camera,
    Light,
    Custom_Start = CUSTOM_START
    // custom component ids will start at 501
}

CustomComponent :: struct {
    using base: Component,
    name: string,

}

add_component_to_scene :: proc(sg: ^SceneGraph,  component: ^Component) -> Error {
    if sg == nil {
        return error(.NilPtr, "^SceneGraph was nil")
    }
    if component == nil {
        return error(.NilPtr, "^Component was nil")
    }
    
    append(&sg.Components[component.ctype], component)
    return good()
}

add_entity_to_scene :: proc(sg: ^SceneGraph, components: [](^Component)) -> (EntityID, Error) {
    
    max_eid := slice.max(sg.Entities[:])
    eid := max_eid + 1
    append(&sg.Entities, eid)
    for &c in components {
        c.eid = EntityID(eid)
        err := add_component_to_scene(sg, c)
        if !ok(err) {
            message := fmt.tprintf("failed to add component to scene: %s", c)
            error(err.t, message)
            return 0, err
        }
    }
    return eid, good()
}

register_custom_component :: proc(sg: ^SceneGraph, name: string) -> Error {
    id := CUSTOM_START + len(sg.CustomComponents) + 1
    sg.CustomComponents[name] = u64(id)
    sg.Components[ComponentType(id)] = make([dynamic]^Component)
    
    return good()
}