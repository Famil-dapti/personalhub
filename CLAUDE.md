# CLAUDE.md — PersonalHub Super App

This file defines the behavioral rules Claude must follow when working on this project. Read at the start of every new session.

## Language Policy (strict)

- **Speak Turkish to the user only.** User-facing chat replies, planning questions, conversational explanations are Turkish.
- **Everything else is English.** All files (including this one), all code, all identifiers, all internal comments, all log strings, all commit messages, all branch names, all docs, all memory entries — English only.
- **No Turkish characters** (g s u o i c with cedilla/breve) anywhere in files or code. User-facing chat is the only exception.

## Sub-Agent Usage (mandatory)

- Sub-agent usage via the `Agent` tool is **not optional, it is required** for this project.
- Use sub-agents for research, multi-file analysis, anything parallelizable.
- Single trivial file edits do not require sub-agents — every other case does.
- Agent type selection: code search -> `Explore`, planning -> `Plan`, open-ended research -> `general-purpose`.

## Feature Evaluation Rule (mandatory)

When the user proposes a feature, approach, or technique, **before implementing it**:
1. List at least 2 alternatives briefly.
2. Suggest a better solution if one exists.
3. Flag any uncertainty that requires research.
4. Consider whether a different approach would reduce token cost during implementation; propose it if so.

**Exception:** topics already decided during planning are not re-litigated. Follow what is written in `Project-plan.md` directly.

## Living Documents (mandatory)

- **`Project-state.md`** — updated after every completed task. Current phase, finished work, next task, known blockers.
- **`Project-plan.md`** — updated when architecture, feature set, or roadmap changes.
- **`docs/ai-index.md`** — updated when a new module/directory is added.
- **Per-module `README.md`** (3-10 lines): purpose, public surface, dependencies.

## Clean Code

- Follow the rules in `docs/clean-code-principles.md`.
- Summary: SRP, function <=30 lines, comments only for WHY, error handling via Result pattern, no magic numbers.

## Tech Stack

- **Framework:** Flutter (Dart)
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Realtime)
- **State management:** Riverpod
- **Navigation:** go_router
- **Platform channels:** Android NotificationListenerService (Kotlin)
- **Targets:** Android APK + Flutter Web

## Build & Test

- Run dev: `flutter run`
- Build APK: `flutter build apk --release`
- Build web: `flutter build web`
- Unit tests: `flutter test`
- Integration tests: `flutter test integration_test/`

## Architecture Constraints

- **Notification Archiver** is Android-only. Web shows read-only archive view.
- **Media Cleaner** is mobile-only (device-local file access). Not available on web.
- **Wallet** is fully cross-platform (Android + Web + iOS).
- All user data lives in Supabase. No local-only persistence except media file operations.
- Supabase Row Level Security (RLS) must be enabled on all tables.
- Never store Supabase service_role key in the Flutter app — use anon key + RLS only.

## Session Orientation

When a new Claude session starts, read in this order:
1. This file (`CLAUDE.md`)
2. `Project-state.md` — where are we?
3. `docs/ai-index.md` — codebase map
4. `Project-plan.md` — big picture (only if needed)
5. `docs/research/*` — only when domain detail is required
