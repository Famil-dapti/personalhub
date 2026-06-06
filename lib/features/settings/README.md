# settings

Per-account app settings (Phase 4). Currently the Groq API key that enables the
AI fallback parser for notification -> transaction extraction.

- **Public surface:** `SettingsScreen` (the "Ayarlar" tab); `groqApiKeyProvider`
  (streams the synced key); `settingsControllerProvider` (`setGroqKey` /
  `clearGroqKey`).
- **Storage:** synced per-user via the Drift `LocalUserSettings` mirror +
  Supabase `user_settings` table (RLS, one row per user, id == user id).
- **Dependencies:** core/db (Drift), core/sync, core/supabase.
