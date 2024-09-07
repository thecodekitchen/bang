package bang
import "core:fmt"
import "base:runtime"

ErrorType :: enum {
    None,
    GL,
    InvalidType,
    NilPtr
}

Error :: struct {
    t: ErrorType,
    message: string
}

debug_log :: proc(message: string, location := #caller_location) {
    fmt.printf("[%s:%d] %s\n", location.file_path, location.line, message)
}

// Wrapper function to get caller's caller location
error_log :: proc(message: string, t: ErrorType, location: runtime.Source_Code_Location) {
    fmt.printf("ERROR: %s at [%s:%d] %s\n", t, location.file_path, location.line, message)
}

error :: proc(message: string, etype: ErrorType, location := #caller_location) -> Error {
    if etype != .None {
        error_log(message, etype, location)
    }
    
    error := Error {
        t = etype,
        message = message
    }
    return error
}

good :: proc() -> Error {
    return error("", .None)
}

ok :: proc(err: Error) -> bool {
    return err.t == .None
}