extern void __wasm_call_ctors(void);
extern int main(void);
extern void __prepare_for_exit(void);
void _Exit(int) __attribute__((noreturn));

void _start(void) {
    // The linker synthesizes this to call constructors.
    __wasm_call_ctors();

    // Call `main` which will either be the application's zero-argument
    // `main` function or a libc routine which populates `argc` and `argv`
    // and calls the application's two-argument `__main_argc_argv`.
    int r = main();

    // Call atexit functions, destructors, stdio cleanup, etc.
    __prepare_for_exit();

    // If main exited successfully, just return, otherwise call _Exit.
    if (r != 0) {
        _Exit(r);
    }
}
