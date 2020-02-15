#import "Debug";

debug_here :: () #expand {
    attach_to_debugger();
    breakpoint();
}