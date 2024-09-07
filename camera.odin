package bang

import "core:math"
import "core:math/linalg"
import "core:fmt"

Camera :: struct {
    using base: Component,
    is_main: bool,
    view_matrix: linalg.Matrix4f32,
    projection_matrix: linalg.Matrix4f32,
    projection: Projection
}

Projection:: struct {
    aspect_ratio: f32,
    field_of_view: f32,
    near_plane: f32,
    far_plane: f32
}

update_cameras :: proc(sg: ^SceneGraph) -> Error {
    for c in sg.Components[.Camera] {
        cam := cast(^Camera)c
        err := update_view_matrix(sg, cam)
        if !ok(err) {
            message := fmt.tprintf("failed to update view matrix for camera with eid %d", cam.eid)
            return error(err.t, message)
        }
    }
    return good()
}
/* Updates the view matrix of a camera and set scene's view matrix to camera's current view matrix if camera is the main camera. 
    If camera is not the main camera, it only updates.
*/
update_view_matrix :: proc(sg: ^SceneGraph, camera: ^Camera) -> Error {
    transform := get_transform(sg, camera.eid)
    if transform == nil {
        m :=fmt.tprintf("failed to get transform for camera with eid %d", camera.eid)
        return error(.NilPtr, m)
    }    
    view_matrix, err := get_view_matrix(transform)
    if !ok(err) {
        m := fmt.tprintf("transform was nil for camera with eid %d", camera.eid)
        return error(err.t, m)
    }
    camera.view_matrix = view_matrix
    if camera.is_main{
        sg.Renderer.view_matrix = camera.view_matrix
    }
    return good()
}

get_main_camera :: proc(sg: ^SceneGraph) -> ^Camera {
    for c in sg.Components[.Camera] {
        cam := cast(^Camera)c
        
        if cam.is_main {
            return cam
        }
    }
    return nil
}

get_main_camera_transform :: proc(sg: ^SceneGraph) -> ^Transform {
    for c in sg.Components[.Camera] {
        cam := cast(^Camera)c
        if cam.is_main {
            return get_transform(sg, cam.eid)
        }
    }
    return nil
}

get_view_matrix :: proc(t:^Transform) -> (linalg.Matrix4f32, Error) {
    if t == nil {
        return linalg.MATRIX4F32_IDENTITY, error(.NilPtr, "transform was nil")
    }
    target := t.position + t.front
    return linalg.matrix4_look_at_f32(t.position, target, t.up), good()
}

build_camera :: proc(sg: ^SceneGraph,transform: ^Transform, is_main: bool) -> (Camera, Error) {
    camera := Camera{
        ctype = .Camera,
        is_main = is_main
    }
    view_matrix, err := get_view_matrix(transform)
    if !ok(err) {
        m := fmt.tprintf("transform was nil for camera with eid %d", camera.eid)
        return camera, error(err.t, m)
    }

    camera.view_matrix = view_matrix
    camera.projection = Projection{
        aspect_ratio = f32(sg.Width / sg.Height),
        field_of_view = math.to_radians_f32(45.0),
        near_plane = 0.1,
        far_plane = 100.0
    }
    camera.projection_matrix = linalg.matrix4_perspective_f32(camera.projection.field_of_view, camera.projection.aspect_ratio, camera.projection.near_plane, camera.projection.far_plane)
    if is_main {
        sg.Renderer.view_matrix = camera.view_matrix
        sg.Renderer.projection_matrix = camera.projection_matrix
    }
    return camera, good()
}

entity_is_camera :: proc(sg: ^SceneGraph, eid: EntityID) -> bool {
    for c in sg.Components[.Camera] {
        if c.eid == eid {
            return true
        }
    }
    return false
}