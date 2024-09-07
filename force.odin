package bang

import "core:math/linalg"
import "core:time"
import "core:log"

Force :: struct {
    eid: EntityID,
    linear: linalg.Vector3f32,
    angular: linalg.Quaternionf32
}

gravity_system :: proc(sg: ^SceneGraph) -> Error {
    for c in sg.Components[.RigidBody] {

        rb := cast(^RigidBody)c
        if !rb.has_gravity {
            continue
        }
        gravity_force :=  Force{
            eid = rb.eid,
            linear = linalg.Vector3f32{0, -9.81 * rb.mass, 0},
            angular = linalg.quaternion_from_euler_angles_f32(0,0,0,.XYZ)
        }
        append(&sg.Forces, gravity_force)
    }
    return good()
}

add_linear_force :: proc(sg: ^SceneGraph, eid: EntityID, force: linalg.Vector3f32) -> Error {
    f := Force{
        eid = eid,
        linear = force,
        angular = linalg.quaternion_from_euler_angles_f32(0,0,0,.XYZ)
    }
    append(&sg.Forces, f)
    return good()
}

add_angular_force :: proc(sg: ^SceneGraph, eid: EntityID, force: linalg.Quaternionf32) -> Error {
    f := Force{
        eid = eid,
        linear = linalg.Vector3f32{0, 0, 0},
        angular = force
    }
    append(&sg.Forces, f)
    return good()
}

apply_forces :: proc(sg: ^SceneGraph) -> Error {
    for f in sg.Forces {
        rb := get_rigidbody(sg, f.eid)
        if rb == nil {
            return error(.NilPtr, "^RigidBody was nil for force with eid", f.eid)
        }
        rb.linear_velocity += f.linear
        if f.angular != linalg.quaternion_from_euler_angles_f32(0,0,0,.XYZ) {
            rb.angular_velocity = linalg.quaternion_mul_quaternion(rb.angular_velocity, f.angular)
        }
    }
    for c in sg.Components[.RigidBody] {
        rb := cast(^RigidBody)c
        t := get_transform(sg, rb.eid)
        t.position += rb.linear_velocity * f32(time.duration_seconds(sg.FrameTime))
        t.rotation = linalg.quaternion_mul_quaternion(t.rotation,rb.angular_velocity)
    }
    sg.Forces = [dynamic]Force{}
    return good()
}

