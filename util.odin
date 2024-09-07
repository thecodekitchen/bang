package bang

import "core:math/rand"

random_f32 :: proc(min, max: f32) -> f32 {
    return min + (max - min) * rand.float32()
}