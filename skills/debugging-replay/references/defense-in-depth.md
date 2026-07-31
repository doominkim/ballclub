# Defense in depth

After repairing the root cause, add validation only at boundaries where it gives
independent protection or a clearer error.

- Validate external or untrusted input at entry.
- Preserve domain invariants where state is constructed or changed.
- Fail with actionable context before irreversible operations.
- Avoid duplicating identical checks at every internal layer.

Defense in depth complements a root-cause fix; it must not replace one.
