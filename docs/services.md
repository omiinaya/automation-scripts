Display Name,Service Name,Description,Default Startup,Safe to Disable
ActiveX Installer,AxInstSV,UAC validation to control the installation of Active-X controls via the internet.,Manual,Yes
Agent Activation Runtime_?????,AarSvc_?????,Chatbot Runtime for activating Conversational agent applications - Clippy returns.,Manual,No
AllJoyn Router Service,AJRouter,IoT integration.,Manual (Trigger Start),Yes
App Readiness,AppReadiness,Runs at first logon to prepare apps for use.,Manual,No
Application Identity,AppIDSvc,"Verify Application identity, used by AppLocker.",Manual (Trigger Start),No
Application Information,Appinfo,Facilitates running applications with additional administrative privileges. If disabled those additional privileges will not be available.,Manual (Trigger Start),No
Application Layer Gateway Service,ALG,Enables plugins for internet connection sharing. Primarily used for FTP sessions through network address translation (NAT).,Manual,Yes
Application Management,AppMgmt,"Required for Group Policy software management, Not Available in Win 10 home.",Manual,Yes
AppX Deployment Service (AppXSVC),AppXSvc,Windows Store integration. Cannot be disabled.,Manual,Yes
AssignedAccessManager Service,AssignedAccessManagerSvc,"Kiosk mode, Not Available in Win 10 home.",Manual,No
Auto Time Zone Updater,Tzautoupdate,Automatically set the Time Zone.,Disabled,Yes
AVCTP service,BthAvctpSvc,Audio Video Control TP service - Bluetooth / Wireless.,Manual (Trigger Start),Yes
Background Intelligent Transfer Service,BITS,Transfer files.,Manual or Automatic (Delayed Start),Yes
Background Tasks Infrastructure Service,BrokerInfrastructure,Cannot be disabled.,Automatic,No
Base Filtering Engine,BFE,Manage Windows Firewall and IPsec policies and implements user mode filtering. Do not disable.,Automatic,No
BitLocker Drive Encryption Service,BDESVC,Secure startup and volume encryption.,Manual (Trigger Start),No
Block Level Backup Engine Service,Wbengine,Used by Windows Backup.,Manual,Maybe - if not using backup
Bluetooth Audio Gateway Service,BTAGService,Bluetooth Audio - Wireless headsets.,Manual (Trigger Start),Yes - if not using Bluetooth audio
Bluetooth Support Service,Bthserv,Discovery of Bluetooth devices.,Manual (Trigger Start),Yes - if not using Bluetooth
Bluetooth User Support Service_?????,BluetoothUserService_?????,Bluetooth features.,Manual (Trigger Start),Yes - if not using Bluetooth
BranchCache,PeerDistSvc,Used by Windows Update for download sharing on the local subnet.,Manual,Yes
Capability Access Manager Service,Camsvc,Manage UWP apps.,Manual,Yes
CaptureService_?????,CaptureService_?????,Screen Capture Service via the Windows.Grapics.Capture API.,Manual,Yes
Cellular Time,Autotimesvc,Set the time based on NITZ messages from a mobile network.,Manual,Yes
Certificate Propagation,CertPropSvc,,Manual (Trigger Start),No
Client License Service (ClipSVC),ClipSVC,"Support for Microsoft store, cannot be disabled.",Manual (Trigger Start),Yes
Clipboard User Service_?????,Cbdhsvc_?????,Clipboard.,Manual,Yes
CNG Key Isolation,KeyIso,Secure long lived keys for cryptographic operations.,Manual (Trigger Start),No
COM+ Event System,EventSystem,"COM Event notification service, required for COM+",Manual,No
COM+ System Application,COMSysApp,Network discovery of systems on local network.,Manual (Trigger Start),No
Connected Devices Platform Service,CDPSvc,Connected Devices Platform.,"Automatic (Delayed Start, Trigger Start)",Yes
Connected Devices Platform User Service_?????,CDPUserSvc_?????,Connected Devices Platform.,Automatic,Yes
Connected User Experiences and Telemetry,DiagTrack,Feedback and Diagnostics.,Automatic,Yes - for privacy/performance
ConsentUX_?????,ConsentUxUserSvc_?????,"Connect and pair Wi-Fi and Bluetooth devices, ConnectUX.",Manual,Yes
Contact Data_?????,PimIndexMaintenanceSvc_?????,Indexes contact data for fast contact searching.,Manual,Yes
CoreMessaging,CoreMessagingRegistrar,Cannot be disabled. Manages communication between system components.,Automatic,No
Credential Manager,VaultSvc,Secure storage and retrieval of credentials. Control Panel: Credential Manager.,Manual,No
CredentialEnrollmentManagerUserSvc_?????,CredentialEnrollmentManagerUserSvc_?????,Credential Enrolment Manager.,Manual,No
Cryptographic Services,CryptSvc,Manage root certificates.,Automatic,No
Data Sharing Service,DsSvc,Data brokering between applications.,Manual (Trigger Start),No
Data Usage,DusmSvc,"Network data usage,data limit/metered networks.",Automatic,No
DCOM Server Process Launcher,DcomLaunch,Required for COM and DCOM object activation requests.,Automatic,No
Delivery Optimization,DoSvc,Content delivery Optimisation.,Automatic (Delayed Start),No
Device Association Service,DeviceAssociationService,Pairing between the system and wired or wireless devices.,Manual (Trigger Start),Yes
Device Install Service,DeviceInstall,"Recognise new hardware, do not disable.",Manual (Trigger Start),No
Device Management Enrollment Service,DmEnrollmentSvc,Device enrolment/management.,Manual,Maybe
Device Management Wireless Application Protocol (WAP) Push message Routing Service,Dmwappushservice,WAP - Sync device sessions.,Manual,Maybe
Device Setup Manager,DsmSvc,Install device drivers.,Manual (Trigger Start),No
DeviceAssociationBroker_?????,DeviceAssociationBrokerSvc_?????,Pair devices.,Manual,Maybe
DevicePicker_?????,DevicePickerUserSvc_?????,Manage Miracast DLNA and DIAL UI.,Manual,Yes
DevicesFlow_?????,DevicesFlowUserSvc_?????,"Connect and pair Wi-Fi and Bluetooth devices, ConnectUX/PC settings.",Manual,Yes
DevQuery Background Discovery Broker,DevQueryBroker,Enable apps to discover devices with a background task.,Manual (Trigger Start),No
DHCP Client,Dhcp,Allocate an IP address to this computer automatically.,Automatic,No
Diagnostic Execution Service,Diagsvc,Enable troubleshooting support.,Manual (Trigger Start),No
Diagnostic Policy Service,DPS,"Enable problem detection, troubleshooting and resolution for Windows components.",Automatic,No
Diagnostic Service Host,WdiServiceHost,Diagnostics for Local Services.,Manual,No
Diagnostic System Host,WdiSystemHost,Diagnostics for the Local System.,Manual,No
DialogBlockingService,DialogBlockingService,DialogBlockingService,Disabled,Yes
Display Enhancement Service,DisplayEnhancementService,Brightness.,Manual (Trigger Start),No
Display Policy Service,DispBrokerDesktopSvc,Connection and configuration of local and remote displays.,Automatic (Delayed Start),No
Distributed Link Tracking Client,TrkWks,Attempt to maintain valid links between NTFS files across a network.,Automatic,Yes
Distributed Transaction Coordinator,MSDTC,"Co-ordinate transactions between resource managers, database, file and message queues.",Manual,Yes
DNS Client,Dnscache,Cache DNS queries and register the computername.,Automatic (Trigger Start),No
Downloaded Maps Manager,MapsBroker,Windows/Bing maps.,Automatic (Delayed Start),Yes
Embedded Mode,Embeddedmode,Activate background applications.,Manual (Trigger Start),No
Encrypting File System (EFS),EFS,Allow storage of encrypted files on NTFS file systems.,Manual (Trigger Start),No
Enterprise App Management Service,EntAppSvc,Cannot be disabled. Enterprise Application management.,Manual,Yes
Extensible Authentication Protocol,Eaphost,Network Authentication - VPN NAP and Wireless.,Manual,Yes
File History Service,Fhsvc,Used by Windows Backup.,Manual (Trigger Start),No
FileSyncHelper,FileSyncHelper,One Drive (if installed),Manual,Depends - if using OneDrive
Function Discovery Provider Host,FdPHost,Network discovery and Web Service discovery.,Manual,Yes
Function Discovery Resource Publication,FDResPub,Publish this computer and resources over the network.,Manual,Yes
GameInput Service,GameInputsvc,,,Yes - if not gaming with controllers
Geolocation Service,Lfsvc,Manage Geofences - a geographic location with associated events.,Manual (Trigger Start),Yes
GraphicsPerfSvc,GraphicsPerfSvc,Monitor graphics performance.,Manual (Trigger Start),No
Group Policy Client,Gpsvc,Cannot be disabled. Apply admin settings through group policy.,Automatic (Trigger Start),No
Human Interface Device Service,Hidserv,Activate and maintain hot buttons on keyboards and other controls.,Manual (Trigger Start),No
HV Host Service,HvHost,Hyper-V interface for performance counters.,Manual (Trigger Start),Yes - if not using Hyper-V
Hyper-V Data Exchange Service,Vmickvpexchange,Hyper-V interface for data exchange.,Manual (Trigger Start),Yes - if not using Hyper-V
Hyper-V Guest Service Interface,Vmicguestinterface,Hyper-V interface for VM services.,Manual (Trigger Start),Yes - if not using Hyper-V
Hyper-V Guest Shutdown Service,Vmicshutdown,Hyper-V interface for VM shutdown.,Manual (Trigger Start),Yes - if not using Hyper-V
Hyper-V Heartbeat Service,Vmicheartbeat,Hyper-V identify frozen VMs.,Manual (Trigger Start),Yes - if not using Hyper-V
Hyper-V PowerShell Direct Service,Vmicvmsession,Hyper-V interface for PowerShell.,Manual (Trigger Start),Yes - if not using Hyper-V
Hyper-V Remote Desktop Virtualization Service,Vmicrdv,Hyper-V desktop interface. Not Available in Win 10 home.,Manual (Trigger Start),Yes - if not using Hyper-V
Hyper-V Time Synchronization Service,Vmictimesync,Hyper-V time sync.,Manual (Trigger Start),Yes - if not using Hyper-V
Hyper-V Volume Shadow Copy Requestor,Vmicvss,Hyper-V shadow copy/backup.,Manual (Trigger Start),Yes - if not using Hyper-V
IKE and AuthIP IPsec Keying Modules,IKEEXT,Internet Key exchange.,Manual (Trigger Start),No
Internet Connection Sharing (ICS),SharedAccess,Provides NAT/name resolution for small office networks. Very rarely needed.,Manual (Trigger Start),Yes
IP Helper,Iphlpsvc,IPv6 translation.,Automatic,Yes
IP Translation Configuration Service,IpxlatCfgSvc,IPv6 translation.,Manual (Trigger Start),Yes
IPsec Policy Agent,PolicyAgent,Network level peer authentication. Enforces IPsec policies.,Manual (Trigger Start),No
KtmRm for Distributed Transaction Coordinator,KtmRm,Co-ordinates distributed transactions. MSDTC/KTM.,Manual (Trigger Start),No
Language Experience Service,LxpSvc,Deployment infrastructure for configuring additional languages.,Manual,No
Link-Layer Topology Discovery Mapper,Lltdsvc,Creates a Network map describing each PC and device.,Manual,Yes
Local Profile Assistant Service,Wlpasvc,Profile management for local subscriber identity modules.,Manual (Trigger Start),Yes
Local Session Manager,LSM,Cannot be disabled. Manage local user sessions.,Automatic,No
MCPManagementService,MCPManagementService,,,Maybe
MessagingService_?????,MessagingService_?????,Text Messaging.,,Yes
Microsoft (R) Diagnostics Hub Standard Collector Service,Diagnosticshub.standardcollector.service,Collect real-time Event Tracing for Windows (ETW) events.,Manual,No
Microsoft Account Sign-in Assistant,Wlidsvc,Running if using MS account to log in to computer.,Manual (Trigger Start),Yes - if not using MS account
Microsoft App-V Client,AppVClient,Manage App-V users and virtual applications. Not Available in Win 10 home.,Disabled,Yes
Microsoft Cloud Identity Service,Cloudidsvc,,Manual,Maybe
Microsoft Defender Antivirus Network Inspection Service,WdNisSvc,,Manual,No
Microsoft Defender Antivirus Service,WinDefend,,Manual,No
Microsoft Defender Core Service,MDCoreSvc,,Automatic,No
Microsoft iSCSI Initiator Service,MSiSCSI,Manage iSCSI devices.,Manual,Yes
Microsoft Keyboard Filter,MsKeyboardFilter,Control keystroke filtering and mapping.,Not Installed (Disabled),Maybe
Microsoft Passport,NgcSvc,Process isolation for cryptographic keys. Cannot be disabled.,Manual (Trigger Start),Yes
Microsoft Passport Container,NgcCtnrSvc,Manage Local user identity keys and smartcard access. Cannot be disabled.,Manual (Trigger Start),Yes
Microsoft Policy Platform Local Authority,Lpasvc,,Manual,Maybe
Microsoft Policy Platform Processor,Lppsvc,,Manual,Maybe
Microsoft Search in Bing,MicrosoftSearchinBing,Workplace search,Automatic,Maybe
Microsoft Software Shadow Copy Provider,Swprv,Volume Shadow Copy. Used by Windows Backup.,"Manual (Runs at boot, then stops)",Yes
Microsoft Storage Spaces SMP,Smphost,Manage storage pools with multiple disks (WSS).,Manual,Yes
Microsoft Store Install Service,InstallService,Microsoft Store.,Manual,Yes
Microsoft Windows SMS Router Service.,SmsRouter,Route messages.,,Yes
Natural Authentication,NaturalAuthentication,Signal aggregator service for automatic device lock/unlock.,Manual (Trigger Start),Yes
Net.Tcp Port Sharing Service,NetTcpPortSharing,Provides ability to share TCP ports over net.tcp,Disabled,Yes
Netlogon,Netlogon,Connect to a domain controller.,,Yes
Network Connected Devices Auto-Setup,NcdAutoSetup,Discover and install qualified devices.,Manual (Trigger Start),Yes
Network Connection Broker,NcbService,Broker connections between Windows store apps and the internet.,Manual (Trigger Start),Yes
Network Connections,Netman,Manage network and Dial-up connections.,Manual,No
Network Connectivity Assistant,NcaSvc,DirectAccess status notification.,Manual (Trigger Start),Yes
Network List Service,Netprofm,Identify networks.,Manual,Maybe
Network Location Awareness,NlaSvc,Notify changes in the network configuration.,Automatic,Yes
Network Setup Service,NetSetupSvc,Manage installation and configuration of network drivers.,Manual (Trigger Start),No
Network Store Interface Service,Nsi,Network notifications for user mode clients.,Automatic (Running),Maybe
NPSMSvc_??????,NPSMSvc_??????,Now Playing session manager,Manual,Maybe
Offline Files,CscService,Perform offline maintenance on the offline files cache. Not Available in Win 10 home.,Manual (Trigger Start),Yes
OneDrive Updater Service,OneDrive Updater Service,,Manual,Depends
OpenSSH Authentication Agent,Ssh-agent,Agent to hold private keys used for public key authentication.,Disabled,Yes
Optimize drives,Defragsvc,Helps the computer run more efficiently by optimizing files on storage drives.,Manual,Yes
Parental Controls,WpcMonSvc,"Enforces parental controls for child accounts in Windows. If this service is stopped or disabled, parental controls aren't enforced.",Manual,Yes
Payments and NFC/SE Manager,SEMgrSvc,Manages payments and Near Field Communication (NFC) based secure elements.,Manual,Yes
Peer Name Resolution Protocol,PNRPsvc,,Manual,Yes
Peer Networking Grouping,P2psvc,,Manual,Yes
Peer Networking Identity Manager,P2pimsvc,,Manual,Yes
Performance Counter DLL Host,PerfHost,"Enables remote users and 64-bit processes to query performance counters provided by 32-bit DLLs. If this service is stopped, only local users and 32-bit processes are able to query performance counters provided by 32-bit DLLs.",Manual,No
Performance Logs & Alerts,Pla,"Performance Logs and Alerts Collects performance data from local or remote computers based on preconfigured schedule parameters, then writes the data to a log or triggers an alert. If this service is stopped, performance information isn't collected. If this service is disabled, any services that explicitly depend on it fails to start.",Manual,No
Phone Service,PhoneSvc,Manages the telephony state on the device.,Manual,Yes
Plug and Play,PlugPlay,Enables a computer to recognize and adapt to hardware changes with little or no user input. Stopping or disabling this service results in system instability.,Manual,Maybe
PNRP Machine Name Publication Service,PNRPAutoReg,,Manual,Yes
Portable Device Enumerator Service,WPDBusEnum,Enforces group policy for removable mass-storage devices. Enables applications such as Windows Media Player and Image Import Wizard to transfer and synchronize content using removable mass-storage devices.,Manual,Yes
Power,Power,Manages power policy and power policy notification delivery.,Automatic,No
Print Spooler,Spooler,"This service spools print jobs and handles interaction with the printer. If you turn off this service, you aren't able to print or see your printers.",Automatic,Yes - if not printing
Printer Extensions and Notifications,PrintNotify,This service opens custom printer dialog boxes and handles notifications from a remote print server or a printer. Reconfiguring PrintNotivy prevents use of printer extensions and prevents notifications.,Manual,Yes - if not printing
Problem Reports and Solutions Control Panel Support,Wercplsupport,"This service provides support for viewing, sending and deletion of system-level problem reports for the Problem Reports and Solutions control panel.",Manual,Maybe
Program Compatibility Assistant Service,PcaSvc,"This service provides support for the Program Compatibility Assistant (PCA). PCA monitors programs installed and run by the user and detects known compatibility problems. If this service is stopped, PCA doesn't function properly.",Automatic,Yes
Quality Windows Audio Video Experience,QWAVE,"Quality Windows Audio Video Experience (qWave) is a networking platform for Audio Video (AV) streaming applications on IP home networks. qWave enhances AV streaming performance and reliability by ensuring network quality-of-service (QoS) for AV applications. It provides mechanisms for admission control, run time monitoring and enforcement, application feedback, and traffic prioritization.",Manual,Yes
Radio Management Service,RmSvc,Radio Management and Airplane Mode Service.,Manual,Yes
Recommended Troubleshooting Service,TroubleshootingSvc,Enables automatic mitigation for known problems by applying recommended troubleshooting. Disabling TroubleshootingSvc prevents recommended troubleshooting for problems on your device.,Manual,Maybe
Remote Access Auto Connection Manager,RasAuto,Creates a connection to a remote network whenever a program references a remote DNS or NetBIOS name or address.,Manual,Yes
Remote Access Connection Manager,RasMan,"Manages dial-up and virtual private network (VPN) connections from this computer to the Internet or other remote networks. If this service is disabled, any services that explicitly depend on it fails to start.",Manual,Yes
Remote Desktop Configuration,SessionEnv,"Remote Desktop Configuration service (RDCS) is responsible for all Remote Desktop Services and Remote Desktop related configuration and session maintenance activities that require SYSTEM context. These include per-session temporary folders, RD themes, and RD certificates.",Manual,No
Remote Desktop Services,TermService,"Allows users to connect interactively to a remote computer. Remote Desktop and Remote Desktop Session Host Server depend on this service. To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System properties control panel item.",Manual,No
Remote Desktop Services UserMode Port Redirector,UmRdpService,Allows the redirection of Printers/Drives/Ports for RDP connections.,Manual,No
Remote Procedure Call,RpcSs,"The RPCSS service is the Service Control Manager for COM and DCOM servers. It performs object activations requests, object exporter resolutions and distributed garbage collection for COM and DCOM servers. If the service is stopped or disabled, programs using COM or DCOM don't function properly. Disabling RpcSs service isn't recommended.",Automatic,No
Remote Procedure Call Locator,RpcLocator,"In Windows 2003 and earlier versions of Windows, the Remote Procedure Call (RPC) Locator service manages the RPC name service database. In Windows Vista and later versions of Windows, this service doesn't provide any functionality and is present for application compatibility.",Manual,Yes
Remote Registry,RemoteRegistry,Enables remote users to modify registry settings on this computer. Disabling RemoteRegistry service restricts registry updating to local users only and isn't recommended.,Automatic,No - but often disabled for security
Retail Demo Service,RetailDemo,The Retail Demo service controls device activity while the device is in retail demo mode.,Automatic,Yes
Routing and Remote Access,RemoteAccess,Offers routing services to businesses in local area and wide area network environments.,Disabled,Yes
RPC Endpoint Mapper,RpcEptMapper,"Resolves RPC interfaces identifiers to transport endpoints. If this service is stopped or disabled, programs using Remote Procedure Call (RPC) services doesn't function properly.",Automatic,No
Secondary Logon,Seclogon,"Enables starting processes under alternate credentials. If this service is stopped, this type of logon access us unavailable. If this service is disabled, any services that explicitly depend on it fails to start.",Manual,No
Secure Socket Tunneling Protocol Service,SstpSvc,"Provides support for the Secure Socket Tunneling Protocol (SSTP) to connect to remote computers using VPN. If this service is disabled, users aren't able to use SSTP to access remote servers.",Manual,Yes
Security Accounts Manager,SamSs,"The startup of this service signals other services that the Security Accounts Manager (SAM) is ready to accept requests. Disabling this service prevents other services in the system from being notified when the SAM is ready, which causes those services to fail to start correctly. This service shouldn't be disabled.",Automatic,No
Security Center,Wscsvc,"The WSCSVC (Windows Security Center) service monitors and reports security health settings on the computer. The health settings include firewall (on/off), antivirus (on/off/out of date), antispyware (on/off/out of date), Windows Update (automatically/manually download and install updates), User Account Control (on/off), and Internet settings (recommended/not recommended). The service provides COM APIs for independent software vendors to register and record the state of their products to the Security Center service. The Security and Maintenance UI uses the service to provide systray alerts and a graphical view of the security health states in the Security and Maintenance control panel. Network Access Protection (NAP) uses the service to report the security health states of clients to the NAP Network Policy Server to make network quarantine decisions. The service also has a public API that allows external consumers to programmatically retrieve the aggregated security health state of the system.",Manual,No
Sensor Data Service,SensorDataService,Delivers data from various sensors.,Manual,Yes
Sensor Monitoring Service,SensrSvc,Monitors various sensors in order to expose data and adapt to system and user state. Reconfiguring Sensor Monitoring Service prevents dynamic response to changes in lighting conditions. Stopping this service might affect other system functionality and features as well.,Manual,Yes
Sensor Service,SensorService,"A service for sensors that manages the functionality of different sensors. Manages Simple Device Orientation (SDO) and History for sensors. Loads the SDO sensor that reports device orientation changes. If this service is stopped or disabled, the SDO sensor doesn't load and autorotation doesn't occur. History collection from Sensors stop.",Manual,Yes
Server,LanmanServer,"Supports file, print, and named-pipe sharing over the network for this computer. If this service is stopped, these functions are unavailable. If this service is disabled, any services that explicitly depend on it fails to start.",Automatic,Yes - if not sharing files
Shared PC Account Manager,Shpamsvc,Manages profiles and accounts on a SharedPC configured device.,Automatic,Yes
Shell Hardware Detection,ShellHWDetection,Provides notifications for Auto-Play hardware events.,Automatic,Yes
Smart Card,SCardSvr,"Manages access to smart cards read by this computer. If this service is stopped, this computer is unable to read smart cards. If this service is disabled, any services that explicitly depend on it fails to start.",Manual,Yes
Smart Card Device Enumeration Service,ScDeviceEnum,"Creates software device nodes for all smart card readers accessible to a given session. If this service is disabled, WinRT APIs aren't able to enumerate smart card readers. Needed almost exclusively for WinRT apps.",Manual,Yes
Smart Card Removal Policy,SCPolicySvc,Allows the system to be configured to lock the user desktop upon smart card removal.,Manual,Yes
SNMP Trap,SNMPTRAP,"Receives trap messages generated by local or remote Simple Network Management Protocol (SNMP) agents and forwards the messages to SNMP management programs running on this computer. If this service is stopped, SNMP-based programs on this computer don't receive SNMP trap messages. If this service is disabled, any services that explicitly depend on it fails to start.",Manual,Yes
Software Protection,Sppsvc,"Enables the download, installation and enforcement of digital licenses for Windows and Windows applications. If the service is disabled, the operating system and licensed applications run in a notification mode. Disabling Software Protection isn't recommended.",Automatic,No
Spatial Data Service,SharedRealitySvc,This service is used for Spatial Perception scenarios.,Manual,No
Spot Verifier,Svsvc,Verifies potential file system corruptions.,Manual,No
SSDP Discovery,SSDPSRV,"Discovers networked devices and services that use the SSDP discovery protocol, such as UPnP devices. Also announces SSDP devices and services running on the local computer. If this service is stopped, SSDP-based devices aren't discovered. If this service is disabled, any services that explicitly depend on it fails to start.",Manual,Yes