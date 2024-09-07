package bang
import "core:fmt"
import "core:log"
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


// Wrapper function to get caller's caller location
error_log :: proc(message: string, t: ErrorType, location: runtime.Source_Code_Location) {
    fmt.printf("ERROR: %s at [%s:%d] %s\n", t, location.file_path, location.line, message)
}

error :: proc(etype: ErrorType, message: ..any) -> Error {
    if etype != .None {
        log.error(message)
    }
    
    error := Error {
        t = etype,
        message = fmt.tprint(message)
    }
    return error
}

good :: proc() -> Error {
    return error(.None, "")
}

ok :: proc(err: Error) -> bool {
    return err.t == .None
}