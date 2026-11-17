### Bug fix

**You own the diagnosis and the verdict. Delegate the fix.**

1. Load **diagnosing-bugs**. Reproduce it yourself on the real surface (app, simulator, browser, CLI). Ask the user only when no surface you control reaches it, and say why.
2. Binary-search the cause: list hypotheses, cut the most problem space per pass, get runtime evidence. Use **why** for regression history. Confirm the mechanism before you fix.
3. Fix crosses a function boundary: **architect** first. Delegate the fix with a tight scope.
4. Verify on the same surface: the original repro passes. Wrong surface or inconclusive is not a pass.
5. With a cheap test path, the failing test lands before the fix (**tdd**).
6. Run `ship.md` when the user wants a PR.

**Reply:** what broke, root cause, fix, failing-then-passing repro output.
