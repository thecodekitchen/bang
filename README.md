# BANG

A developing game engine written in Odin mostly.

It's still quite early days, but I've dug into it as my primary spare time project and would welcome thoughtful contributions.

I'm using GLFW with OpenGL for rendering. Supporting other rendering backends is of interest to me long term, but I haven't had time to explore it yet.

## Architecture

This is my attempt at an ECS framework, so we start with a scene graph. 

It has a dynamic array of entity ids. 
It has a map of dynamic component arrays for each component type. 
It has a map of named systems. 

Systems are simply procedures that take in a scene graph and produce either an error or a "good" result. (See error handling section below)

It also has an input manager to allow input processing prior to systems processing in the game loop.

The game loop executes in the following order:

1. Inputs are processed
2. Systems are run
3. Camera is updated to react to systems
4. Scene is rendered with updated camera view matrix

To add a camera entity to the scene, for example, you would construct a Camera component and a Transform component, then call add_entity_to_scene on both of them in an array like so:
```

// create a transform component
cam_transform := bang.default_transform()
cam_transform.position = {0,2,5}

// create a camera component
main_cam, cam_err := bang.build_camera(&sg, &cam_transform, true)
if !bang.ok(cam_err) {
    return bang.error("failed to build camera")
}

// Create a new entity id and assign it to each of the listed components.
cam_eid, eid_err := bang.add_entity_to_scene(&sg, [](^bang.Component){&cam_transform, &main_cam})
if !bang.ok(eid_err) {
    fmt.println("failed to add camera to scene")
    return
}
bang.debug_log("added camera to scene")
```

For a full example, check out [this](https://github.com/thecodekitchen/bang-example) repo.
## Loading Assets

I lightly extended [this](https://github.com/vassvik/odin-assimp) basic set of assimp bindings to get a slightly more robust obj importer.

To get this to work, follow the instructions over at that repo precisely with the exception that you'll replace the meshloader_lib.cpp file in the src folder with the one in the assimp folder of this repo.

Once you've built it, move the include and lib folders along with the dll file into your bang directory.

## Rendering

This is the area where I could probably use the most help from those knowledgeable on the topic. 
Currently, I'm using a very crude shader to capture some basic specular lighting details of objects in the scene.
I've also implemented some very simple light components that can be added to the scene and moved around with their associated transforms.
More research is planned in this area, but my next primary focus, now that basic spatial rendering is possible, will be physics.

## Error Handling

Since Odin doesn't exactly have strong opinions on error handling, Bang uses its own error propagation logic. It's roughly inspired by Go's errors as values approach.

It also includes three procedures called 'error', 'good', and 'ok'.

Use them like so, but hopefully without the unfortunate abuse of nil:

```
import "core:log"
import b"path/to/bang"

danger_boy :: proc(nilly:^string) -> (^string, b.Error) {
    if nilly == nil {
        return nil, b.error("nilly be nillin")
    }
    return nilly, b.good()
}

main :: proc() {
    bad: ^string = nil
    nilly, err := danger_boy(bad)
    if !b.ok(err) {
        log.debug("danger boy failed!")
        return
    } 
    log.debug("danger boy found ", nilly)
}
```

The error procedure will also log the calling location where the error originated.
To print a basic stack trace, simply propagate the error.
Odin provides more robust stack tracing natively, but I like the way this leverages the #caller_location directive to enforce good logging habits.

## Project Trajectory

My plan is to keep working on this in my spare time for the forseeable future, and I'd love to start building a core team around it, but my intention is to keep it entirely open source. Odin is a really cool language, and I would really like to help grow its ecosystem.

Future plans include:

- Physics engine
- More advanced shaders
- Full GUI editor
- A lot more I haven't thought of yet

Contributions and/or suggestions are massively appreciated as I have a lot to learn in this arena!