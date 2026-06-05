# clean-code-principles.md

Rules for this project. Short, enforceable.

## Structure
- **SRP:** One class/file = one responsibility. Screens do not contain business logic.
- **Feature isolation:** Cross-feature imports go through `core/` only. Features do not import from each other.
- **Layer separation:** `data/` (repositories, models) -> `domain/` (use cases, entities) -> `presentation/` (screens, providers, widgets).

## Functions
- Max 30 lines per function/method. Extract if longer.
- No nested callbacks deeper than 2 levels — extract to named functions.
- Pure functions preferred; side effects at the edges.

## Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `kConstantName` (Flutter convention)
- Providers: `walletTransactionsProvider`, not `provider1`

## Comments
- No comments explaining WHAT the code does — name it clearly instead.
- Comments only for WHY: a hidden constraint, a workaround, a non-obvious invariant.

## Error Handling
- Use `AsyncValue` (Riverpod) for async state — covers loading/error/data.
- Never swallow exceptions silently. Log + surface to user.
- Supabase errors: map to user-friendly messages at the repository layer.

## Security
- Never log or print auth tokens, passwords, or personal data.
- Never hardcode Supabase service_role key — use anon key + RLS.
- All Supabase tables: RLS enabled, `user_id = auth.uid()` policy enforced.
- File deletion: always confirm before executing. No silent deletes.

## Flutter-Specific
- `const` constructors everywhere possible.
- No `BuildContext` passing across async gaps — use `mounted` check.
- Riverpod providers declared at top-level (not inside widgets).
- `go_router` for all navigation — no `Navigator.push` calls.
