# CLAUDE.md — Fakhri Barcode APK

This file defines the behavioral rules Claude must follow when working on this project. Read at the start of every new session.

## Language Policy (strict)

- **Speak Turkish to the user only.** User-facing chat replies, planning questions, conversational explanations are Turkish.
- **Everything else is English.** All files (including this one), all code, all identifiers, all internal comments, all log strings, all commit messages, all branch names, all docs, all memory entries — English only.
- **No Turkish characters** (ğ ş ü ö ı ç) anywhere in files or code. User-facing chat is the only exception.

## Sub-Agent Usage (mandatory)

- Sub-agent usage via the `Agent` tool is **not optional, it is required** for this project.
- Use sub-agents for research, multi-file analysis, anything parallelizable.
- Single trivial file edits do not require sub-agents — every other case does.
- Agent type selection: code search → `Explore`, planning → `Plan`, open-ended research → `general-purpose`.

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
- **Per-module `README.md`** (3–10 lines): purpose, public surface, dependencies.

## Clean Code

- Follow the rules in `docs/clean-code-principles.md`.
- Summary: SRP, function ≤30 lines, comments only for WHY, error handling via `Result<T>`, no magic numbers.

## Build & Test

- Build: `./gradlew assembleDebug`
- Install (phone with USB Debugging enabled): `adb install -r app/build/outputs/apk/debug/app-debug.apk`
- Unit tests: `./gradlew test`
- Instrumented tests: `./gradlew connectedAndroidTest` (device must be attached)

## Development Strategy

- **Virtual Printer Mode** stays operational at all times. End-to-end testing must be possible without a real M-102 device.
- Bluetooth Classic SPP is the **default** transport; BLE and USB are fallbacks. The `PrinterTransport` interface abstracts all three.
- When the physical M-102 arrives, Phase 2 begins. Until then, all UI and data flow must be complete via the Virtual transport.

## Session Orientation

When a new Claude session starts, read in this order:
1. This file (`CLAUDE.md`)
2. `Project-state.md` — where are we?
3. `docs/ai-index.md` — codebase map
4. `Project-plan.md` — big picture (only if needed)
5. `docs/research/*` — only when domain detail is required
