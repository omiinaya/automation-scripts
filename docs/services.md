# Windows 11 Services – Safe to Disable for Performance & Stability (2026 Update)

This guide lists many common **Windows 11 services** (based on builds like 23H2, 24H2, and 25H2).  
It includes the **Display Name**, **Service Name**, brief **Description**, **Default Startup Type**, and whether it's generally **Safe to Disable** for better performance, lower resource usage, and privacy.

### Important Warnings
- **Safe to Disable** → **Yes** = Usually safe if you don't use the feature (e.g., no Bluetooth → disable Bluetooth services).
- **Maybe** → Depends on your setup (e.g., printing, gaming, backups, etc.).
- **No** → Critical for core system stability, security, or features you likely use.
- **Recommendation**: Set to **Manual** first if unsure — it's safer than **Disabled**.
- Always create a **System Restore Point** before making changes.
- Use `services.msc` (Win + R → services.msc) to manage them.
- Disabling non-essential services can reduce CPU/RAM usage, speed up boot times, and improve privacy.

### Services List

| # | Display Name | Service Name | Description | Default Startup | Safe to Disable? | Notes |
|---|--------------|--------------|-------------|------------------|------------------|-------|
| 1 | ActiveX Installer | AxInstSV | Validates and installs ActiveX controls from the internet | Manual | Yes | Rarely used today |
| 2 | AllJoyn Router Service | AJRouter | IoT device discovery and communication | Manual (Trigger) | Yes | Only if you have IoT devices |
| 3 | App Readiness | AppReadiness | Prepares apps for first use | Manual | No | Needed for app installation |
| 4 | Application Identity | AppIDSvc | Enforces AppLocker policies | Manual (Trigger) | No | Critical for security features |
| 5 | Application Information | Appinfo | Allows apps to run elevated | Manual (Trigger) | No | Core UAC functionality |
| 6 | Application Layer Gateway Service | ALG | Supports plugins for ICS (Internet Connection Sharing) | Manual | Yes | Only needed for old ICS setups |
| 7 | Application Management | AppMgmt | Processes Group Policy software installs | Manual | Yes | Mostly enterprise |
| 8 | AppX Deployment Service (AppXSVC) | AppXSvc | Deploys UWP/Store apps | Manual | No | Required for Microsoft Store |
| 9 | Auto Time Zone Updater | tzautoupdate | Automatically updates time zone | Disabled | Yes | Rarely needed |
| 10 | AVCTP service | BthAvctpSvc | Bluetooth audio/video control | Manual (Trigger) | Yes | If no Bluetooth audio |
| 11 | Background Intelligent Transfer Service | BITS | Background file transfers (Windows Update) | Automatic (Delayed) | Maybe | Keep for updates |
| 12 | Base Filtering Engine | BFE | Manages Windows Firewall & IPsec | Automatic | No | Critical for firewall |
| 13 | BitLocker Drive Encryption Service | BDESVC | BitLocker encryption support | Manual (Trigger) | Yes | If not using BitLocker |
| 14 | Bluetooth Audio Gateway Service | BTAGService | Bluetooth audio gateway | Manual (Trigger) | Yes | If no Bluetooth audio |
| 15 | Bluetooth Support Service | bthserv | Bluetooth device discovery & support | Manual (Trigger) | Yes | If no Bluetooth at all |
| 16 | Bluetooth User Support Service_* | BluetoothUserService_* | Per-user Bluetooth features | Manual (Trigger) | Yes | If no Bluetooth |
| 17 | BranchCache | PeerDistSvc | Local network content caching | Manual | Yes | Rarely used |
| 18 | Capability Access Manager Service | camsvc | Manages UWP app permissions | Manual | Yes | Minimal impact |
| 19 | CaptureService_* | CaptureService_* | Screen capture via Windows.Graphics.Capture | Manual | Yes | If not using capture features |
| 20 | Cellular Time | autotimesvc | Sets time from cellular network | Manual | Yes | If not using cellular |
| 21 | Client License Service (ClipSVC) | ClipSVC | Microsoft Store licensing | Manual (Trigger) | No | Needed for Store |
| 22 | Connected Devices Platform Service | CDPSvc | Connected devices & sync | Automatic (Delayed) | Yes | Privacy/performance gain |
| 23 | Connected User Experiences and Telemetry | DiagTrack | Telemetry & feedback | Automatic | Yes | Big privacy & perf gain |
| 24 | Credential Manager | VaultSvc | Stores credentials securely | Manual | No | Needed for saved passwords |
| 25 | Cryptographic Services | CryptSvc | Manages certificates & crypto | Automatic | No | Critical for security |
| 26 | Data Usage | DusmSvc | Tracks network data usage | Automatic | Yes | If not monitoring data caps |
| 27 | DCOM Server Process Launcher | DcomLaunch | Core COM/DCOM support | Automatic | No | Essential |
| 28 | Delivery Optimization | DoSvc | Peer-to-peer Windows Update | Automatic (Delayed) | Maybe | Keep if on metered connection |
| 29 | Device Association Service | DeviceAssociationService | Device pairing | Manual (Trigger) | Yes | If not pairing devices |
| 30 | Device Management Wireless Application Protocol (WAP) Push | dmwappushservice | Device management push | Manual | Yes | Rarely needed |
| 31 | Diagnostic Policy Service | DPS | Problem detection & troubleshooting | Automatic | No | Helpful for diagnostics |
| 32 | Distributed Link Tracking Client | TrkWks | Maintains file links across networks | Automatic | Yes | Minimal impact |
| 33 | Downloaded Maps Manager | MapsBroker | Downloaded offline maps | Automatic (Delayed) | Yes | If not using Maps app |
| 34 | Encrypting File System (EFS) | EFS | Encrypts files on NTFS | Manual (Trigger) | Yes | If not using EFS |
| 35 | File History Service | fhsvc | File History backup | Manual (Trigger) | Yes | If not using File History |
| 36 | Function Discovery Provider Host | fdPHost | Network discovery | Manual | Yes | If not discovering network devices |
| 37 | Function Discovery Resource Publication | FDResPub | Publishes computer on network | Manual | Yes | If not sharing files/printers |
| 38 | Geolocation Service | lfsvc | Location services | Manual (Trigger) | Yes | Privacy gain |
| 39 | Human Interface Device Service | hidserv | Hotkeys & special input devices | Manual (Trigger) | No | Needed for keyboards/mice |
| 40 | Hyper-V Services (various) | vmicsvc* | Hyper-V guest integration | Manual (Trigger) | Yes | If not using Hyper-V |
| 41 | Internet Connection Sharing (ICS) | SharedAccess | Shares internet connection | Manual (Trigger) | Yes | Rarely used |
| 42 | IP Helper | iphlpsvc | IPv6 transition | Automatic | Yes | If not using IPv6 |
| 43 | Link-Layer Topology Discovery Mapper | lltdsvc | Network map creation | Manual | Yes | If not using network map |
| 44 | Microsoft Account Sign-in Assistant | wlidsvc | Microsoft account login | Manual (Trigger) | Yes | If using local account |
| 45 | Microsoft Defender Antivirus Service | WinDefend | Real-time antivirus | Automatic | No | Keep for security |
| 46 | Net.Tcp Port Sharing Service | NetTcpPortSharing | Shares TCP ports | Disabled | Yes | Rarely used |
| 47 | Parental Controls | WpcMonSvc | Enforces parental controls | Manual | Yes | If no child accounts |
| 48 | Payments and NFC/SE Manager | SEMgrSvc | NFC payments | Manual | Yes | If no NFC |
| 49 | Phone Service | PhoneSvc | Phone integration | Manual | Yes | If no phone link |
| 50 | Print Spooler | Spooler | Printing support | Automatic | Yes | If no printer |
| 51 | Program Compatibility Assistant Service | PcaSvc | Compatibility assistant | Automatic | Yes | Minimal impact |
| 52 | Remote Desktop Services | TermService | Remote Desktop | Manual | Yes | If not using RDP |
| 53 | Remote Registry | RemoteRegistry | Remote registry access | Manual | Yes | Security risk if enabled |
| 54 | Secondary Logon | seclogon | Run as different user | Manual | Yes | Rarely needed |
| 55 | Sensor Monitoring Service | SensrSvc | Sensor monitoring | Manual | Yes | If no sensors |
| 56 | Server | LanmanServer | File & printer sharing | Automatic | Yes | If not sharing files/printers |
| 57 | Smart Card Services (various) | SCardSvr etc. | Smart card support | Manual | Yes | If no smart cards |
| 58 | SSDP Discovery | SSDPSRV | UPnP device discovery | Manual | Yes | If not using UPnP |
| 59 | SysMain (Superfetch/Prefetch) | SysMain | Preloads apps | Automatic | Yes | Mixed opinions; test it |
| 60 | Windows Search | WSearch | File indexing | Automatic | Yes | Big perf gain if disabled |
| 61 | Windows Update Delivery Optimization | DoSvc | Peer-to-peer updates | Automatic (Delayed) | Maybe | Keep for faster updates |
| 62 | Xbox Live Auth Manager | XblAuthManager | Xbox services | Manual | Yes | If not using Xbox |
| 63 | Xbox Live Game Save | XblGameSave | Xbox cloud saves | Manual | Yes | If not using Xbox |
| 64 | Xbox Live Networking Service | XboxNetApiSvc | Xbox networking | Manual | Yes | If not using Xbox |

### Final Tips
- For **maximum performance**: Disable telemetry (DiagTrack), Bluetooth (if unused), printing (if no printer), Xbox services (if no gaming), and Windows Search (if you use alternative search).
- For **privacy**: Disable DiagTrack, CDPSvc, and any telemetry-related services.
- Always test after changes — if something breaks, set the service back to **Automatic** or **Manual**.
- Use tools like **Chris Titus Tech's Winutil** or **ShutUp10++** for easier management.

This list is community-curated and based on Microsoft docs + expert recommendations (2025–2026). Your mileage may vary depending on your Windows 11 build and usage!