# 🚀 MynaTask Pro: Scalable Engine Edition

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=for-the-badge&logo=powershell)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Stable-orange?style=for-the-badge)

**MynaTask Pro** is a high-performance, lightweight system process manager built with PowerShell and WPF (XAML). Designed for developers and power users, it utilizes native Windows APIs to provide deep control over system threads, allowing for the suspension and resumption of processes without termination.

---

## ✨ Key Features

* **⚡ Ultra-Stable Engine:** Implements Dynamic Class Injection to prevent "Type already exists" errors, ensuring 100% stability during script re-runs.
* **📉 Real-Time Telemetry:** Monitor CPU load and RAM consumption per process with a high-refresh-rate dashboard.
* **❄️ Process Freezing:** Native `ntdll.dll` integration for **Suspend** and **Resume** actions—perfect for freezing resource-heavy apps or games temporarily.
* **🖥️ True Scalable UI:** A fully responsive XAML layout that adapts to any window size. No more blurry UI or broken layouts when maximizing.
* **🔍 Instant Search:** Heuristic search filtering to find and manage specific PIDs or process names instantly.
* **🛡️ Privilege Guard:** Integrated auto-elevation logic to ensure the engine always has the `NT AUTHORITY\SYSTEM` level access required for low-level API calls.

---

## 🛠 Prerequisites

* **OS:** Windows 10 or Windows 11 (x64).
* **Environment:** Windows PowerShell 5.1 (Run in STA Mode).
* **Permissions:** Administrative privileges are required for Native API interaction.

---

## 🚀 Quick Start

1.  **Clone/Download:** Grab the `MynaTaskPro.ps1` file.
2.  **Run:** Right-click the script and select **Run with PowerShell**.
3.  **Manage:**
    * Select any process from the grid.
    * Use **SUSPEND** to freeze or **RESUME** to unfreeze.
    * Use **TERMINATE** for a forced kill of stubborn applications.

---

## ⚠️ Important Notes

* **Antivirus:** Some AV engines may flag the script due to the use of `ntdll.dll` (standard for system tools). Please whitelist the script if you encounter execution blocks.
* **Critical Processes:** Exercise caution when suspending core Windows processes (e.g., `svchost.exe`, `csrss.exe`) as it may result in a System Freeze or BSOD.

---

## 👤 Author

* **Developer:** ItsMynaX (son171020)
* **Build:** v1.5 Stable Global
* **Stack:** PowerShell | XAML | C#

---

## 📜 License

This project is licensed under the **MIT License**. Feel free to fork, modify, and distribute as you see fit.

---
*Built for performance. Optimized for control.*
