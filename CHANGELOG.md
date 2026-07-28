# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and each component follows [Semantic Versioning](https://semver.org/).

> **Note:** Each `#` date heading marks a joint release (components shipped together). Dates below are placeholder/dummy values — replace them with the actual release dates.

---

# 2026-07-28

## [1.4.0] - launcher
### Changed
- Re-released and bumped the central Launcher ecosystem version to bundle and encapsulate the latest robust media processing updates across the Backend (`v1.7.0`), WebUI (`v1.6.0`), and Worker (`v1.4.0`) components.

## [1.7.0] - backend
### Added
- Introduced event-driven recording capabilities by adding `record_on_detect` and `record_segment_secs` configuration fields to the device/camera data schemas.

### Fixed
- Enforced strict scope validation and limit boundary checks during the creation and provisioning workflows of new camera devices.

### Security
- Implemented robust Magic Byte (file signature) validation within the file upload middleware to definitively verify payload integrity and mitigate malicious file injection vectors.

## [1.6.0] - webui
### Added
- Upgraded the camera management interface by integrating a dedicated "Record on Detect" toggle and a dynamic input field for configuring "Recording Segment Duration (Seconds)".

## [1.4.0] - worker
### Added
- Engineered a new, highly robust `Recorder` class responsible for managing complex video stream lifecycles, including initialization, start/stop executions, and seamless segment finalization.
- Integrated automated "Record on Detect" processing directly into the active device stream pipeline, allowing the system to instantly capture and save video segments triggered by recognition events.

---

# 2026-07-26

## [1.6.1] - backend
### Fixed
- Fixed the static file server configuration to correctly resolve and serve storage files directly from the designated path defined within the `.env` configuration file, rather than defaulting to incorrect directories.

## [1.3.1] - launcher
### Changed
- Re-released and bumped the Launcher version to encapsulate and bundle the latest patch update from the backend (`v1.6.1`).

## [1.6.0] - backend
### Added
- Added global license quota enforcement mechanisms across Department, Employee, and Camera repositories. Batch imports are now intelligently truncated to fit remaining quotas instead of rejecting entire payloads outright.
- Added automated self-service Community License request workflows within `LicenseService` for frictionless deployments.
- Added a comprehensive `TelemetryService` orchestrating pulse checks, user feedback, and usage counters. Features robust cron-based scheduling for daily log uploads, 6-hour flushes, and boot-time catch-up routines to recover data from missed downtime windows.

### Changed
- Refactored daily telemetry log uploads to be fully idempotent, automatically purging files post-upload and recording explicit logs when queues are empty.
- Removed the default department factory from the database seeder.

### Fixed
- Fixed critical race conditions within the `LicenseService` shared state by implementing `sync.RWMutex` locking across read/write operations and securing active plan bounds inside an encrypted lockfile.
- Fixed error visibility during the license validation flow by replacing strict `Decoder.Decode` bindings with `io.ReadAll`, properly differentiating between "failed to reach server" network errors and active "server rejected key" denials.
- Fixed inaccurate Attendance Summary aggregate counting metrics feeding the overview analytics dashboard.

## [1.5.0] - webui
### Added
- Added a dedicated "System & License" tab inside the settings panel detailing active plans, limit usages, expiration thresholds, and a guided "Start with Community Edition" self-service activation dialog.
- Added page-view telemetry tracking logic (excluding Kiosk routes) supported by a debounced `TelemetryProvider`.
- Added a `PulseCheckWidget` (a biweekly satisfaction popup) and a global floating `FeedbackWidget` to seamlessly route operator experiences back to the engineering telemetry stream.
- Added advanced Employee KPI analytics tracking Discipline Index, Attendance ratios, and Punctuality percentiles within the employee detail page and the monthly summary `.xlsx` export.

## [1.3.0] - launcher
### Added
- Added `GetWebUIPort()` application bindings to dynamically read the active `WEBUI_PORT` from local `.env` variables (defaulting to 3000 if unset).
- Added a live dashboard URL badge to the Services UI header alongside a functional "Open Dashboard" footer action button utilizing the native Wails `BrowserOpenURL` invocation.

### Changed
- Re-released and bumped the central Launcher ecosystem bundle version to deliver the major architectural updates across Backend (`v1.6.0`), and WebUI (`v1.5.0`).

---

# 2026-07-24

## [1.2.3] - launcher
### Added
- Added `supported_runtimes` and `supported_os` validation guards prior to initiating variant package downloads.
- Added automatic legacy binary file cleanup post-update to gracefully migrate pre-rename installations to the new naming scheme.

### Changed
- Pointed `manifestURL` to `manifest.json` on the primary `face-sync` repository.
- Integrated dynamic `{version}/{runtime}/{os}` placeholder resolution using `appRuntime` (injected via `ldflags`) and `runtime.GOOS`.
- Refactored bundled service binary names to streamline system architecture:
  - `backend` $\rightarrow$ `core`
  - `worker` $\rightarrow$ `processor`
  - `mediamtx` $\rightarrow$ `stream`
  - `piper` $\rightarrow$ `voice`
  *(Note: `webui` remain unchanged)*

### Fixed
- Fixed a process hanging issue during `restartSelf` on Windows where `cmd /C start "" /MIN <script>` spawned an orphaned, interactive command window. Replaced the execution logic with direct `cmd /C <script>` invocation to respect `HideWindow` parameters and prevent unclosed background console sessions.

## [1.4.0] - updater
### Added
- Added dynamic placeholder resolution for `{version}`, `{runtime}`, and `{os}` parameters within `download_url` entries in `manifest.json`.
- Added runtime and OS detection fallback mechanism (`cuda` and native `GOOS`) using `.env` inputs for precise platform variant targeting.

### Changed
- Updated the update Manifest URL to point to `manifest.json` (migrated from legacy `version.json`).

---

# 2026-07-22

## [1.5.0] - backend
### Added
- Added a full Role-Based Access Control (RBAC) engine supporting granular permissions, role hierarchies, and department scoping.
- Added a `non_working_day` status code for accurate tracking of scheduled off-days.
- Added dashboard analytics endpoints to aggregate workforce stats, attendance trends, late ranks, and detection metrics.
- Added camera management endpoints providing programmatic controls for PTZ movement, manual siren triggers, and Text-to-Speech (TTS) audio playback.
- Added a CLI `db:status` command returning JSON state (`migrated`, `has_data`) to prevent destructive migrations when core database tables are already populated.

### Fixed
- Fixed database dump structures to ensure idempotency and prevent duplicate key violations upon re-restoration.
- Fixed break time deduction rules based on statutory labor standards (*UU Ketenagakerjaan Pasal 79*): break times are no longer subtracted if actual working hours (check-in to check-out) are less than 4 hours.
- Fixed boundary condition detection logic when processing cross-day overnight shifts.

## [1.4.0] - webui
### Added
- Added a comprehensive User Management page featuring user creation, permission toggles, department assignment matrices, and `canManage()` privilege guards.
- Added a reusable `DepartmentPicker` multi-select dropdown component.
- Added an Analytic Dashboard page presenting real-time stats across custom date ranges (Today, 7D, 30D, Monthly).
- Added an Employee Detail view displaying profile info, face enrollment status, current month attendance summary, daily calendar, and recent check-in/out logs.
- Added a Work Schedule Detail view with full attendance breakdowns, override information, and a visual detection event timeline with preview and download capabilities.
- Added a Camera Management console (`/cameras/[id]`) featuring live streaming, PTZ directional pad controls, manual siren toggling, TTS text dispatching, device capabilities rechecking, and recognition zone configuration.

### Changed
- Refactored sidebar navigation logic to dynamically filter items based on active user module read permissions in addition to role thresholds.

## [1.3.0] - worker
### Added
- Added spatial Recognition Zone filtering using a Point-in-Polygon algorithm (`_is_in_recognition_zone`). Facial tracks outside normalized (0–1) zone coordinates are automatically filtered out prior to recognition publishing.
- Updated benchmark visualization tools to render zone polygons (red outlines) and bypass bounding boxes outside defined zones.

## [1.2.1] - launcher
### Fixed
- Fixed a data loss vulnerability where a missing lockfile executed `migrate --fresh` even when populated database tables existed. The setup process now inspects `db:status` first, falling back to safe migrations if existing data is detected.
- Added a robust `extractJSON[T]` stream parser to reliably isolate JSON status objects embedded within mixed log streams.

---

# 2026-07-15

## [1.3.0] - webui
### Added
- Added Screen WakeLock integration to the Kiosk page to guarantee the monitor remains continuously powered on during operations.
- Added an operational log list view under the Kiosk display to present recent scan history instantly.
- Added advanced master data input forms for complex Work Day types.
- Added support for Work Schedule dynamic exceptions to easily log off-days, corporate holidays, and emergency leaves.
- Added bulk employee data management via native Excel (`.xlsx`) import and export capabilities.
- Added a dedicated Backup & Restore control hub within the system settings dashboard.
- Added a break duration configuration field inside the Shift Management form.
- Added a smart warning system notifying administrators if the scheduled shift duration minus break times violates the maximum 8-hour daily limit per regulatory standards (*PP No. 35 Tahun 2021*).

### Changed
- Refactored high-traffic Kiosk audio notifications: when the processing queue surpasses the designated threshold $N$, the system plays a swift audio beep instead of reciting individual names to reduce lane congestion.

### Fixed
- Fixed a validation component bug encountered when attempting to select and assign employees to bulk scheduling pools.

## [1.4.0] - backend
### Added
- Added an automated early checkout framework (`earlyCheckoutSec`) allowing the processor to validate early structural departures safely.
- Added an advanced Work Day type engine supporting default dynamic seeds (`Work`, `Off Day`, `Holiday`, `Leave`, `WFH`).
- Added a `break_duration_secs` field into database models mapping out mandated break slots matching statutory codes (*PP No. 35 Tahun 2021*).
- Added a comprehensive Backup, Archiving, and Restoration service engine equipped with scheduled cron routines. The system tracks absolute disk telemetry metrics (Total, Used, Free capacity), compiles live database instances into compressed `.zip` downloads, allows automated interval routing, and hosts a cleanup engine to purge legacy screenshots and heavy detection artifacts.

### Fixed
- Fixed a decryption crash issue throwing false-positive "license tampered or corrupted" alerts during boot checking.
- Fixed boundary mathematical calculation bugs regarding late arrival tolerance limits.

## [1.2.0] - worker
### Added
- Added a robust multi-face tracking pipeline by integrating the *ByteTracker* algorithm to optimize spatial coordinates handling.

### Changed
- Refactored core infrastructure by completely decoupling the face detection and face recognition processing routines into isolated worker execution tracks.

### Renamed / Optimized
- Optimized ArcFace facial matching limits to drastically reduce compute latency, accelerating verification loops.

## [1.2.0] - launcher
### Added
- Added a robust single-instance mechanism using a TCP loopback mutex bound to `127.0.0.1:38271` via `acquireSingleInstanceLock()`. When a second app instance attempts to spawn, it safely opens an IPC channel to send a "show" trigger command to the primary active instance and then gracefully terminates itself without generating redundant window processes.

### Fixed
- Fixed an interaction glitch where the system tray menu became unresponsive and failed to register clicks while the main graphical window remained unfocused or in the background.
- Fixed stream handling reliability by adding the mandatory `scanner.Err()` checks following `bufio.Scanner` loop closures to catch hidden I/O stream tokenization issues.

---

# 2026-06-25

## [1.0.1] - launcher
### Changed
- Re-released and bumped Launcher version to encapsulate and bundle the latest core update from the backend (`v1.3.0`).

## [1.3.0] - backend
### Added
- Added up to a 14-day offline tolerance grace period to the license verification pipeline when network faults occur.
- Added backend logic to compute overtime data during manual admin overrides and whenever a work schedule changes post-attendance.
- Added an automated error tracking system where errors are actively appended to local `.txt` logs and dispatched once every day.

### Changed
- Refined the work duration calculation formulas to use the check-in time if `checkin >= shift start`, but gracefully fall back to the shift start timestamp if the employee clocked in early (`checkin < shift start`).

### Fixed
- Fixed a bug causing an unexpected "Not Found" HTTP response error when attempting to delete valid work schedule entities.
- Fixed inaccuracies and bugs within the early arrivals and late departures calculation formulas to guarantee compliant reporting.

---

# 2026-06-01

## [1.0.0] - launcher
### Added
- Initial Windows release of the launcher as the desktop UI launcher and service manager, currently targeted and optimized exclusively for the Windows desktop platform.

## [1.3.0] - updater
### Added
- Users can now configure and execute fetch settings directly within the updater component.

## [1.2.0] - backend
### Added
- Implemented backend logic to compute overtime data, extending the data structures to support daily and monthly reporting.

### Changed
- Added the work schedule date directly to the stdout logs during attendance processing to streamline backend troubleshooting and debugging.

## [1.1.2] - worker
### Fixed
- Resolved a performance issue where the Piper service experienced high latency during its first run. The service now performs a dummy synthesis on startup to warm up the engine, ensuring all subsequent requests are processed instantly.

## [1.2.0] - webui
### Added
- Added a new date column to the Attendance table, linked to display the corresponding work schedule date.
- Integrated the new overtime fields into the frontend views and daily/monthly Excel export actions.

---

# 2026-05-01

## [1.0.0] - builder
### Added
- Added a brand-new, lightweight desktop UI launcher developed using the Wails framework.
- Integrated a real-time log viewer to monitor all background system services from a single interface.
- Implemented a native startup feature enabling services to automatically run upon system boot.

## [1.1.0] - backend
### Added
- Added new database factories for Employees, Work Schedules, and Attendances to facilitate better seeding and automated testing.

### Changed
- Introduced chunk-based processing for detection logs during attendance exports to minimize memory overhead and prevent timeouts.

### Fixed
- Resolved a bug where employee facial embeddings failed to preload when executing a "load all" database query.

## [1.1.1] - worker
### Fixed
- Fixed a configuration bug, ensuring the worker reliably reads and applies system parameters directly from the local `.env` file.

## [1.1.2] - webui
### Changed
- Overrode strict frontend validation constraints, marking specific non-critical input fields as optional to prevent form submission blockages.

### Fixed
- Fixed the password update mechanism so that submitting the form no longer errantly mandates the inclusion of the old password.

---

# 2026-04-01

## [1.1.1] - webui
### Fixed
- Resolved a "Not Found" error that triggered unpredictably when users attempted to toggle the camera state or delete a camera profile from the dashboard.

## [1.0.4] - backend
### Changed
- Externalized the Piper TTS host configuration.

## [1.1.0] - worker
### Added
- Integrated Redis HNSW (Hierarchical Navigable Small World) indexing support to efficiently store, index, and query high-dimensional encoded face embeddings.

## [1.1.0] - self
### Added
- Added a new configuration for the Piper HTTP server into `supervisor.conf`, ensuring the new HTTP-based TTS service is automatically managed and monitored by the system supervisor.

## [1.2.0] - updater
### Added
- Updater now checks for `supervisord.conf` changes on every run and automatically applies them without manual intervention.
- When a config change is detected, the container restarts automatically to apply the new supervisor configuration.