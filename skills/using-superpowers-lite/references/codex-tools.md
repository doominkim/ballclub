# Codex tool mapping

- Read and search files with the available shell/search tools; prefer `rg` for text search.
- Edit files with `apply_patch` and preserve unrelated user changes.
- Run verification with the available command execution tool.
- Use the native plan tool only when task complexity benefits from explicit tracking.
- Dispatch subagents only when multi-agent support is available, policy permits it, and work is genuinely independent.
- Load skills through Codex's native skill mechanism; do not manually paste every skill into context.
