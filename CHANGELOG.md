# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and each component follows [Semantic Versioning](https://semver.org/).

> **Note:** Each `#` date heading marks a joint release (components shipped together). Dates below are placeholder/dummy values — replace them with the actual release dates.

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