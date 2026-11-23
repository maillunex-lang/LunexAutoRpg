# Дорожная карта LunexAutoRpg

[GDD v0.1](GDD.md). Порядок ниже предложен с учётом зависимостей. По каждому выбранному этапу поиск и рекомендации на GitHub предшествуют утверждению внедрения.

| Этап | Скелет этапа | Проверка результата | Статус |
| --- | --- | --- | --- |
| 0. GDD и план | Общая концепция, первый игровой сценарий, этапы и порядок утверждения | Владелец утверждает GDD и выбирает этап | На утверждении |
| 1. [Каркас Android и Godot](STAGE-01.md) | Тестовая 3D-зона, персонаж, камера, сенсорное движение, горизонтальная сборка | APK запускается на Android, персонаж двигается | Завершён, принят на Android |
| 2. [Сетевой каркас](STAGE-02.md) | Выделенный сервер, тестовый вход, подключение и синхронизация игроков | Два клиента видят движение друг друга и могут переподключиться | Завершён, принят на Android |
| 3. [Автонавигация и бой](STAGE-03.md) | Выбор цели, путь к цели, противник, ручное и автоматическое управление боем | Игрок может начать и остановить автобой, сервер определяет результат | Завершён, принят на Android |
| 4. [Прогресс и сохранение](STAGE-04.md) | Простое задание, добыча, опыт, инвентарь и экипировка | Награда выдана один раз, прогресс сохраняется после перезапуска сервера | Завершён, принят на Android |
| 5. [Совместная игра](STAGE-05.md) | Чат зоны и общая PvE-цель с учётом участия игроков | Два игрока общаются и получают положенные награды за общий бой | Завершён, принят на Android |
| 6. [Сборка скелета на VPS](STAGE-06.md) | Развёртывание, запуск и перезапуск сервера, основной интерфейс, замеры на Android и VPS | Два Android-устройства проходят сквозной сценарий, результаты замеров записаны | Завершён, принят на Android |
| 7. Детализация | По итогам скелета утверждаем правила механик, контент и дальнейший объём | Определены приоритеты и отдельные критерии для следующей версии | Начат |
| 7.1. [Первый визуальный проход](STAGE-07-01.md) | Low-poly герой и противник, анимации, три пиксельных материала арены | Визуальные ресурсы и анимации проверены на Android | Развёрнут на VPS, ожидает приёмки на Android |
| 7.2. [Первая игровая глава](STAGE-07-02.md) | Цепочка заданий, выбор цели, уровень и второй слот | Оба задания пройдены, прежние сохранения загружаются | Завершён, принят на Android |
| 7.3. [Ответные атаки и возрождение](STAGE-07-03.md) | Урон дозорного, ОЗ героя и возрождение | Два клиента видят результат атаки и возрождение | Завершён, принят на Android |
| 7.4. [Боевое умение и бонусы экипировки](STAGE-07-04.md) | Мощный удар, перезарядка, бонусы кольца и медальона | Умение и характеристики подтверждены двумя клиентами | Отложен |
| 7.5. [Вторая локация за воротами](STAGE-07-05.md) | Каменный проход, переход между зонами, страж и короткое задание | Два игрока могут перейти, победить стража и сохранить прогресс | Развёрнут на VPS, ожидает приёмки на Android |
| 7.6. [Живой мир и NPC](STAGE-07-06.md) | 3 NPC, 5 квестов, автопуть, журнал, серверные проверки и SQLite | Поэтапная приёмка, два клиента и сохранение прогресса | Завершён, принят на Android 23.11.2026; production stage75 не переключён |
| 7.7. [Классы и боевые умения](GDD-07-07.md) | 4 класса, автобой + ручные навыки, постепенное открытие | [План 7.7.1](STAGE-07-07-01-PLAN.md), [GitHub-проверка](GH77-COMPATIBILITY.md) | 7.7.1 принят; [7.7.2 реализован в dev](STAGE-07-07-02-RESULT.md), **ожидает приёмки**; 7.7.3 не начат |

Для каждого завершённого этапа добавляем запись с датой, ссылкой на коммит или PR, утверждёнными источниками, адаптациями и результатом проверки.

22.11.2026 — для этапа 1 внедрены тестовая зона, камера, персонаж и адаптированный MIT-джойстик. Подпись APK и сценарий ввода в Godot проверены. [Коммит реализации](https://github.com/maillunex-lang/LunexAutoRpg/commit/f5af2352d656c4b713533aac3199bc8b54b44072)

22.11.2026 — владелец подтвердил приёмку этапа 1 на Android. [Результаты проверки](STAGE-01.md)

22.11.2026 — для этапа 2 внедрён Godot ENet, сервер развёрнут на Lunex, сетевой сценарий с двумя клиентами прошёл на VPS. [Реализация](https://github.com/maillunex-lang/LunexAutoRpg/commit/aac998b) · [Проверки](STAGE-02.md#развёртывание-и-проверки)

22.11.2026 — владелец подтвердил приёмку этапа 2 на Android. Подготовлены [рекомендации этапа 3](STAGE-03.md).

22.11.2026 — этап 3 развёрнут на Lunex. Тесты боя и сетевого каркаса с двумя клиентами пройдены на VPS. [Коммит реализации](https://github.com/maillunex-lang/LunexAutoRpg/commit/a800f3c) · [Результаты проверки](STAGE-03.md#результаты)

22.11.2026 — владелец подтвердил приёмку этапа 3 на Android. [Результаты проверки](STAGE-03.md#результаты)

22.11.2026 — этап 4 развёрнут на Lunex. Проверены одноразовая награда, отдельные профили и восстановление экипировки после перезапуска сервера. [Реализация](https://github.com/maillunex-lang/LunexAutoRpg/commit/507d5b6) · [Результаты](STAGE-04.md#результаты)

22.11.2026 — владелец подтвердил приёмку этапа 4 на Android. [Результаты проверки](STAGE-04.md#результаты)

22.11.2026 — этап 5 развёрнут на Lunex. Чат, совместные награды и загрузка прогресса этапа 4 проверены на VPS. [Реализация](https://github.com/maillunex-lang/LunexAutoRpg/commit/72edb3f) · [Результаты](STAGE-05.md#результаты)

22.11.2026 — владелец подтвердил приёмку этапа 5 на Android. [Результаты проверки](STAGE-05.md#результаты)

22.11.2026 — этап 6 развёрнут на Lunex. Сквозной прогон и восстановление двух профилей проверены на VPS. Замеры процесса сохранены, замеры Android ожидаются. [Реализация](https://github.com/maillunex-lang/LunexAutoRpg/commit/13b518c) · [Результаты](STAGE-06.md#результаты)

22.11.2026 — записаны замеры iQOO 15R и Xiaomi 13T Pro из APK 0.6.0. [Результаты Android](STAGE-06.md#приёмка-на-android)

22.11.2026 — этап 6 принят. Владелец подтвердил сохранение опыта и экипировки после перезапуска рабочей службы. [Результаты](STAGE-06.md#приёмка-на-android)

22.11.2026 — этап 7.1 развёрнут на Lunex. Сетевая проверка анимаций и сохранений пройдена. [Результаты](STAGE-07-01.md#результаты)

22.11.2026 — первая игровая глава развёрнута на Lunex. Миграция существующих профилей, совместная награда и два слота проверены. [Результаты](STAGE-07-02.md#результаты)

22.11.2026 — этап 7.3 развёрнут на Lunex. Уклонение, урон, падение и возрождение проверены на двух тестовых клиентах. [Результаты](STAGE-07-03.md#результаты)

23.11.2026 — владелец подтвердил приёмку этапа 7.3 на Android. [Результаты](STAGE-07-03.md#результаты)

23.11.2026 — этап 7.5 развёрнут на Lunex. Переходы, изоляция зон и сохранение совместной награды проверены. [Результаты](STAGE-07-05.md#результаты)

23.11.2026 — утверждён 7.6 A и решения GH76-001 ADAPT, GH76-002 STUDY, GH76-003 SKIP. Этап 7.6.1 реализован без переключения production, прошёл тесты двух клиентов и регрессию 7.5. [Описание и результаты](STAGE-07-06.md).

23.11.2026 — по команде владельца принят 7.6.1, реализован 7.6.2: Dialogue Manager 4.2.0 MIT, три ветвящихся диалога, редактируемое окно, серверный доступ; тесты 7/7 и регрессия 7.5 20/20. Android не проверен, production не изменён.

23.11.2026 — по команде владельца принят 7.6.2; выполнен 7.6.3: серверная SQLite-инфраструктура сюжетных квестов и проверки состояний. Тесты 15/15, диалоги 7/7, регрессия 7.5 20/20. Не развёрнуто в production, 7.6.4 не начат.

23.11.2026 — принят 7.6.3; реализован 7.6.4: 5 связанных NPC-заданий с проверкой сервером, 11/11 NPC, 26/26 SQLite, 20/20 регрессия. Не развёрнуто в production, Android не проверен.

23.11.2026 — принят 7.6.4; реализован 7.6.5: журнал пяти сюжетных заданий, серверный автопуть к NPC/воротам. Проверки 15/15, SQLite 26/26, регрессия 20/20. APK и production не затронуты.

23.11.2026 — принят 7.6.5; этап 7.6.6: VPS-регрессия 15/15 + 26/26 + 20/20, Android debug APK 0.7.6 собран, подписан и доступен на rikagro.ru/download/LunexAutoRpg-0.7.6-debug.apk. Физический Android не проверен, 7.6.7 тестовый сервер и APK опубликованы, ожидается проверка Android и финальная приёмка.

23.11.2026 — 7.6.7 частично: отдельный UDP/28766 тестовый сервер с независимой SQLite и APK с предзаполненным тестовым портом; живой smoke 15/15. Production stage75 не менялся. Ждём проверки Android.

23.11.2026 — владелец подтвердил Android-приёмку 7.6.6–7.6.7: «Все работает, делаем дальше». Этап 7.6 закрыт. Тестовый сервер stage76 продолжает работать отдельно, production stage75 не изменён. Следующий 7.7 подлежит отдельному проектированию и утверждению.

23.11.2026 — утверждён GDD-07.7: CLASS-077 A (воин/маг/жрец/бард), COMBAT-077 A (автобой + ручные навыки), SKILLS-077 B (постепенное открытие), GITHUB-077 A (GH77-001 STUDY, 002 TEST, 003 STUDY, 004 ADAPT). Подготовлены план 7.7.1 и первичный аудит GitHub. Код, БД, APK и серверы не изменены; внедрение ждёт отдельного разрешения.

23.11.2026 — утверждён LEGACY-077 B: старые и новые персонажи получают класс «Воин» в SQLite без изменения текущего боя. Выполнен только 7.7.1: четыре Godot Resource-класса, идемпотентная SQLite-миграция, серверный whitelist. Тесты 19/19 + 26/26 + 15/15 + 20/20 = **80/80 PASS**; Android debug export успешен. [Отчёт](STAGE-07-07-01-RESULT.md). Production и тестовый сервер 7.6 не изменены; 7.7.2 не начат, ждём приёмки.

23.11.2026 — владелец ответил «Делай» после отчёта 7.7.1: принято как разрешение продолжить 7.7.2. Реализованы выбор класса для новых персонажей, серверная однократная фиксация класса, отображение класса рядом с ником. LEGACY-077 B сохранён: старые персонажи автоматически зафиксированы как Воин. 21+26+15+20=**82/82 PASS**, Android APK локально собрана и подписана. [Отчёт 7.7.2](STAGE-07-07-02-RESULT.md). Серверы не переключены. Ожидается приёмка 7.7.2, 7.7.3 не начат.

23.11.2026 — для ручной приёмки 7.7.2 запущен отдельный сервер `lunex-autorpg-stage772-test.service` на UDP `28777` с собственной SQLite; опубликована [APK 7.7.2](https://rikagro.ru/download/LunexAutoRpg-0.7.7.2-class-test.apk), проверена подпись и HTTP 200. **Ждём проверки владельца на Android.** 7.7.3 не начат.

2026-11-23: 7.7.2 accepted. Stage 7.7.3 implemented in dev: editable ability definitions, authoritative validation engine, cooldowns, status data. [Report](STAGE-07-07-03-RESULT.md). Tests 102/102 PASS, Android export/sign verified. No live server changes. Stage 7.7.4 not started; awaits owner acceptance.

2026-11-23: Owner accepted 7.7.3. Stage 7.7.4 implemented in dev: [Warrior and Mage abilities](STAGE-07-07-04-RESULT.md), authoritative skill RPC, training-target damage, shield, energy regeneration, editable HUD and resources. 117/117 automated checks passed; Android debug export/signature OK. No running services updated. Awaiting acceptance; stage 7.7.5 not started.

2026-11-23: Owner accepted 7.7.4 ("Делай"). Implemented stage 7.7.5: [Priest and Bard support skills](STAGE-07-07-05-RESULT.md), server-selected allies, healing, temporary damage reduction and four editable skills. 134/134 automated tests PASS; Android debug export and signature OK. No live service changed. Awaiting 7.7.5 acceptance, 7.7.6 not started.

2026-11-23: Owner accepted 7.7.5 ("Все ок, делай дальше"). Stage 7.7.6 implemented in dev: [manual skill priority, HUD cooldowns and procedural VFX](STAGE-07-07-06-RESULT.md). 146/146 automated checks passed; Godot headless import, Android debug export and signature OK. Live servers unchanged. Awaiting 7.7.6 acceptance; 7.7.7 not started.

2026-11-23: Owner accepted 7.7.6. Stage 7.7.7 implemented in dev: [anti-cheat, ability limits, LOS and full regression](STAGE-07-07-07-RESULT.md). 179/179 automated checks passed, Godot headless import and signed Android debug APK export passed (58 MB). Preliminary balance retained, not finalized. No live services or public APK changed. Awaiting owner acceptance; 7.7.8 not started.

2026-11-23: Owner accepted 7.7.7 and authorized 7.7.8. Isolated four-class Android combat test [deployed](STAGE-07-07-08-RESULT.md) on UDP 28788 with independent SQLite and public signed APK at https://rikagro.ru/download/LunexAutoRpg-0.7.7.8-test.apk (HTTP 200). Server active, 179/179 prior automated checks passed. Manual Android/two-client acceptance PENDING. Production and previous tests untouched. No next stage started.

2026-11-23: Stage 7.7.8 live server smoke supplement: 7/7 two-client Godot ENet checks passed on UDP 28788; authoritative movement, wall collision, reconnect and error recovery verified. Manual Android combat/healing still pending. No new stage started.

2026-11-23: GDD-08.1 dark fantasy concept C confirmed; owner approved WORLD-081 B (one map/five zones), TERRAIN-081 A (native Godot Mesh scenes), ART-081 B (Stylized Dark Fantasy). [GDD-08-01.md](GDD-08-01.md) records the design, eight proposed stages and five GitHub candidates for study/compatibility only. **No GDD-08 implementation or candidate integration authorized** until manual 7.7.8 acceptance and separate permission.

2026-11-23: GDD-08.2 monster/AI/spawn design drafted for approval in [GDD-08-02.md](GDD-08-02.md), including GitHub candidate study GH08-003/004/006-009. AI-082, SPAWN-082, AGGRO-082, BOSS-082 are proposed, NOT approved. **No code/integration/deployment; stage 7.7.8 manual acceptance remains pending.**

2026-11-23: Owner APPROVED GDD-08.2 recommendations: AI-082 A (server-side FSM), SPAWN-082 B (fixed spawn points, varied composition), AGGRO-082 B (threat/roles/healing), BOSS-082 B (two phases with telegraphed attacks). Recorded in [GDD-08-02.md](GDD-08-02.md). Candidate repositories remain STUDY/COMPAT only. Stage 7.7.8 manual Android acceptance PENDING; GDD-08 code/deployment BLOCKED.

2026-11-23: [GDD-08-03.md](GDD-08-03.md) drafted for approval: chapter 1 'Звон из тумана', proposed 10 main quests, side quests, NPCs, events, quest persistence architecture, and GitHub STUDY/COMPAT candidates GH08-010..013. QUEST-083/EVENT-083/CUTSCENE-083/PARTY-083 are NOT approved. GDD-08 implementation blocked pending stage 7.7.8 manual acceptance.

2026-11-23: Owner established **Era of Celestials** (https://play.google.com/store/apps/details?id=com.gtarcade.eoa) as LunexAutoRpg's primary gameplay/UX reference. See [REFERENCE-ERA-OF-CELESTIALS.md](REFERENCE-ERA-OF-CELESTIALS.md). This does NOT authorize copying assets or implementing additional systems. Stage 7.7.8 manual acceptance still pending; GDD-08 design only.

2026-11-23: GDD-08.3 read-only code audit / Era of Celestials pacing review documented in [GDD-08-03-IMPLEMENTATION-REVIEW.md](GDD-08-03-IMPLEMENTATION-REVIEW.md). GitHub candidates GH08-014 (cutscenes) and GH08-015 (archived sample) added to research; no candidate integrated. QUEST-083 A, EVENT-083 B, CUTSCENE-083 B, PARTY-083 B remain recommendations awaiting owner approval. Stage 7.7.8 manual acceptance PENDING.

2026-11-23: OWNER APPROVED GDD-08.3 QUEST-083 A, EVENT-083 B, CUTSCENE-083 B, PARTY-083 B. Details in [GDD-08-03.md](GDD-08-03.md). Owner instituted mandatory GitHub candidate search, compatibility/license/maintenance analysis and USE/ADAPT/STUDY/REJECT proposal at EVERY future stage; see [GITHUB-CANDIDATE-POLICY.md](GITHUB-CANDIDATE-POLICY.md). Independent explicit approval required before any installation/adaptation/integration. @devbridgelunex LunexAutoRpg memory recorded. 7.7.8 manual acceptance pending; GDD-08 implementation BLOCKED.
