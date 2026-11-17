### Refactoring

**You own the contract. Structure changes, behavior does not.** A found bug or missing feature splits out.

1. Pin the behavior first: characterization test, snapshot or equivalence script. Type check and lint are not a pin.
2. Name the target shape (**improve-codebase-architecture**, **codebase-design**). It must delete branches or invalid states, not add indirection.
3. Subtract first: dead code, one-caller wrappers, orphan references.
4. Move in small steps, pin green each time. Migrate every caller and delete the old API in one wave. Check renames in strings and docs too.
5. Prove unchanged behavior on the real artifact. Revert a diff that does not lower reader load.
6. Commits: subtraction, reshape, cleanup. Then `ship.md`.

**Reply:** structure changed, the pin, equivalence proof, what got reverted.
