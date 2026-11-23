# Android persistence architecture verification

2026-11-23 NEXUS run 56f70b51bcd94ba3946b4bcffdab7450

The previous run's conclusion that Android SQLite binaries were mandatory for the client was INCORRECT. Actual source shows SQLite is instantiated only by `LunexProgressStore.open`, invoked from `online_world.gd:_start_server` when `--server` command line flag is present. Android clients use `ConfigFile` only for local profile token and HUD preferences; authoritative quest/class/XP persistence is handled by the Linux ENet server. The Android export preset deliberately excludes server-side `addons/godot-sqlite/*`. No Android SQLite extension is needed by the intended Android client.

Do not add an Android SQLite dependency or change database architecture. Validate client export and actual runtime separately; server SQLite extension remains necessary on Linux. Client must never use `--server` in Android launch. This corrects earlier audit, not evidence that an Android APK has passed device acceptance.
