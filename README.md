# Face-Sync Updater Repository

This repository serves as the **Central Storage & Versioning System** for the automatic update mechanism (*auto-update*) of the **Face-Sync** application suite.

The main Go Updater application running on the production server periodically reads the `version.json` file from this repository to detect, download, and hot-swap modified system components via PM2.
<!-- 
---

## 📁 Repository Structure

* **`version.json`**: The master manifest file that tracks the latest version, download URL, and PM2 service name for each standalone component.
* **`backend.zip`**: Production binary bundle for the Backend service.
* **`worker.zip`**: Production binary/script bundle for the Worker service.
* **`webui.zip`**: Production Next.js Standalone build bundle (includes `.next`, production `node_modules`, `public`, `static`, `package.json`, and `server.js`).

--- -->
