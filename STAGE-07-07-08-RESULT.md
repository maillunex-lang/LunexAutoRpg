# 7.7.8 - Isolated Android combat acceptance environment

**Status:** isolated test environment deployed; owner manual Android acceptance pending. No next stage started.

## Deployment
- Isolated Godot project: `/opt/lunex-autorpg/stage778`, copied from stage76 with stage 7.7.7 code and configured default client port UDP 28788.
- Dedicated service: `lunex-autorpg-stage778-test.service` (active).
- Dedicated database: `/var/lib/lunex-autorpg-stage778-test/progress.sqlite`; confirmed opened successfully.
- Dedicated UDP port 28788 opened in UFW; server confirmed listening.
- APK: `https://rikagro.ru/download/LunexAutoRpg-0.7.7.8-test.apk` (HTTP 200), 60,678,391 bytes.
- APK SHA256: `98928e8d1c9d32369878b64592df62d6bdfdaff9353b6122c019cd2e2eea88e4`.
- Godot 4.7.2 editor import and Android debug export passed; apksigner verification passed.

## Prior automated checks
- Stage 7.7.7 and earlier: 179/179 PASS on stage76 before isolated deployment.

## Acceptance checklist (manual, not yet completed)
1. Install APK on Android, create new character, select each of four classes (separate profiles).
2. Warrior: strike, shield (level 2), auto-attack priority and cooldown HUD.
3. Mage: bolt, fireball (level 2), distance checks and energy regeneration.
4. Priest: healing of injured teammate and blessing (level 2).
5. Bard: nearby team damage reduction and restoration (level 2).
6. Two Android clients connected simultaneously: verify healing/support, cross-zone protection, no crashes, and persistence on reconnect.
7. Verify server journal for errors and inspect resource usage during gameplay.

**Important:** Service readiness and automated tests are not proof of actual multi-client gameplay. No live two-client combat test was performed. No production or older test service was changed. Do not mark 7.7.8 accepted until owner completes gameplay checks.

## Additional live server verification (2026-11-23)
- Ran `tests/stage02_smoke.gd` against the **already running** isolated UDP 28788 server, using two actual Godot ENet clients.
- **7/7 live network smoke checks PASS:** two clients connect and see one another, movements replicate both directions, wall collision is server-enforced, disconnect removes the pawn, reconnect restores both pawns, and connection failure restores the UI.
- Server stayed active. Journal reported `LUNEX_METRICS players=2 physics_mean_ms=0.061 physics_max_ms=0.372 ticks=301` during the test.
- This test does not validate Android touch input or two-client skill casting/healing. Those remain pending manual acceptance.
