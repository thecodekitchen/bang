package bang

import "core:math/linalg"

MAX_LIGHTS :: 10

Light :: struct {
    using base: Component,
    position: [3]f32,
    color: [3]f32,
    intensity: f32
}

entity_is_light :: proc(sg: ^SceneGraph, eid: EntityID) -> bool {
    for l in sg.Components[.Light] {
        if l.eid == eid {
            return true
        }
    }
    return false
}

get_lights :: proc(sg: ^SceneGraph) -> []^Light {
    lights := [dynamic]^Light{}
    for l in sg.Components[.Light] {
        append(&lights, cast(^Light)l)
    }
    return lights[:]    
}