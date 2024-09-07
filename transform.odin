package bang

import "core:math/linalg"
import "core:math"
import "core:fmt"
Transform :: struct {
    using base: Component,
    position: linalg.Vector3f32,
    front:    linalg.Vector3f32,
    up:       linalg.Vector3f32,
    right:    linalg.Vector3f32,
    world_up: linalg.Vector3f32,
    rotation: linalg.Quaternionf32,
    scale:    linalg.Vector3f32
}

update_model_matrix :: proc(sg: ^SceneGraph, eid: EntityID) -> linalg.Matrix4f32 {
    t := get_transform(sg, eid)
    model := linalg.MATRIX4F32_IDENTITY

    // Scale
    scale_matrix := linalg.matrix4_scale(t.scale)
    model = linalg.matrix_mul(model, scale_matrix)

    // Rotation
    rotation_matrix := linalg.matrix4_from_quaternion_f32(t.rotation)
    model = linalg.matrix_mul(model, rotation_matrix)

    // Translation
    translation_matrix := linalg.matrix4_translate(t.position)
    model = linalg.matrix_mul(model, translation_matrix)

    return model
}

get_transform :: proc(sg: ^SceneGraph, eid: EntityID) -> ^Transform {
    for t in sg.Components[.Transform] {
        if t.eid == eid {
            return cast(^Transform)t
        }
    }
    return nil
}

get_transform_by_name :: proc(sg: ^SceneGraph, ename: string) -> ^Transform {
    for t in sg.Components[.Transform] {
        if t.ename == ename {
            return cast(^Transform)t
        }
    }
    return nil
}
// update_model_matrix :: proc(sg: ^SceneGraph, eid: u64) -> linalg.Matrix4f32 {
//     t := update_transform(sg, eid)
//     model := linalg.MATRIX4F32_IDENTITY

//     // Scale
//     scale_matrix := linalg.matrix4_scale(t.scale)
//     model = linalg.matrix_mul(model, scale_matrix)

//     // Rotation
//     rot_x := linalg.matrix4_rotate_f32(linalg.to_radians(t.rotation.x), {1,0,0})
//     rot_y := linalg.matrix4_rotate_f32(linalg.to_radians(t.rotation.y), {0,1,0})
//     rot_z := linalg.matrix4_rotate_f32(linalg.to_radians(t.rotation.z), {0,0,1})
//     rotation_matrix := linalg.matrix_mul(linalg.matrix_mul(rot_z, rot_y), rot_x)
//     model = linalg.matrix_mul(model, rotation_matrix)

//     // Translation
//     translation_matrix := linalg.matrix4_translate(t.position)
//     model = linalg.matrix_mul(model, translation_matrix)

//     return model
// }



default_transform :: proc(name := "") -> Transform {
    return Transform {
        ctype = .Transform,
        ename = name,
        up = {0,1,0},
        world_up = {0,1,0},
        rotation = linalg.quaternion_from_euler_angles_f32(0,0,0,.XYZ),
        position = generate_default_position(),
        right = {1,0,0},
        front = {0,0,-1},
        scale = {1,1,1}
    }
}

generate_default_position :: proc() -> [3]f32 {
    return {
        random_f32(-5, 5),
        random_f32(-5, 5),
        random_f32(-5, 5),
    }
}

// update_transform :: proc(sg: ^SceneGraph, eid: u64) -> ^Transform {
//     t := get_transform(sg, eid)
//     front, right, up := calculate_orientation_vectors(t.rotation, t.world_up)
//     t.front = front
//     t.right = right
//     t.up = up
//     return t
// }

calculate_orientation_vectors :: proc(rotation, world_up: linalg.Vector3f32) -> (front, right, up: linalg.Vector3f32) {
    // Convert degrees to radians
    pitch := math.to_radians(rotation.x)
    yaw := math.to_radians(rotation.y)
    roll := math.to_radians(rotation.z)

    // Calculate the front vector
    front.x = math.cos(yaw) * math.cos(pitch)
    front.y = math.sin(pitch)
    front.z = math.sin(yaw) * math.cos(pitch)
    front = linalg.normalize(front)

    // Calculate the right vector
    right = linalg.normalize(linalg.cross(front, world_up))

    up = linalg.normalize(linalg.cross(right, front))

    // Apply roll rotation to right and up vectors
    if roll != 0 {
        cos_roll := math.cos(roll)
        sin_roll := math.sin(roll)
        
        right_rolled := right * cos_roll + up * sin_roll
        up_rolled := up * cos_roll - right * sin_roll
        
        right = right_rolled
        up = up_rolled
    }
    return front, right, up
}

rotate_transform :: proc(t: ^Transform, rotation_degrees: linalg.Vector3f32) {
    // Convert degrees to radians
    // debug_log(fmt.tprint("Rotating by: ", rotation_degrees))
    rotation_radians := rotation_degrees * (math.PI / 180.0)

    // Create rotation quaternions for each axis
    rot_x := linalg.quaternion_angle_axis(rotation_radians.x, linalg.Vector3f32{1, 0, 0})
    rot_y := linalg.quaternion_angle_axis(rotation_radians.y, linalg.Vector3f32{0, 1, 0})
    rot_z := linalg.quaternion_angle_axis(rotation_radians.z, linalg.Vector3f32{0, 0, 1})

    // Combine rotations
    combined_rotation := linalg.quaternion_mul_quaternion(rot_z, linalg.quaternion_mul_quaternion(rot_y, rot_x))

    // Apply the new rotation to the existing rotation
    t.rotation = linalg.quaternion_mul_quaternion(combined_rotation, t.rotation)

    // Update front, right, and up vectors
    forward := linalg.Vector3f32{0, 0, -1}
    rotation_matrix := linalg.matrix3_from_quaternion(t.rotation)
    t.front = linalg.matrix_mul_vector(rotation_matrix, forward)
    t.right = linalg.normalize(linalg.cross(t.front, t.world_up))
    t.up = linalg.normalize(linalg.cross(t.right, t.front))
}

look_at :: proc(transform: ^Transform, target: linalg.Vector3f32) {
    // Calculate the new front vector
    new_front := linalg.vector_normalize(target - transform.position)
    
    // Calculate the right vector
    new_right := linalg.vector_normalize(linalg.cross(new_front, transform.world_up))
    
    // Recalculate the up vector to ensure orthogonality
    new_up := linalg.vector_normalize(linalg.cross(new_right, new_front))
    
    // Create a rotation matrix from these new vectors
    rotation_matrix := linalg.Matrix3f32{
        new_right.x, new_up.x, -new_front.x,
        new_right.y, new_up.y, -new_front.y,
        new_right.z, new_up.z, -new_front.z,
    }
    
    // Convert the rotation matrix to a quaternion
    transform.rotation = linalg.quaternion_from_matrix3(rotation_matrix)
    
    // Update the transform's vectors
    transform.front = new_front
    transform.right = new_right
    transform.up = new_up
    
    // Ensure the quaternion is normalized
    transform.rotation = linalg.quaternion_normalize(transform.rotation)
}