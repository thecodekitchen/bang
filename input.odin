package bang

import "vendor:glfw"
import "core:fmt"
InputState :: struct {
    keyboard: [glfw.KEY_LAST]bool,
    previous_keyboard: [glfw.KEY_LAST]bool,
    mouse_buttons: [glfw.MOUSE_BUTTON_LAST]bool,
    previous_mouse_buttons: [glfw.MOUSE_BUTTON_LAST]bool,
    mouse_x, mouse_y: f32,
    previous_mouse_x, previous_mouse_y: f32,
    mouse_delta_x, mouse_delta_y: f32,
}

InputEvent :: struct {
    type: enum {
        KEY_DOWN,
        KEY_HOLD,
        KEY_UP,
        MOUSE_PRESS,
        MOUSE_RELEASE,
        MOUSE_MOVE,
    },
    key: i32,  // Changed from glfw.Key to i32
    mouse_button: i32,  // Changed from glfw.MouseButton to i32
    x, y: f32,
}

InputManager :: struct {
    state: InputState,
    keymap: map[string]i32,
    events: [dynamic]InputEvent,
}

init_input_manager :: proc() -> ^InputManager {
    manager := new(InputManager)
    manager.events = make([dynamic]InputEvent)
    manager.keymap = init_keymap()
    return manager
}

clear_input_manager :: proc(manager: ^InputManager) {
    delete(manager.events)
    manager.events = make([dynamic]InputEvent)
    // clear everything but previous keyboard which will be switched out in the processing step
    manager.state = InputState{
        previous_keyboard = manager.state.keyboard,
        previous_mouse_buttons = manager.state.mouse_buttons,
        previous_mouse_x = manager.state.mouse_x,
        previous_mouse_y = manager.state.mouse_y,
    }
}

process_inputs :: proc(manager: ^InputManager, window: glfw.WindowHandle) {
    
    copy(manager.state.previous_keyboard[:], manager.state.keyboard[:])
    // Update keyboard state
    for key in i32(0)..<i32(glfw.KEY_LAST) {
        manager.state.keyboard[key] = glfw.GetKey(window, key) == glfw.PRESS
        if manager.state.keyboard[key] && !manager.state.previous_keyboard[key] {
            append(&manager.events, InputEvent{type = .KEY_DOWN, key = key})
        } else if !manager.state.keyboard[key] && manager.state.previous_keyboard[key] {
            append(&manager.events, InputEvent{type = .KEY_UP, key = key})
        } else if (manager.state.keyboard[key]) {
            append(&manager.events, InputEvent{type = .KEY_HOLD, key = key})
        }
    }

    // Update mouse state
    for button in i32(0)..<i32(glfw.MOUSE_BUTTON_LAST) {
        manager.state.mouse_buttons[button] = glfw.GetMouseButton(window, button) == glfw.PRESS
        append(&manager.events, InputEvent{type = .MOUSE_PRESS, mouse_button = button})
    }
    x_64, y_64:= glfw.GetCursorPos(window)

    
    prev_x, prev_y := manager.state.previous_mouse_x, manager.state.previous_mouse_y
    x, y := f32(x_64), f32(y_64)

    // fmt.println("previous", manager.state.mouse_x, manager.state.mouse_y)
    // fmt.println("current", x, y)
    if prev_x != x || prev_y != y {
        manager.state.mouse_delta_x = x - prev_x 
        manager.state.mouse_delta_y = y - prev_y
        manager.state.mouse_x = x
        manager.state.mouse_y = y
        append(&manager.events, InputEvent{type = .MOUSE_MOVE, x = x, y = y})
    } else {
        manager.state.mouse_delta_x = 0
        manager.state.mouse_delta_y = 0
    }

    
    manager.state.mouse_x, manager.state.mouse_y = x, y
}

get_key_down :: proc(manager: ^InputManager, key_name: string) -> bool {
    for e in manager.events {
        if e.type == .KEY_DOWN && manager.keymap[key_name] == e.key {
            return true
        }
    }
    return false
}

get_key_hold :: proc(manager: ^InputManager, key_name: string) -> bool {
    for e in manager.events {
        if e.type == .KEY_HOLD && manager.keymap[key_name] == e.key {
            return true
        }
    }
    return false
}

get_key_up :: proc(manager: ^InputManager, key_name: string) -> bool {
    for e in manager.events {
        if e.type == .KEY_UP && manager.keymap[key_name] == e.key {
            return true
        }
    }
    return false
}

is_mouse_button_pressed :: proc(manager: ^InputManager, button: i32) -> bool {
    return manager.state.mouse_buttons[button]
}

get_mouse_position :: proc(manager: ^InputManager) -> (x: f32, y: f32) {
    return manager.state.mouse_x, manager.state.mouse_y
}

get_mouse_deltas :: proc(manager: ^InputManager) -> (x: f32, y: f32) {
    return manager.state.mouse_delta_x, manager.state.mouse_delta_y
}

init_keymap :: proc() -> map[string]i32 {
    return map[string]i32 {
        "a" = glfw.KEY_A,
        "b" = glfw.KEY_B,
        "c" = glfw.KEY_C,
        "d" = glfw.KEY_D,
        "e" = glfw.KEY_E,
        "f" = glfw.KEY_F,
        "g" = glfw.KEY_G,
        "h" = glfw.KEY_H,
        "i" = glfw.KEY_I,
        "j" = glfw.KEY_J,
        "k" = glfw.KEY_K,
        "l" = glfw.KEY_L,
        "m" = glfw.KEY_M,
        "n" = glfw.KEY_N,
        "o" = glfw.KEY_O,
        "p" = glfw.KEY_P,
        "q" = glfw.KEY_Q,
        "r" = glfw.KEY_R,
        "s" = glfw.KEY_S,
        "t" = glfw.KEY_T,
        "u" = glfw.KEY_U,
        "v" = glfw.KEY_V,
        "w" = glfw.KEY_W,
        "x" = glfw.KEY_X,
        "y" = glfw.KEY_Y,
        "z" = glfw.KEY_Z,
        "space" = glfw.KEY_SPACE,
        "left_ctrl" = glfw.KEY_LEFT_CONTROL,
        "left_shift" = glfw.KEY_LEFT_SHIFT,
        "left_alt" = glfw.KEY_LEFT_ALT,
        "right_ctrl" = glfw.KEY_RIGHT_CONTROL,
        "right_shift" = glfw.KEY_RIGHT_SHIFT,
        "right_alt" = glfw.KEY_RIGHT_ALT,
        "escape" = glfw.KEY_ESCAPE,
        "enter" = glfw.KEY_ENTER,
        "tab" = glfw.KEY_TAB,
        "backspace" = glfw.KEY_BACKSPACE,
        "left" = glfw.KEY_LEFT,
        "right" = glfw.KEY_RIGHT,
        "up" = glfw.KEY_UP,
        "down" = glfw.KEY_DOWN,
        "insert" = glfw.KEY_INSERT,
        "delete" = glfw.KEY_DELETE,
        "pageup" = glfw.KEY_PAGE_UP,
        "pagedown" = glfw.KEY_PAGE_DOWN,
        "home" = glfw.KEY_HOME,
        "end" = glfw.KEY_END,
        "capslock" = glfw.KEY_CAPS_LOCK,
        "numlock" = glfw.KEY_NUM_LOCK,
        "scrolllock" = glfw.KEY_SCROLL_LOCK,
        "printscreen" = glfw.KEY_PRINT_SCREEN,
        "pause" = glfw.KEY_PAUSE,
        "f1" = glfw.KEY_F1,
        "f2" = glfw.KEY_F2,
        "f3" = glfw.KEY_F3,
        "f4" = glfw.KEY_F4,
        "f5" = glfw.KEY_F5,
        "f6" = glfw.KEY_F6,
        "f7" = glfw.KEY_F7, 
        "f8" = glfw.KEY_F8,
        "f9" = glfw.KEY_F9,
        "f10" = glfw.KEY_F10,
        "f11" = glfw.KEY_F11,
        "f12" = glfw.KEY_F12,
        "1" = glfw.KEY_1,
        "2" = glfw.KEY_2,
        "3" = glfw.KEY_3,
        "4" = glfw.KEY_4,
        "5" = glfw.KEY_5,
        "6" = glfw.KEY_6,
        "7" = glfw.KEY_7,
        "8" = glfw.KEY_8,
        "9" = glfw.KEY_9,
        "0" = glfw.KEY_0,
        ";" = glfw.KEY_SEMICOLON,
        "=" = glfw.KEY_EQUAL,
        "[" = glfw.KEY_LEFT_BRACKET,
        "]" = glfw.KEY_RIGHT_BRACKET,
        "\\" = glfw.KEY_BACKSLASH,
    }
}