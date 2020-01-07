contract A {
    function f() external {}
}

contract B {
    function g() external {
        function() external f = A.f;
    }
}
// ----
// TypeError: (94-121): Type function A.f() is not implicitly convertible to expected type function () external.
