contract A {
    function f() external {}
}

contract B {
    function g() external {
        A.f();
    }
}
// ----
// TypeError: (94-99): Cannot call function via contract name.
