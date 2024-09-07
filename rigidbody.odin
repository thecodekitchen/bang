package bang

import "core:math/linalg"

RigidBody :: struct {
    using base: Component,
    linear_velocity: linalg.Vector3f32,
    angular_velocity: linalg.Quaternionf32,
    momentum: linalg.Vector3f32,
    mass: f32,
    grounded: bool,
    has_gravity: bool
}
create_rigidbody :: proc() -> RigidBody {
    return RigidBody{
        ctype = .RigidBody,
        linear_velocity = linalg.Vector3f32{0, 0, 0}, 
        angular_velocity = linalg.quaternion_from_euler_angles_f32(0,0,0,.XYZ), 
        mass = 1.0, 
        grounded = false, 
        has_gravity = true
    }
}

get_rigidbody :: proc(sg: ^SceneGraph, eid: EntityID) -> ^RigidBody {
    for c in sg.Components[.RigidBody] {
        if c.eid == eid {
            return cast(^RigidBody)c
        }
    }
    return nil
}