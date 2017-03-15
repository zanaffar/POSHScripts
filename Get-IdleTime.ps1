## Queries a machine to see how long the currently logged on user has been idle. The script uses the PInvoke.Win32 Class LASTINPUTINFO 
## which queries the time since a mouse or keyboard has been touched. This script returns the result for the currently logged on user 
## by impersonating them via a Scheduled task run as SYSTEM, and running the query in the logged-on user's context. The script creates 
## 2 temporary directories, C:\ToolkitTemp and C:\TempLogs to place some files inside. It deletes these directories after the script finishes.

## Usage ##

## Get-IdleTime -ComputerName '123XYZ','ABC123' -Credential 'domain\username' -DisableLogging -WriteHost $false

## -ComputerName can do multiple machines, and it can take pipeline input.
## You don't need to specify -Credential if the account you're running under has access to the remote machines
## Probably best to keep the -DisableLogging switch and -WriteHost $false. The code I stole most of this from has very verbose logging on by default.

function Get-IdleTime {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('Computer')]
		[String[]]$ComputerName = "$env:COMPUTERNAME",
		[Parameter(Mandatory = $false)]
		[PSCredential]$Credential,
		[Parameter(Mandatory = $false)]
		[switch]$DisableLogging = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[boolean]$WriteHost = $true
	)

	begin { }

	process {

        function Get-User { 
        #Requires -Version 2.0             
        [CmdletBinding()]             
         Param              
           (                        
            [Parameter(Mandatory=$false, 
                       Position=0,                           
                       ValueFromPipeline=$true,             
                       ValueFromPipelineByPropertyName=$true)]             
            [String[]]$ComputerName = $env:COMPUTERNAME 
           )#End Param 
 
        Begin             
        {             
         Write-Host "`n Checking Users . . . " 
         $i = 0 
         $MyParams = @{ 
             Class       = "Win32_process"  
             Filter      = "Name='Explorer.exe'"  
             ErrorAction = "Stop" 
            } 
        }#Begin           
        Process             
        { 
            $ComputerName | Foreach-object { 
            $Computer = $_ 
     
            $MyParams["ComputerName"] = $Computer 
            try 
                { 
                    $processinfo = @(Get-WmiObject @MyParams) 
                    if ($Processinfo) 
                        {     
                            $Processinfo | ForEach-Object {  
                                New-Object PSObject -Property @{ 
                                    ComputerName=$Computer 
                                    LoggedOn    =$_.GetOwner().User 
                                    SID         =$_.GetOwnerSid().sid} } |  
                            Select-Object ComputerName,LoggedOn,SID 
                        }#If 
                } 
            catch 
                { 
                    "Cannot find any processes running on $computer" | Out-Host 
                } 
             }#Forech-object(ComputerName)        
             
        }#Process 
        End 
        { 
 
        }#End 
 
        }#Get-LoggedOnUsers 
		
		$ScriptBlock = {

            $DisableLogging = $args[0]
            $WriteHostParam = $args[1]

			[string[]]$ReferencedAssemblies = 'System.Drawing', 'System.Windows.Forms', 'System.DirectoryServices'
			[string]$appDeployToolkitName = 'LastInput'
			[string]$dirAppDeployTemp = 'C:\ToolkitTemp'
			
            #Write-Output "DisableLogging = $DisableLogging"
            #Write-Output "WriteHostParam = $WriteHostParam"

			Add-Type @'
using System;
using System.Text;
using System.Collections;
using System.ComponentModel;
using System.DirectoryServices;
using System.Security.Principal;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using FILETIME = System.Runtime.InteropServices.ComTypes.FILETIME;

namespace PSADT
{
	public class Msi
	{
		enum LoadLibraryFlags : int
		{
			DONT_RESOLVE_DLL_REFERENCES 		= 0x00000001,
			LOAD_IGNORE_CODE_AUTHZ_LEVEL		= 0x00000010,
			LOAD_LIBRARY_AS_DATAFILE    		= 0x00000002,
			LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE	= 0x00000040,
			LOAD_LIBRARY_AS_IMAGE_RESOURCE  	= 0x00000020,
			LOAD_WITH_ALTERED_SEARCH_PATH 		= 0x00000008
		}
		
		[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		static extern IntPtr LoadLibraryEx(string lpFileName, IntPtr hFile, LoadLibraryFlags dwFlags);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		static extern int LoadString(IntPtr hInstance, int uID, StringBuilder lpBuffer, int nBufferMax);
		
		// Get MSI exit code message from msimsg.dll resource dll
		public static string GetMessageFromMsiExitCode(int errCode)
		{
			IntPtr hModuleInstance = LoadLibraryEx("msimsg.dll", IntPtr.Zero, LoadLibraryFlags.LOAD_LIBRARY_AS_DATAFILE);
			
			StringBuilder sb = new StringBuilder(255);
			LoadString(hModuleInstance, errCode, sb, sb.Capacity + 1);
			
			return sb.ToString();
		}
	}
	
	public class Explorer
	{
		private static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);
		private const int WM_SETTINGCHANGE = 0x1a;
		private const int SMTO_ABORTIFHUNG = 0x0002;
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		static extern bool SendNotifyMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		private static extern IntPtr SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam, int fuFlags, int uTimeout, IntPtr lpdwResult);
		
		[DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		private static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
		
		public static void RefreshDesktopAndEnvironmentVariables()
		{
			// Update desktop icons
			SHChangeNotify(0x8000000, 0x1000, IntPtr.Zero, IntPtr.Zero);
			// Update environment variables
			SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, IntPtr.Zero, null, SMTO_ABORTIFHUNG, 100, IntPtr.Zero);
		}
	}
	
	public sealed class FileVerb
	{
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern int LoadString(IntPtr h, int id, StringBuilder sb, int maxBuffer);
		
		[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern IntPtr LoadLibrary(string s);
		
		public static string GetPinVerb(int VerbId)
		{
			IntPtr hShell32 = LoadLibrary("shell32.dll");
			const int nChars  = 255;
			StringBuilder Buff = new StringBuilder("", nChars);
						
			LoadString(hShell32, VerbId, Buff, Buff.Capacity);
			return Buff.ToString();
		}
	}
	
	public sealed class IniFile
	{
		[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern int GetPrivateProfileString(string lpAppName, string lpKeyName, string lpDefault, StringBuilder lpReturnedString, int nSize, string lpFileName);
		
		[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool WritePrivateProfileString(string lpAppName, string lpKeyName, StringBuilder lpString, string lpFileName);
		
		public static string GetIniValue(string section, string key, string filepath)
		{
			string sDefault	= "";
			const int  nChars  = 1024;
			StringBuilder Buff = new StringBuilder(nChars);
					
			GetPrivateProfileString(section, key, sDefault, Buff, Buff.Capacity, filepath);
			return Buff.ToString();
		}
		
		public static void SetIniValue(string section, string key, StringBuilder value, string filepath)
		{
			WritePrivateProfileString(section, key, value, filepath);
		}
	}
	
	public class UiAutomation
	{
		public enum GetWindow_Cmd : int
		{
			GW_HWNDFIRST    = 0,
			GW_HWNDLAST     = 1,
			GW_HWNDNEXT     = 2,
			GW_HWNDPREV     = 3,
			GW_OWNER        = 4,
			GW_CHILD        = 5,
			GW_ENABLEDPOPUP = 6
		}
		
		public enum ShowWindowEnum
		{
			Hide                    = 0,
			ShowNormal              = 1,
			ShowMinimized           = 2,
			ShowMaximized           = 3,
			Maximize                = 3,
			ShowNormalNoActivate    = 4,
			Show                    = 5,
			Minimize                = 6,
			ShowMinNoActivate       = 7,
			ShowNoActivate          = 8,
			Restore                 = 9,
			ShowDefault             = 10,
			ForceMinimized          = 11
		}
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool EnumWindows(EnumWindowsProcD lpEnumFunc, ref IntPtr lParam);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern int GetWindowTextLength(IntPtr hWnd);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool IsWindowEnabled(IntPtr hWnd);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern bool IsWindowVisible(IntPtr hWnd);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool IsIconic(IntPtr hWnd);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool ShowWindow(IntPtr hWnd, ShowWindowEnum flags);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern IntPtr SetActiveWindow(IntPtr hwnd);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool SetForegroundWindow(IntPtr hWnd);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern IntPtr GetForegroundWindow();
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern IntPtr SetFocus(IntPtr hWnd);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern bool BringWindowToTop(IntPtr hWnd);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);
		
		[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern int GetCurrentThreadId();
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern bool AttachThreadInput(int idAttach, int idAttachTo, bool fAttach);
		
		[DllImport("user32.dll", EntryPoint = "GetWindowLong", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern IntPtr GetWindowLong32(IntPtr hWnd, int nIndex);
		
		[DllImport("user32.dll", EntryPoint = "GetWindowLongPtr", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern IntPtr GetWindowLongPtr64(IntPtr hWnd, int nIndex);
		
		public delegate bool EnumWindowsProcD(IntPtr hWnd, ref IntPtr lItems);
		
		public static bool EnumWindowsProc(IntPtr hWnd, ref IntPtr lItems)
		{
			if (hWnd != IntPtr.Zero)
			{
				GCHandle hItems = GCHandle.FromIntPtr(lItems);
				List<IntPtr> items = hItems.Target as List<IntPtr>;
				items.Add(hWnd);
				return true;
			}
			else
			{
				return false;
			}
		}
		
		public static List<IntPtr> EnumWindows()
		{
			try
			{
				List<IntPtr> items = new List<IntPtr>();
				EnumWindowsProcD CallBackPtr = new EnumWindowsProcD(EnumWindowsProc);
				GCHandle hItems = GCHandle.Alloc(items);
				IntPtr lItems = GCHandle.ToIntPtr(hItems);
				EnumWindows(CallBackPtr, ref lItems);
				return items;
			}
			catch (Exception ex)
			{
				throw new Exception("An error occured during window enumeration: " + ex.Message);
			}
		}
		
		public static string GetWindowText(IntPtr hWnd)
		{
			int iTextLength = GetWindowTextLength(hWnd);
			if (iTextLength > 0)
			{
				StringBuilder sb = new StringBuilder(iTextLength);
				GetWindowText(hWnd, sb, iTextLength + 1);
				return sb.ToString();
			}
			else
			{
				return String.Empty;
			}
		}
		
		public static bool BringWindowToFront(IntPtr windowHandle)
		{
			bool breturn = false;
			if (IsIconic(windowHandle))
			{
				// Show minimized window because SetForegroundWindow does not work for minimized windows
				ShowWindow(windowHandle, ShowWindowEnum.ShowMaximized);
			}
			
			int lpdwProcessId;
			int windowThreadProcessId = GetWindowThreadProcessId(GetForegroundWindow(), out lpdwProcessId);
			int currentThreadId = GetCurrentThreadId();
			AttachThreadInput(windowThreadProcessId, currentThreadId, true);
			
			BringWindowToTop(windowHandle);
			breturn = SetForegroundWindow(windowHandle);
			SetActiveWindow(windowHandle);
			SetFocus(windowHandle);
			
			AttachThreadInput(windowThreadProcessId, currentThreadId, false);
			return breturn;
		}
		
		public static int GetWindowThreadProcessId(IntPtr windowHandle)
		{
			int processID = 0;
			GetWindowThreadProcessId(windowHandle, out processID);
			return processID;
		}
		
		public static IntPtr GetWindowLong(IntPtr hWnd, int nIndex)
		{
			if (IntPtr.Size == 4)
			{
				return GetWindowLong32(hWnd, nIndex);
			}
			return GetWindowLongPtr64(hWnd, nIndex);
		}
	}
	
	public class Screen
	{
		[StructLayout(LayoutKind.Sequential)]
		public struct RECT
		{
			public int Left;
			public int Top;
			public int Right;
			public int Bottom;
		}
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		private static extern IntPtr GetForegroundWindow();
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		private static extern IntPtr GetDesktopWindow();
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		private static extern IntPtr GetShellWindow();
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		private static extern int GetWindowRect(IntPtr hWnd, out RECT rc);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
		
		private static IntPtr desktopHandle;
		private static IntPtr shellHandle;
		
		public static bool IsFullScreenWindow(string fullScreenWindowTitle)
		{
			desktopHandle = GetDesktopWindow();
			shellHandle = GetShellWindow();
			
			bool runningFullScreen = false;
			RECT appBounds;
			System.Drawing.Rectangle screenBounds;
			const int nChars = 256;
			StringBuilder Buff = new StringBuilder(nChars);
			string mainWindowTitle = "";
			IntPtr hWnd;
			hWnd = GetForegroundWindow();
			
			if (hWnd != null && !hWnd.Equals(IntPtr.Zero))
			{
				if (!(hWnd.Equals(desktopHandle) || hWnd.Equals(shellHandle)))
				{
					if (GetWindowText(hWnd, Buff, nChars) > 0)
					{
						mainWindowTitle = Buff.ToString();
						//Console.WriteLine(mainWindowTitle);
					}
					
					// If the main window title contains the text being searched for, then check to see if the window is in fullscreen mode.
					Match match = Regex.Match(mainWindowTitle, fullScreenWindowTitle, RegexOptions.IgnoreCase);
					if ((!string.IsNullOrEmpty(fullScreenWindowTitle)) && match.Success)
					{
						GetWindowRect(hWnd, out appBounds);
						screenBounds = System.Windows.Forms.Screen.FromHandle(hWnd).Bounds;
						if ((appBounds.Bottom + appBounds.Top) == screenBounds.Height && (appBounds.Right + appBounds.Left) == screenBounds.Width)
						{
							runningFullScreen = true;
						}
					}
				}
			}
			return runningFullScreen;
		}
	}
	
	public class QueryUser
	{
		[DllImport("wtsapi32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern IntPtr WTSOpenServer(string pServerName);
		
		[DllImport("wtsapi32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern void WTSCloseServer(IntPtr hServer);
		
		[DllImport("wtsapi32.dll", CharSet = CharSet.Ansi, SetLastError = false)]
		public static extern bool WTSQuerySessionInformation(IntPtr hServer, int sessionId, WTS_INFO_CLASS wtsInfoClass, out IntPtr pBuffer, out int pBytesReturned);
		
		[DllImport("wtsapi32.dll", CharSet = CharSet.Ansi, SetLastError = false)]
		public static extern int WTSEnumerateSessions(IntPtr hServer, int Reserved, int Version, out IntPtr pSessionInfo, out int pCount);
		
		[DllImport("wtsapi32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern void WTSFreeMemory(IntPtr pMemory);
		
		[DllImport("winsta.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern int WinStationQueryInformation(IntPtr hServer, int sessionId, int information, ref WINSTATIONINFORMATIONW pBuffer, int bufferLength, ref int returnedLength);
		
		[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern int GetCurrentProcessId();
		
		[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		public static extern bool ProcessIdToSessionId(int processId, ref int pSessionId);
		
		public class TerminalSessionData
		{
			public int SessionId;
			public string ConnectionState;
			public string SessionName;
			public bool IsUserSession;
			public TerminalSessionData(int sessionId, string connState, string sessionName, bool isUserSession)
			{
				SessionId = sessionId;
				ConnectionState = connState;
				SessionName = sessionName;
				IsUserSession = isUserSession;
			}
		}
		
		public class TerminalSessionInfo
		{
			public string NTAccount;
			public string SID;
			public string UserName;
			public string DomainName;
			public int SessionId;
			public string SessionName;
			public string ConnectState;
			public bool IsCurrentSession;
			public bool IsConsoleSession;
			public bool IsActiveUserSession;
			public bool IsUserSession;
			public bool IsRdpSession;
			public bool IsLocalAdmin;
			public DateTime? LogonTime;
			public TimeSpan? IdleTime;
			public DateTime? DisconnectTime;
			public string ClientName;
			public string ClientProtocolType;
			public string ClientDirectory;
			public int ClientBuildNumber;
		}
		
		[StructLayout(LayoutKind.Sequential)]
		private struct WTS_SESSION_INFO
		{
			public Int32 SessionId;
			[MarshalAs(UnmanagedType.LPStr)]
			public string SessionName;
			public WTS_CONNECTSTATE_CLASS State;
		}
		
		[StructLayout(LayoutKind.Sequential)]
		public struct WINSTATIONINFORMATIONW
		{
			[MarshalAs(UnmanagedType.ByValArray, SizeConst = 70)]
			private byte[] Reserved1;
			public int SessionId;
			[MarshalAs(UnmanagedType.ByValArray, SizeConst = 4)]
			private byte[] Reserved2;
			public FILETIME ConnectTime;
			public FILETIME DisconnectTime;
			public FILETIME LastInputTime;
			public FILETIME LoginTime;
			[MarshalAs(UnmanagedType.ByValArray, SizeConst = 1096)]
			private byte[] Reserved3;
			public FILETIME CurrentTime;
		}
		
		public enum WINSTATIONINFOCLASS
		{
			WinStationInformation = 8
		}
		
		public enum WTS_CONNECTSTATE_CLASS
		{
			Active,
			Connected,
			ConnectQuery,
			Shadow,
			Disconnected,
			Idle,
			Listen,
			Reset,
			Down,
			Init
		}
		
		public enum WTS_INFO_CLASS
		{
			SessionId=4,
			UserName,
			SessionName,
			DomainName,
			ConnectState,
			ClientBuildNumber,
			ClientName,
			ClientDirectory,
			ClientProtocolType=16
		}
		
		private static IntPtr OpenServer(string Name)
		{
			IntPtr server = WTSOpenServer(Name);
			return server;
		}
		
		private static void CloseServer(IntPtr ServerHandle)
		{
			WTSCloseServer(ServerHandle);
		}
		
		private static IList<T> PtrToStructureList<T>(IntPtr ppList, int count) where T : struct
		{
			List<T> result = new List<T>();
			long pointer = ppList.ToInt64();
			int sizeOf = Marshal.SizeOf(typeof(T));
			
			for (int index = 0; index < count; index++)
			{
				T item = (T) Marshal.PtrToStructure(new IntPtr(pointer), typeof(T));
				result.Add(item);
				pointer += sizeOf;
			}
			return result;
		}
		
		public static DateTime? FileTimeToDateTime(FILETIME ft)
		{
			if (ft.dwHighDateTime == 0 && ft.dwLowDateTime == 0)
			{
				return null;
			}
			long hFT = (((long) ft.dwHighDateTime) << 32) + ft.dwLowDateTime;
			return DateTime.FromFileTime(hFT);
		}
		
		public static WINSTATIONINFORMATIONW GetWinStationInformation(IntPtr server, int sessionId)
		{
			int retLen = 0;
			WINSTATIONINFORMATIONW wsInfo = new WINSTATIONINFORMATIONW();
			WinStationQueryInformation(server, sessionId, (int) WINSTATIONINFOCLASS.WinStationInformation, ref wsInfo, Marshal.SizeOf(typeof(WINSTATIONINFORMATIONW)), ref retLen);
			return wsInfo;
		}
		
		public static TerminalSessionData[] ListSessions(string ServerName)
		{
			IntPtr server = IntPtr.Zero;
			if (ServerName == "localhost" || ServerName == String.Empty)
			{
				ServerName = Environment.MachineName;
			}
			
			List<TerminalSessionData> results = new List<TerminalSessionData>();
			
			try
			{
				server = OpenServer(ServerName);
				IntPtr ppSessionInfo = IntPtr.Zero;
				int count;
				bool _isUserSession = false;
				IList<WTS_SESSION_INFO> sessionsInfo;
				
				if (WTSEnumerateSessions(server, 0, 1, out ppSessionInfo, out count) == 0)
				{
					throw new Win32Exception();
				}
				
				try
				{
					sessionsInfo = PtrToStructureList<WTS_SESSION_INFO>(ppSessionInfo, count);
				}
				finally
				{
					WTSFreeMemory(ppSessionInfo);
				}
				
				foreach (WTS_SESSION_INFO sessionInfo in sessionsInfo)
				{
					if (sessionInfo.SessionName != "Services" && sessionInfo.SessionName != "RDP-Tcp")
					{
						_isUserSession = true;
					}
					results.Add(new TerminalSessionData(sessionInfo.SessionId, sessionInfo.State.ToString(), sessionInfo.SessionName, _isUserSession));
					_isUserSession = false;
				}
			}
			finally
			{
				CloseServer(server);
			}
			
			TerminalSessionData[] returnData = results.ToArray();
			return returnData;
		}
		
		public static TerminalSessionInfo GetSessionInfo(string ServerName, int SessionId)
		{
			IntPtr server = IntPtr.Zero;
			IntPtr buffer = IntPtr.Zero;
			int bytesReturned;
			TerminalSessionInfo data = new TerminalSessionInfo();
			bool _IsCurrentSessionId = false;
			bool _IsConsoleSession = false;
			bool _IsUserSession = false;
			int currentSessionID = 0;
			string _NTAccount = String.Empty;
			if (ServerName == "localhost" || ServerName == String.Empty)
			{
				ServerName = Environment.MachineName;
			}
			if (ProcessIdToSessionId(GetCurrentProcessId(), ref currentSessionID) == false)
			{
				currentSessionID = -1;
			}
			
			// Get all members of the local administrators group
			bool _IsLocalAdminCheckSuccess = false;
			List<string> localAdminGroupSidsList = new List<string>();
			try
			{
				DirectoryEntry localMachine = new DirectoryEntry("WinNT://" + ServerName + ",Computer");
				string localAdminGroupName = new SecurityIdentifier("S-1-5-32-544").Translate(typeof(NTAccount)).Value.Split('\\')[1];
				DirectoryEntry admGroup = localMachine.Children.Find(localAdminGroupName, "group");
				object members = admGroup.Invoke("members", null);
				foreach (object groupMember in (IEnumerable)members)
				{
					DirectoryEntry member = new DirectoryEntry(groupMember);
					if (member.Name != String.Empty)
					{
						localAdminGroupSidsList.Add((new NTAccount(member.Name)).Translate(typeof(SecurityIdentifier)).Value);
					}
				}
				_IsLocalAdminCheckSuccess = true;
			}
			catch { }
			
			try
			{
				server = OpenServer(ServerName);
				
				if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.ClientBuildNumber, out buffer, out bytesReturned) == false)
				{
					return data;
				}
				int lData = Marshal.ReadInt32(buffer);
				data.ClientBuildNumber = lData;
				
				if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.ClientDirectory, out buffer, out bytesReturned) == false)
				{
					return data;
				}
				string strData = Marshal.PtrToStringAnsi(buffer);
				data.ClientDirectory = strData;
				
				if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.ClientName, out buffer, out bytesReturned) == false)
				{
					return data;
				}
				strData = Marshal.PtrToStringAnsi(buffer);
				data.ClientName = strData;
				
				if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.ClientProtocolType, out buffer, out bytesReturned) == false)
				{
					return data;
				}
				Int16 intData = Marshal.ReadInt16(buffer);
				if (intData == 2)
				{
					strData = "RDP";
					data.IsRdpSession = true;
				}
				else
				{
					strData = "";
					data.IsRdpSession = false;
				}
				data.ClientProtocolType = strData;
				
				if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.ConnectState, out buffer, out bytesReturned) == false)
				{
					return data;
				}
				lData = Marshal.ReadInt32(buffer);
				data.ConnectState = ((WTS_CONNECTSTATE_CLASS) lData).ToString();
				
				if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.SessionId, out buffer, out bytesReturned) == false)
				{
					return data;
				}
				lData = Marshal.ReadInt32(buffer);
				data.SessionId = lData;
				
				if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.DomainName, out buffer, out bytesReturned) == false)
				{
					return data;
				}
				strData = Marshal.PtrToStringAnsi(buffer).ToUpper();
				data.DomainName = strData;
				if (strData != String.Empty)
				{
					_NTAccount = strData;
				}
				
				if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.UserName, out buffer, out bytesReturned) == false)
				{
					return data;
				}
				strData = Marshal.PtrToStringAnsi(buffer);
				data.UserName = strData;
				if (strData != String.Empty)
				{
					data.NTAccount = _NTAccount + "\\" + strData;
					string _Sid = (new NTAccount(_NTAccount + "\\" + strData)).Translate(typeof(SecurityIdentifier)).Value;
					data.SID = _Sid;
					if (_IsLocalAdminCheckSuccess == true)
					{
						foreach (string localAdminGroupSid in localAdminGroupSidsList)
						{
							if (localAdminGroupSid == _Sid)
							{
								data.IsLocalAdmin = true;
								break;
							}
							else
							{
								data.IsLocalAdmin = false;
							}
						}
					}
				}
				
				if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.SessionName, out buffer, out bytesReturned) == false)
				{
					return data;
				}
				strData = Marshal.PtrToStringAnsi(buffer);
				data.SessionName = strData;
				if (strData != "Services" && strData != "RDP-Tcp" && data.UserName != String.Empty)
				{
					_IsUserSession = true;
				}
				data.IsUserSession = _IsUserSession;
				if (strData == "Console")
				{
					_IsConsoleSession = true;
				}
				data.IsConsoleSession = _IsConsoleSession;
				
				WINSTATIONINFORMATIONW wsInfo = GetWinStationInformation(server, SessionId);
				DateTime? _loginTime = FileTimeToDateTime(wsInfo.LoginTime);
				DateTime? _lastInputTime = FileTimeToDateTime(wsInfo.LastInputTime);
				DateTime? _disconnectTime = FileTimeToDateTime(wsInfo.DisconnectTime);
				DateTime? _currentTime = FileTimeToDateTime(wsInfo.CurrentTime);
				TimeSpan? _idleTime = (_currentTime != null && _lastInputTime != null) ? _currentTime.Value - _lastInputTime.Value : TimeSpan.Zero;
				data.LogonTime = _loginTime;
				data.IdleTime = _idleTime;
				data.DisconnectTime = _disconnectTime;
				
				if (currentSessionID == SessionId)
				{
					_IsCurrentSessionId = true;
				}
				data.IsCurrentSession = _IsCurrentSessionId;
			}
			finally
			{
				WTSFreeMemory(buffer);
				buffer = IntPtr.Zero;
				CloseServer(server);
			}
			return data;
		}
		
		public static TerminalSessionInfo[] GetUserSessionInfo(string ServerName)
		{
			if (ServerName == "localhost" || ServerName == String.Empty)
			{
				ServerName = Environment.MachineName;
			}
			
			// Find and get detailed information for all user sessions
			// Also determine the active user session. If a console user exists, then that will be the active user session.
			// If no console user exists but users are logged in, such as on terminal servers, then select the first logged-in non-console user that is either 'Active' or 'Connected' as the active user.
			TerminalSessionData[] sessions = ListSessions(ServerName);
			TerminalSessionInfo sessionInfo = new TerminalSessionInfo();
			List<TerminalSessionInfo> userSessionsInfo = new List<TerminalSessionInfo>();
			string firstActiveUserNTAccount = String.Empty;
			bool IsActiveUserSessionSet = false;
			foreach (TerminalSessionData session in sessions)
			{
				if (session.IsUserSession == true)
				{
					sessionInfo = GetSessionInfo(ServerName, session.SessionId);
					if (sessionInfo.IsUserSession == true)
					{
						if ((firstActiveUserNTAccount == String.Empty) && (sessionInfo.ConnectState == "Active" || sessionInfo.ConnectState == "Connected"))
						{
							firstActiveUserNTAccount = sessionInfo.NTAccount;
						}
						
						if (sessionInfo.IsConsoleSession == true)
						{
							sessionInfo.IsActiveUserSession = true;
							IsActiveUserSessionSet = true;
						}
						else
						{
							sessionInfo.IsActiveUserSession = false;
						}
						
						userSessionsInfo.Add(sessionInfo);
					}
				}
			}
			
			TerminalSessionInfo[] userSessions = userSessionsInfo.ToArray();
			if (IsActiveUserSessionSet == false)
			{
				foreach (TerminalSessionInfo userSession in userSessions)
				{
					if (userSession.NTAccount == firstActiveUserNTAccount)
					{
						userSession.IsActiveUserSession = true;
						break;
					}
				}
			}
			
			return userSessions;
		}
	}
}

'@ -ReferencedAssemblies $ReferencedAssemblies -IgnoreWarnings -ErrorAction 'Stop'
			
			
			[Security.Principal.WindowsIdentity]$CurrentProcessToken = [Security.Principal.WindowsIdentity]::GetCurrent()
			[Security.Principal.SecurityIdentifier]$CurrentProcessSID = $CurrentProcessToken.User
			[string]$ProcessNTAccount = $CurrentProcessToken.Name
			[string]$ProcessNTAccountSID = $CurrentProcessSID.Value
			[boolean]$IsAdmin = [boolean]($CurrentProcessToken.Groups -contains [Security.Principal.SecurityIdentifier]'S-1-5-32-544')
			
			[string]$exeSchTasks = "$env:WinDir\System32\schtasks.exe" # Manages Scheduled Tasks
			
			#region Function Write-Log
			
			
			Function Write-Log {
<#
.SYNOPSIS
	Write messages to a log file in CMTrace.exe compatible format or Legacy text file format.
.DESCRIPTION
	Write messages to a log file in CMTrace.exe compatible format or Legacy text file format and optionally display in the console.
.PARAMETER Message
	The message to write to the log file or output to the console.
.PARAMETER Severity
	Defines message type. When writing to console or CMTrace.exe log format, it allows highlighting of message type.
	Options: 1 = Information (default), 2 = Warning (highlighted in yellow), 3 = Error (highlighted in red)
.PARAMETER Source
	The source of the message being logged.
.PARAMETER ScriptSection
	The heading for the portion of the script that is being executed. Default is: $script:installPhase.
.PARAMETER LogType
	Choose whether to write a CMTrace.exe compatible log file or a Legacy text log file.
.PARAMETER LogFileDirectory
	Set the directory where the log file will be saved.
.PARAMETER LogFileName
	Set the name of the log file.
.PARAMETER MaxLogFileSizeMB
	Maximum file size limit for log file in megabytes (MB). Default is 10 MB.
.PARAMETER WriteHost
	Write the log message to the console.
.PARAMETER ContinueOnError
	Suppress writing log message to console on failure to write message to log file.
.PARAMETER PassThru
	Return the message that was passed to the function
.PARAMETER DebugMessage
	Specifies that the message is a debug message. Debug messages only get logged if -LogDebugMessage is set to $true.
.PARAMETER LogDebugMessage
	Debug messages only get logged if this parameter is set to $true in the config XML file.
.EXAMPLE
	Write-Log -Message "Installing patch MS15-031" -Source 'Add-Patch' -LogType 'CMTrace'
.EXAMPLE
	Write-Log -Message "Script is running on Windows 8" -Source 'Test-ValidOS' -LogType 'Legacy'
.NOTES
.LINK
	http://psappdeploytoolkit.codeplex.com
#>
				[CmdletBinding()]
				Param (
					[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
					[AllowEmptyCollection()]
					[Alias('Text')]
					[string[]]$Message,
					[Parameter(Mandatory = $false, Position = 1)]
					[ValidateRange(1, 3)]
					[int16]$Severity = 1,
					[Parameter(Mandatory = $false, Position = 2)]
					[ValidateNotNull()]
					[string]$Source = '',
					[Parameter(Mandatory = $false, Position = 3)]
					[ValidateNotNullorEmpty()]
					#[string]$ScriptSection = $script:installPhase,
					[string]$ScriptSection = '',
					[Parameter(Mandatory = $false, Position = 4)]
					[ValidateSet('CMTrace', 'Legacy')]
					#[string]$LogType = $configToolkitLogStyle,
					[string]$LogType = 'CMTrace',
					[Parameter(Mandatory = $false, Position = 5)]
					[ValidateNotNullorEmpty()]
					#[string]$LogFileDirectory = $logDirectory,
					[string]$LogFileDirectory = 'C:\TempLogs',
					[Parameter(Mandatory = $false, Position = 6)]
					[ValidateNotNullorEmpty()]
					#[string]$LogFileName = $logName,
					[string]$LogFileName = 'LastInput.log',
					[Parameter(Mandatory = $false, Position = 7)]
					[ValidateNotNullorEmpty()]
					#[decimal]$MaxLogFileSizeMB = $configToolkitLogMaxSize,
					[decimal]$MaxLogFileSizeMB = '10',
					[Parameter(Mandatory = $false, Position = 8)]
					[ValidateNotNullorEmpty()]
					#[boolean]$WriteHost = $configToolkitLogWriteToHost,
					[boolean]$WriteHost = $WriteHostParam,
					[Parameter(Mandatory = $false, Position = 9)]
					[ValidateNotNullorEmpty()]
					[boolean]$ContinueOnError = $true,
					[Parameter(Mandatory = $false, Position = 10)]
					[switch]$PassThru = $false,
					[Parameter(Mandatory = $false, Position = 11)]
					[switch]$DebugMessage = $false,
					[Parameter(Mandatory = $false, Position = 12)]
					#[boolean]$LogDebugMessage = $configToolkitLogDebugMessage
					[boolean]$LogDebugMessage = $false
				)
				
				Begin {
					## Get the name of this function
					[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
					
					## Logging Variables
					#  Log file date/time
					[string]$LogTime = (Get-Date -Format HH:mm:ss.fff).ToString()
					[string]$LogDate = (Get-Date -Format MM-dd-yyyy).ToString()
					If (-not (Test-Path -Path 'variable:LogTimeZoneBias')) { [int32]$script:LogTimeZoneBias = [timezone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes }
					[string]$LogTimePlusBias = $LogTime + $script:LogTimeZoneBias
					#  Initialize variables
					[boolean]$ExitLoggingFunction = $false
					If (-not (Test-Path -Path 'variable:DisableLogging')) { $DisableLogging = $false }
					#  Check if the script section is defined
					[boolean]$ScriptSectionDefined = [boolean](-not [string]::IsNullOrEmpty($ScriptSection))
					#  Get the file name of the source script
					Try {
						If ($script:MyInvocation.Value.ScriptName) {
							[string]$ScriptSource = Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf -ErrorAction 'Stop'
						} Else {
							[string]$ScriptSource = Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf -ErrorAction 'Stop'
						}
					} Catch {
						$ScriptSource = ''
					}
					
					## Create script block for generating CMTrace.exe compatible log entry
					[scriptblock]$CMTraceLogString = {
						Param (
							[string]$lMessage,
							[string]$lSource,
							[int16]$lSeverity
						)
						"<![LOG[$lMessage]LOG]!>" + "<time=`"$LogTimePlusBias`" " + "date=`"$LogDate`" " + "component=`"$lSource`" " + "context=`"$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + "type=`"$lSeverity`" " + "thread=`"$PID`" " + "file=`"$ScriptSource`">"
					}
					
					## Create script block for writing log entry to the console
					[scriptblock]$WriteLogLineToHost = {
						Param (
							[string]$lTextLogLine,
							[int16]$lSeverity
						)
						If ($WriteHost) {
							#  Only output using color options if running in a host which supports colors.
							If ($Host.UI.RawUI.ForegroundColor) {
								Switch ($lSeverity) {
									3 { Write-Host $lTextLogLine -ForegroundColor 'Red' -BackgroundColor 'Black' }
									2 { Write-Host $lTextLogLine -ForegroundColor 'Yellow' -BackgroundColor 'Black' }
									1 { Write-Host $lTextLogLine }
								}
							}
							#  If executing "powershell.exe -File <filename>.ps1 > log.txt", then all the Write-Host calls are converted to Write-Output calls so that they are included in the text log.
Else {
								Write-Output $lTextLogLine
							}
						}
					}
					
					## Exit function if it is a debug message and logging debug messages is not enabled in the config XML file
					If (($DebugMessage) -and (-not $LogDebugMessage)) { [boolean]$ExitLoggingFunction = $true; Return }
					## Exit function if logging to file is disabled and logging to console host is disabled
					If (($DisableLogging) -and (-not $WriteHost)) { [boolean]$ExitLoggingFunction = $true; Return }
					## Exit Begin block if logging is disabled
					If ($DisableLogging) { Return }
					
					## Create the directory where the log file will be saved
					If (-not (Test-Path -Path $LogFileDirectory -PathType Container)) {
						Try {
							New-Item -Path $LogFileDirectory -ItemType 'Directory' -Force -ErrorAction 'Stop' | Out-Null
						} Catch {
							[boolean]$ExitLoggingFunction = $true
							#  If error creating directory, write message to console
							If (-not $ContinueOnError) {
								Write-Host "[$LogDate $LogTime] [${CmdletName}] $ScriptSection :: Failed to create the log directory [$LogFileDirectory]. `n$(Resolve-Error)" -ForegroundColor 'Red'
							}
							Return
						}
					}
					
					## Assemble the fully qualified path to the log file
					[string]$LogFilePath = Join-Path -Path $LogFileDirectory -ChildPath $LogFileName
				}
				Process {
					## Exit function if logging is disabled
					If ($ExitLoggingFunction) { Return }
					
					ForEach ($Msg in $Message) {
						## If the message is not $null or empty, create the log entry for the different logging methods
						[string]$CMTraceMsg = ''
						[string]$ConsoleLogLine = ''
						[string]$LegacyTextLogLine = ''
						If ($Msg) {
							#  Create the CMTrace log message
							If ($ScriptSectionDefined) { [string]$CMTraceMsg = "[$ScriptSection] :: $Msg" }
							
							#  Create a Console and Legacy "text" log entry
							[string]$LegacyMsg = "[$LogDate $LogTime]"
							If ($ScriptSectionDefined) { [string]$LegacyMsg += " [$ScriptSection]" }
							If ($Source) {
								[string]$ConsoleLogLine = "$LegacyMsg [$Source] :: $Msg"
								Switch ($Severity) {
									3 { [string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Error] :: $Msg" }
									2 { [string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Warning] :: $Msg" }
									1 { [string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Info] :: $Msg" }
								}
							} Else {
								[string]$ConsoleLogLine = "$LegacyMsg :: $Msg"
								Switch ($Severity) {
									3 { [string]$LegacyTextLogLine = "$LegacyMsg [Error] :: $Msg" }
									2 { [string]$LegacyTextLogLine = "$LegacyMsg [Warning] :: $Msg" }
									1 { [string]$LegacyTextLogLine = "$LegacyMsg [Info] :: $Msg" }
								}
							}
						}
						
						## Execute script block to create the CMTrace.exe compatible log entry
						[string]$CMTraceLogLine = & $CMTraceLogString -lMessage $CMTraceMsg -lSource $Source -lSeverity $Severity
						
						## Choose which log type to write to file
						If ($LogType -ieq 'CMTrace') {
							[string]$LogLine = $CMTraceLogLine
						} Else {
							[string]$LogLine = $LegacyTextLogLine
						}
						
						## Write the log entry to the log file if logging is not currently disabled
						If (-not $DisableLogging) {
							Try {
								$LogLine | Out-File -FilePath $LogFilePath -Append -NoClobber -Force -Encoding 'UTF8' -ErrorAction 'Stop'
							} Catch {
								If (-not $ContinueOnError) {
									Write-Host "[$LogDate $LogTime] [$ScriptSection] [${CmdletName}] :: Failed to write message [$Msg] to the log file [$LogFilePath]. `n$(Resolve-Error)" -ForegroundColor 'Red'
								}
							}
						}
						
						## Execute script block to write the log entry to the console if $WriteHost is $true
						& $WriteLogLineToHost -lTextLogLine $ConsoleLogLine -lSeverity $Severity
					}
				}
				End {
					## Archive log file if size is greater than $MaxLogFileSizeMB and $MaxLogFileSizeMB > 0
					Try {
						If ((-not $ExitLoggingFunction) -and (-not $DisableLogging)) {
							[IO.FileInfo]$LogFile = Get-ChildItem -Path $LogFilePath -ErrorAction 'Stop'
							[decimal]$LogFileSizeMB = $LogFile.Length/1MB
							If (($LogFileSizeMB -gt $MaxLogFileSizeMB) -and ($MaxLogFileSizeMB -gt 0)) {
								## Change the file extension to "lo_"
								[string]$ArchivedOutLogFile = [IO.Path]::ChangeExtension($LogFilePath, 'lo_')
								[hashtable]$ArchiveLogParams = @{ ScriptSection = $ScriptSection; Source = ${CmdletName}; Severity = 2; LogFileDirectory = $LogFileDirectory; LogFileName = $LogFileName; LogType = $LogType; MaxLogFileSizeMB = 0; WriteHost = $WriteHost; ContinueOnError = $ContinueOnError; PassThru = $false }
								
								## Log message about archiving the log file
								$ArchiveLogMessage = "Maximum log file size [$MaxLogFileSizeMB MB] reached. Rename log file to [$ArchivedOutLogFile]."
								Write-Log -Message $ArchiveLogMessage @ArchiveLogParams
								
								## Archive existing log file from <filename>.log to <filename>.lo_. Overwrites any existing <filename>.lo_ file. This is the same method SCCM uses for log files.
								Move-Item -Path $LogFilePath -Destination $ArchivedOutLogFile -Force -ErrorAction 'Stop'
								
								## Start new log file and Log message about archiving the old log file
								$NewLogMessage = "Previous log file was renamed to [$ArchivedOutLogFile] because maximum log file size of [$MaxLogFileSizeMB MB] was reached."
								Write-Log -Message $NewLogMessage @ArchiveLogParams
							}
						}
					} Catch {
						## If renaming of file fails, script will continue writing to log file even if size goes over the max file size
					} Finally {
						If ($PassThru) { Write-Output $Message }
					}
				}
			}
			#endregion
			
			#region Function Write-FunctionHeaderOrFooter
			Function Write-FunctionHeaderOrFooter {
<#
.SYNOPSIS
	Write the function header or footer to the log upon first entering or exiting a function.
.DESCRIPTION
	Write the "Function Start" message, the bound parameters the function was invoked with, or the "Function End" message when entering or exiting a function.
	Messages are debug messages so will only be logged if LogDebugMessage option is enabled in XML config file.
.PARAMETER CmdletName
	The name of the function this function is invoked from.
.PARAMETER CmdletBoundParameters
	The bound parameters of the function this function is invoked from.
.PARAMETER Header
	Write the function header.
.PARAMETER Footer
	Write the function footer.
.EXAMPLE
	Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
.EXAMPLE
	Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
.NOTES
	This is an internal script function and should typically not be called directly.
.LINK
	http://psappdeploytoolkit.codeplex.com
#>
				[CmdletBinding()]
				Param (
					[Parameter(Mandatory = $true)]
					[ValidateNotNullorEmpty()]
					[string]$CmdletName,
					[Parameter(Mandatory = $true, ParameterSetName = 'Header')]
					[AllowEmptyCollection()]
					[hashtable]$CmdletBoundParameters,
					[Parameter(Mandatory = $true, ParameterSetName = 'Header')]
					[switch]$Header,
					[Parameter(Mandatory = $true, ParameterSetName = 'Footer')]
					[switch]$Footer
				)
				
				If ($Header) {
					Write-Log -Message 'Function Start' -Source ${CmdletName} -DebugMessage
					
					## Get the parameters that the calling function was invoked with
					[string]$CmdletBoundParameters = $CmdletBoundParameters | Format-Table -Property @{ Label = 'Parameter'; Expression = { "[-$($_.Key)]" } }, @{ Label = 'Value'; Expression = { $_.Value }; Alignment = 'Left' } -AutoSize -Wrap | Out-String
					If ($CmdletBoundParameters) {
						Write-Log -Message "Function invoked with bound parameter(s): `n$CmdletBoundParameters" -Source ${CmdletName} -DebugMessage
					} Else {
						Write-Log -Message 'Function invoked without any bound parameters.' -Source ${CmdletName} -DebugMessage
					}
				} ElseIf ($Footer) {
					Write-Log -Message 'Function End' -Source ${CmdletName} -DebugMessage
				}
			}
			#endregion
			
			#region Function Execute-ProcessAsUser
			Function Execute-ProcessAsUser {
<#
.SYNOPSIS
	Execute a process with a logged in user account, by using a scheduled task, to provide interaction with user in the SYSTEM context.
.DESCRIPTION
	Execute a process with a logged in user account, by using a scheduled task, to provide interaction with user in the SYSTEM context.
.PARAMETER UserName
	Logged in Username under which to run the process from. Default is: The active console user. If no console user exists but users are logged in, such as on terminal servers, then the first logged-in non-console user.
.PARAMETER Path
	Path to the file being executed.
.PARAMETER Parameters
	Arguments to be passed to the file being executed.
.PARAMETER RunLevel
	Specifies the level of user rights that Task Scheduler uses to run the task. The acceptable values for this parameter are:
	- HighestAvailable: Tasks run by using the highest available privileges (Admin privileges for Administrators). Default Value.
	- LeastPrivilege: Tasks run by using the least-privileged user account (LUA) privileges.
.PARAMETER Wait
	Wait for the process, launched by the scheduled task, to complete execution before accepting more input. Default is $false.
.PARAMETER PassThru
	Returns the exit code from this function or the process launched by the scheduled task.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is $true.
.EXAMPLE
	Execute-ProcessAsUser -UserName 'CONTOSO\User' -Path "$PSHOME\powershell.exe" -Parameters "-Command & { & `"C:\Test\Script.ps1`"; Exit `$LastExitCode }" -Wait
	Execute process under a user account by specifying a username under which to execute it.
.EXAMPLE
	Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" -Parameters "-Command & { & `"C:\Test\Script.ps1`"; Exit `$LastExitCode }" -Wait
	Execute process under a user account by using the default active logged in user that was detected when the toolkit was launched.
.NOTES
.LINK
	http://psappdeploytoolkit.codeplex.com
#>
				[CmdletBinding()]
				Param (
					[Parameter(Mandatory = $false)]
					[ValidateNotNullorEmpty()]
					[string]$UserName = $RunAsActiveUser.NTAccount,
					[Parameter(Mandatory = $true)]
					[ValidateNotNullorEmpty()]
					[string]$Path,
					[Parameter(Mandatory = $false)]
					[ValidateNotNullorEmpty()]
					[string]$Parameters = '',
					[Parameter(Mandatory = $false)]
					[ValidateSet('HighestAvailable', 'LeastPrivilege')]
					[string]$RunLevel = 'HighestAvailable',
					[Parameter(Mandatory = $false)]
					[ValidateNotNullOrEmpty()]
					[switch]$Wait = $false,
					[Parameter(Mandatory = $false)]
					[switch]$PassThru = $false,
					[Parameter(Mandatory = $false)]
					[ValidateNotNullOrEmpty()]
					[boolean]$ContinueOnError = $true
				)
				
				Begin {
					## Get the name of this function and write header
					[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
					Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
				}
				Process {
					## Initialize exit code variable
					[int32]$executeProcessAsUserExitCode = 0
					
					## Confirm that the username field is not empty
					If (-not $UserName) {
						[int32]$executeProcessAsUserExitCode = 60009
						Write-Log -Message "The function [${CmdletName}] has a -UserName parameter that has an empty default value because no logged in users were detected when the toolkit was launched." -Severity 3 -Source ${CmdletName}
						If (-not $ContinueOnError) {
							Throw "The function [${CmdletName}] has a -UserName parameter that has an empty default value because no logged in users were detected when the toolkit was launched."
						} Else {
							Return
						}
					}
					
					## Confirm if the toolkit is running with administrator privileges
					If (($RunLevel -eq 'HighestAvailable') -and (-not $IsAdmin)) {
						[int32]$executeProcessAsUserExitCode = 60003
						Write-Log -Message "The function [${CmdletName}] requires the toolkit to be running with Administrator privileges if the [-RunLevel] parameter is set to 'HighestAvailable'." -Severity 3 -Source ${CmdletName}
						If (-not $ContinueOnError) {
							Throw "The function [${CmdletName}] requires the toolkit to be running with Administrator privileges if the [-RunLevel] parameter is set to 'HighestAvailable'."
						} Else {
							Return
						}
					}
					
					## Build the scheduled task XML name
					[string]$schTaskName = "$appDeployToolkitName-ExecuteAsUser"
					
					##  Create the temporary App Deploy Toolkit files folder if it doesn't already exist
					If (-not (Test-Path -Path $dirAppDeployTemp -PathType Container)) {
						$null = New-Item -Path $dirAppDeployTemp -ItemType Directory -Force -ErrorAction 'Stop'
					}
					
					## If PowerShell.exe is being launched, then create a VBScript to launch PowerShell so that we can suppress the console window that flashes otherwise
					If (($Path -eq 'PowerShell.exe') -or ((Split-Path -Path $Path -Leaf) -eq 'PowerShell.exe')) {

						[string]$executeProcessAsUserParametersVBS = 'chr(34) & ' + "`"$($Path)`"" + ' & chr(34) & ' + '" ' + ($Parameters -replace '"', "`" & chr(34) & `"" -replace ' & chr\(34\) & "$', '') + '"'
						[string[]]$executeProcessAsUserScript = "strCommand = $executeProcessAsUserParametersVBS"
						$executeProcessAsUserScript += 'set oWShell = CreateObject("WScript.Shell")'
						$executeProcessAsUserScript += 'intReturn = oWShell.Run(strCommand, 0, true)'
						$executeProcessAsUserScript += 'WScript.Quit intReturn'
						$executeProcessAsUserScript | Out-File -FilePath "$dirAppDeployTemp\$($schTaskName).vbs" -Force -Encoding 'default' -ErrorAction 'SilentlyContinue'
						$Path = 'wscript.exe'
						$Parameters = "`"$dirAppDeployTemp\$($schTaskName).vbs`""
						
					}
					
					
					## Specify the scheduled task configuration in XML format
					[string]$xmlSchTask = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo />
  <Triggers />
  <Settings>
	<MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
	<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
	<StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
	<AllowHardTerminate>true</AllowHardTerminate>
	<StartWhenAvailable>false</StartWhenAvailable>
	<RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
	<IdleSettings>
	  <StopOnIdleEnd>false</StopOnIdleEnd>
	  <RestartOnIdle>false</RestartOnIdle>
	</IdleSettings>
	<AllowStartOnDemand>true</AllowStartOnDemand>
	<Enabled>true</Enabled>
	<Hidden>false</Hidden>
	<RunOnlyIfIdle>false</RunOnlyIfIdle>
	<WakeToRun>false</WakeToRun>
	<ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
	<Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
	<Exec>
	  <Command>$Path</Command>
	  <Arguments>$Parameters</Arguments>
	</Exec>
  </Actions>
  <Principals>
	<Principal id="Author">
	  <UserId>$UserName</UserId>
	  <LogonType>InteractiveToken</LogonType>
	  <RunLevel>$RunLevel</RunLevel>
	</Principal>
  </Principals>
</Task>
"@
					## Export the XML to file
					Try {
						#  Specify the filename to export the XML to
						[string]$xmlSchTaskFilePath = "$dirAppDeployTemp\$schTaskName.xml"
						[string]$xmlSchTask | Out-File -FilePath $xmlSchTaskFilePath -Force -ErrorAction Stop
					} Catch {
						[int32]$executeProcessAsUserExitCode = 60007
						Write-Log -Message "Failed to export the scheduled task XML file [$xmlSchTaskFilePath]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
						If (-not $ContinueOnError) {
							Throw "Failed to export the scheduled task XML file [$xmlSchTaskFilePath]: $($_.Exception.Message)"
						} Else {
							Return
						}
					}
					
					## Create Scheduled Task to run the process with a logged-on user account
					If ($Parameters) {
						Write-Log -Message "Create scheduled task to run the process [$Path $Parameters] as the logged-on user [$userName]..." -Source ${CmdletName}
					} Else {
						Write-Log -Message "Create scheduled task to run the process [$Path] as the logged-on user [$userName]..." -Source ${CmdletName}
					}
					[psobject]$schTaskResult = Execute-Process -Path $exeSchTasks -Parameters "/create /f /tn $schTaskName /xml `"$xmlSchTaskFilePath`"" -WindowStyle Hidden -CreateNoWindow -PassThru
					If ($schTaskResult.ExitCode -ne 0) {
						[int32]$executeProcessAsUserExitCode = $schTaskResult.ExitCode
						Write-Log -Message "Failed to create the scheduled task by importing the scheduled task XML file [$xmlSchTaskFilePath]." -Severity 3 -Source ${CmdletName}
						If (-not $ContinueOnError) {
							Throw "Failed to create the scheduled task by importing the scheduled task XML file [$xmlSchTaskFilePath]."
						} Else {
							Return
						}
					}
					
					## Trigger the Scheduled Task
					If ($Parameters) {
						Write-Log -Message "Trigger execution of scheduled task with command [$Path $Parameters] as the logged-on user [$userName]..." -Source ${CmdletName}
					} Else {
						Write-Log -Message "Trigger execution of scheduled task with command [$Path] as the logged-on user [$userName]..." -Source ${CmdletName}
					}
					[psobject]$schTaskResult = Execute-Process -Path $exeSchTasks -Parameters "/run /i /tn $schTaskName" -WindowStyle Hidden -CreateNoWindow -Passthru
					If ($schTaskResult.ExitCode -ne 0) {
						[int32]$executeProcessAsUserExitCode = $schTaskResult.ExitCode
						Write-Log -Message "Failed to trigger scheduled task [$schTaskName]." -Severity 3 -Source ${CmdletName}
						#  Delete Scheduled Task
						Write-Log -Message 'Delete the scheduled task which did not trigger.' -Source ${CmdletName}
						Execute-Process -Path $exeSchTasks -Parameters "/delete /tn $schTaskName /f" -WindowStyle Hidden -CreateNoWindow -ContinueOnError $true
						If (-not $ContinueOnError) {
							Throw "Failed to trigger scheduled task [$schTaskName]."
						} Else {
							Return
						}
					}
					
					## Wait for the process launched by the scheduled task to complete execution
					If ($Wait) {
						Write-Log -Message "Waiting for the process launched by the scheduled task [$schTaskName] to complete execution (this may take some time)..." -Source ${CmdletName}
						Start-Sleep -Seconds 1
						While ((($exeSchTasksResult = & $exeSchTasks /query /TN $schTaskName /V /FO CSV) | ConvertFrom-CSV | Select-Object -ExpandProperty 'Status' | Select-Object -First 1) -eq 'Running') {
							Start-Sleep -Seconds 5
						}
						#  Get the exit code from the process launched by the scheduled task
						[int32]$executeProcessAsUserExitCode = ($exeSchTasksResult = & $exeSchTasks /query /TN $schTaskName /V /FO CSV) | ConvertFrom-CSV | Select-Object -ExpandProperty 'Last Result' | Select-Object -First 1
						Write-Log -Message "Exit code from process launched by scheduled task [$executeProcessAsUserExitCode]." -Source ${CmdletName}
					}
					
					## Delete scheduled task
					Try {
						Write-Log -Message "Delete scheduled task [$schTaskName]." -Source ${CmdletName}
						Execute-Process -Path $exeSchTasks -Parameters "/delete /tn $schTaskName /f" -WindowStyle Hidden -CreateNoWindow -ErrorAction 'Stop'
					} Catch {
						Write-Log -Message "Failed to delete scheduled task [$schTaskName]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
					}
				}
				End {
					If ($PassThru) { Write-Output $executeProcessAsUserExitCode }
					
					Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
				}
			}
			#endregion
			
			#region Function Get-LoggedOnUser
			Function Get-LoggedOnUser {
<#
.SYNOPSIS
	Get session details for all local and RDP logged on users.
.DESCRIPTION
	Get session details for all local and RDP logged on users using Win32 APIs. Get the following session details:
	 NTAccount, SID, UserName, DomainName, SessionId, SessionName, ConnectState, IsCurrentSession, IsConsoleSession, IsUserSession, IsActiveUserSession
	 IsRdpSession, IsLocalAdmin, LogonTime, IdleTime, DisconnectTime, ClientName, ClientProtocolType, ClientDirectory, ClientBuildNumber
.EXAMPLE
	Get-LoggedOnUser
.NOTES
	Description of ConnectState property:
	Value		 Description
	-----		 -----------
	Active		 A user is logged on to the session.
	ConnectQuery The session is in the process of connecting to a client.
	Connected	 A client is connected to the session).
	Disconnected The session is active, but the client has disconnected from it.
	Down		 The session is down due to an error.
	Idle		 The session is waiting for a client to connect.
	Initializing The session is initializing.
	Listening 	 The session is listening for connections.
	Reset		 The session is being reset.
	Shadowing	 This session is shadowing another session.
	
	Description of IsActiveUserSession property:
	If a console user exists, then that will be the active user session.
	If no console user exists but users are logged in, such as on terminal servers, then the first logged-in non-console user that is either 'Active' or 'Connected' is the active user.
	
	Description of IsRdpSession property:
	Gets a value indicating whether the user is associated with an RDP client session.
.LINK
	http://psappdeploytoolkit.codeplex.com
#>
				[CmdletBinding()]
				Param (
				)
				
				Begin {
					## Get the name of this function and write header
					[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
					Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
				}
				Process {
					Try {
						Write-Log -Message 'Get session information for all logged on users.' -Source ${CmdletName}
						Write-Output ([PSADT.QueryUser]::GetUserSessionInfo("$env:ComputerName"))
					} Catch {
						Write-Log -Message "Failed to get session information for all logged on users. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
					}
				}
				End {
					Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
				}
			}
			#endregion
			
			Function Resolve-Error {
<#
.SYNOPSIS
	Enumerate error record details.
.DESCRIPTION
	Enumerate an error record, or a collection of error record, properties. By default, the details for the last error will be enumerated.
.PARAMETER ErrorRecord
	The error record to resolve. The default error record is the latest one: $global:Error[0]. This parameter will also accept an array of error records.
.PARAMETER Property
	The list of properties to display from the error record. Use "*" to display all properties.
	Default list of error properties is: Message, FullyQualifiedErrorId, ScriptStackTrace, PositionMessage, InnerException
.PARAMETER GetErrorRecord
	Get error record details as represented by $_.
.PARAMETER GetErrorInvocation
	Get error record invocation information as represented by $_.InvocationInfo.
.PARAMETER GetErrorException
	Get error record exception details as represented by $_.Exception.
.PARAMETER GetErrorInnerException
	Get error record inner exception details as represented by $_.Exception.InnerException. Will retrieve all inner exceptions if there is more than one.
.EXAMPLE
	Resolve-Error
.EXAMPLE
	Resolve-Error -Property *
.EXAMPLE
	Resolve-Error -Property InnerException
.EXAMPLE
	Resolve-Error -GetErrorInvocation:$false
.NOTES
.LINK
	http://psappdeploytoolkit.codeplex.com
#>
				[CmdletBinding()]
				Param (
					[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
					[AllowEmptyCollection()]
					[array]$ErrorRecord,
					[Parameter(Mandatory = $false, Position = 1)]
					[ValidateNotNullorEmpty()]
					[string[]]$Property = ('Message', 'InnerException', 'FullyQualifiedErrorId', 'ScriptStackTrace', 'PositionMessage'),
					[Parameter(Mandatory = $false, Position = 2)]
					[switch]$GetErrorRecord = $true,
					[Parameter(Mandatory = $false, Position = 3)]
					[switch]$GetErrorInvocation = $true,
					[Parameter(Mandatory = $false, Position = 4)]
					[switch]$GetErrorException = $true,
					[Parameter(Mandatory = $false, Position = 5)]
					[switch]$GetErrorInnerException = $true
				)
				
				Begin {
					## If function was called without specifying an error record, then choose the latest error that occurred
					If (-not $ErrorRecord) {
						If ($global:Error.Count -eq 0) {
							#Write-Warning -Message "The `$Error collection is empty"
							Return
						} Else {
							[array]$ErrorRecord = $global:Error[0]
						}
					}
					
					## Allows selecting and filtering the properties on the error object if they exist
					[scriptblock]$SelectProperty = {
						Param (
							[Parameter(Mandatory = $true)]
							[ValidateNotNullorEmpty()]
							$InputObject,
							[Parameter(Mandatory = $true)]
							[ValidateNotNullorEmpty()]
							[string[]]$Property
						)
						
						[string[]]$ObjectProperty = $InputObject | Get-Member -MemberType *Property | Select-Object -ExpandProperty Name
						ForEach ($Prop in $Property) {
							If ($Prop -eq '*') {
								[string[]]$PropertySelection = $ObjectProperty
								Break
							} ElseIf ($ObjectProperty -contains $Prop) {
								[string[]]$PropertySelection += $Prop
							}
						}
						Write-Output $PropertySelection
					}
					
					#  Initialize variables to avoid error if 'Set-StrictMode' is set
					$LogErrorRecordMsg = $null
					$LogErrorInvocationMsg = $null
					$LogErrorExceptionMsg = $null
					$LogErrorMessageTmp = $null
					$LogInnerMessage = $null
				}
				Process {
					If (-not $ErrorRecord) { Return }
					ForEach ($ErrRecord in $ErrorRecord) {
						## Capture Error Record
						If ($GetErrorRecord) {
							[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord -Property $Property
							$LogErrorRecordMsg = $ErrRecord | Select-Object -Property $SelectedProperties
						}
						
						## Error Invocation Information
						If ($GetErrorInvocation) {
							If ($ErrRecord.InvocationInfo) {
								[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord.InvocationInfo -Property $Property
								$LogErrorInvocationMsg = $ErrRecord.InvocationInfo | Select-Object -Property $SelectedProperties
							}
						}
						
						## Capture Error Exception
						If ($GetErrorException) {
							If ($ErrRecord.Exception) {
								[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord.Exception -Property $Property
								$LogErrorExceptionMsg = $ErrRecord.Exception | Select-Object -Property $SelectedProperties
							}
						}
						
						## Display properties in the correct order
						If ($Property -eq '*') {
							#  If all properties were chosen for display, then arrange them in the order the error object displays them by default.
							If ($LogErrorRecordMsg) { [array]$LogErrorMessageTmp += $LogErrorRecordMsg }
							If ($LogErrorInvocationMsg) { [array]$LogErrorMessageTmp += $LogErrorInvocationMsg }
							If ($LogErrorExceptionMsg) { [array]$LogErrorMessageTmp += $LogErrorExceptionMsg }
						} Else {
							#  Display selected properties in our custom order
							If ($LogErrorExceptionMsg) { [array]$LogErrorMessageTmp += $LogErrorExceptionMsg }
							If ($LogErrorRecordMsg) { [array]$LogErrorMessageTmp += $LogErrorRecordMsg }
							If ($LogErrorInvocationMsg) { [array]$LogErrorMessageTmp += $LogErrorInvocationMsg }
						}
						
						If ($LogErrorMessageTmp) {
							$LogErrorMessage = 'Error Record:'
							$LogErrorMessage += "`n-------------"
							$LogErrorMsg = $LogErrorMessageTmp | Format-List | Out-String
							$LogErrorMessage += $LogErrorMsg
						}
						
						## Capture Error Inner Exception(s)
						If ($GetErrorInnerException) {
							If ($ErrRecord.Exception -and $ErrRecord.Exception.InnerException) {
								$LogInnerMessage = 'Error Inner Exception(s):'
								$LogInnerMessage += "`n-------------------------"
								
								$ErrorInnerException = $ErrRecord.Exception.InnerException
								$Count = 0
								
								While ($ErrorInnerException) {
									[string]$InnerExceptionSeperator = '~' * 40
									
									[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrorInnerException -Property $Property
									$LogErrorInnerExceptionMsg = $ErrorInnerException | Select-Object -Property $SelectedProperties | Format-List | Out-String
									
									If ($Count -gt 0) { $LogInnerMessage += $InnerExceptionSeperator }
									$LogInnerMessage += $LogErrorInnerExceptionMsg
									
									$Count++
									$ErrorInnerException = $ErrorInnerException.InnerException
								}
							}
						}
						
						If ($LogErrorMessage) { $Output = $LogErrorMessage }
						If ($LogInnerMessage) { $Output += $LogInnerMessage }
						
						Write-Output $Output
						
						If (Test-Path -Path 'variable:Output') { Clear-Variable -Name Output }
						If (Test-Path -Path 'variable:LogErrorMessage') { Clear-Variable -Name LogErrorMessage }
						If (Test-Path -Path 'variable:LogInnerMessage') { Clear-Variable -Name LogInnerMessage }
						If (Test-Path -Path 'variable:LogErrorMessageTmp') { Clear-Variable -Name LogErrorMessageTmp }
					}
				}
				End {
				}
			}
			#endregion
			
			#region Function Execute-Process
			Function Execute-Process {
<#
.SYNOPSIS
	Execute a process with optional arguments, working directory, window style.
.DESCRIPTION
	Executes a process, e.g. a file included in the Files directory of the App Deploy Toolkit, or a file on the local machine.
	Provides various options for handling the return codes (see Parameters).
.PARAMETER Path
	Path to the file to be executed. If the file is located directly in the "Files" directory of the App Deploy Toolkit, only the file name needs to be specified.
	Otherwise, the full path of the file must be specified. If the files is in a subdirectory of "Files", use the "$dirFiles" variable as shown in the example.
.PARAMETER Parameters
	Arguments to be passed to the executable
.PARAMETER WindowStyle
	Style of the window of the process executed. Options: Normal, Hidden, Maximized, Minimized. Default: Normal.
	Note: Not all processes honor the "Hidden" flag. If it it not working, then check the command line options for the process being executed to see it has a silent option.
.PARAMETER CreateNoWindow
	Specifies whether the process should be started with a new window to contain it. Default is false.
.PARAMETER WorkingDirectory
	The working directory used for executing the process. Defaults to the directory of the file being executed.
.PARAMETER NoWait
	Immediately continue after executing the process.
.PARAMETER PassThru
	Returns ExitCode, STDOut, and STDErr output from the process.
.PARAMETER WaitForMsiExec
	Sometimes an EXE bootstrapper will launch an MSI install. In such cases, this variable will ensure that
	that this function waits for the msiexec engine to become available before starting the install.
.PARAMETER MsiExecWaitTime
	Specify the length of time in seconds to wait for the msiexec engine to become available. Default: 600 seconds (10 minutes).
.PARAMETER IgnoreExitCodes
	List the exit codes to ignore.
.PARAMETER ContinueOnError
	Continue if an exit code is returned by the process that is not recognized by the App Deploy Toolkit. Default: $false (fail on error).
.EXAMPLE
	Execute-Process -Path 'uninstall_flash_player_64bit.exe' -Parameters '/uninstall' -WindowStyle Hidden
	If the file is in the "Files" directory of the App Deploy Toolkit, only the file name needs to be specified.
.EXAMPLE
	Execute-Process -Path "$dirFiles\Bin\setup.exe" -Parameters '/S' -WindowStyle Hidden
.EXAMPLE
	Execute-Process -Path 'setup.exe' -Parameters '/S' -IgnoreExitCodes '1,2'
.NOTES
.LINK
	http://psappdeploytoolkit.codeplex.com
#>
				[CmdletBinding()]
				Param (
					[Parameter(Mandatory = $true)]
					[Alias('FilePath')]
					[ValidateNotNullorEmpty()]
					[string]$Path,
					[Parameter(Mandatory = $false)]
					[Alias('Arguments')]
					[ValidateNotNullorEmpty()]
					[string[]]$Parameters,
					[Parameter(Mandatory = $false)]
					[ValidateSet('Normal', 'Hidden', 'Maximized', 'Minimized')]
					[Diagnostics.ProcessWindowStyle]$WindowStyle = 'Normal',
					[Parameter(Mandatory = $false)]
					[ValidateNotNullorEmpty()]
					[switch]$CreateNoWindow = $false,
					[Parameter(Mandatory = $false)]
					[ValidateNotNullorEmpty()]
					[string]$WorkingDirectory,
					[Parameter(Mandatory = $false)]
					[switch]$NoWait = $false,
					[Parameter(Mandatory = $false)]
					[switch]$PassThru = $false,
					[Parameter(Mandatory = $false)]
					[switch]$WaitForMsiExec = $false,
					[Parameter(Mandatory = $false)]
					[ValidateNotNullorEmpty()]
					#[timespan]$MsiExecWaitTime = $(New-TimeSpan -Seconds $configMSIMutexWaitTime),
					[timespan]$MsiExecWaitTime = $(New-TimeSpan -Seconds 30),
					[Parameter(Mandatory = $false)]
					[ValidateNotNullorEmpty()]
					[string]$IgnoreExitCodes,
					[Parameter(Mandatory = $false)]
					[ValidateNotNullorEmpty()]
					[boolean]$ContinueOnError = $false
				)
				
				Begin {
					## Get the name of this function and write header
					[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
					Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
				}
				Process {
					Try {
						$private:returnCode = $null
						
						## Validate and find the fully qualified path for the $Path variable.
						If (([IO.Path]::IsPathRooted($Path)) -and ([IO.Path]::HasExtension($Path))) {
							Write-Log -Message "[$Path] is a valid fully qualified path, continue." -Source ${CmdletName}
							If (-not (Test-Path -Path $Path -PathType Leaf -ErrorAction 'Stop')) {
								Throw "File [$Path] not found."
							}
						} Else {
							#  The first directory to search will be the 'Files' subdirectory of the script directory
							[string]$PathFolders = $dirFiles
							#  Add the current location of the console (Windows always searches this location first)
							[string]$PathFolders = $PathFolders + ';' + (Get-Location -PSProvider 'FileSystem').Path
							#  Add the new path locations to the PATH environment variable
							$env:PATH = $PathFolders + ';' + $env:PATH
							
							#  Get the fully qualified path for the file. Get-Command searches PATH environment variable to find this value.
							[string]$FullyQualifiedPath = Get-Command -Name $Path -CommandType 'Application' -TotalCount 1 -Syntax -ErrorAction 'SilentlyContinue'
							
							#  Revert the PATH environment variable to it's original value
							$env:PATH = $env:PATH -replace [regex]::Escape($PathFolders + ';'), ''
							
							If ($FullyQualifiedPath) {
								Write-Log -Message "[$Path] successfully resolved to fully qualified path [$FullyQualifiedPath]." -Source ${CmdletName}
								$Path = $FullyQualifiedPath
							} Else {
								Throw "[$Path] contains an invalid path or file name."
							}
						}
						
						## Set the Working directory (if not specified)
						If (-not $WorkingDirectory) { $WorkingDirectory = Split-Path -Path $Path -Parent -ErrorAction 'Stop' }
						
						## If MSI install, check to see if the MSI installer service is available or if another MSI install is already underway.
						## Please note that a race condition is possible after this check where another process waiting for the MSI installer
						##  to become available grabs the MSI Installer mutex before we do. Not too concerned about this possible race condition.
						If (($Path -match 'msiexec') -or ($WaitForMsiExec)) {
							[boolean]$MsiExecAvailable = Test-IsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds $MsiExecWaitTime.TotalMilliseconds
							Start-Sleep -Seconds 1
							If (-not $MsiExecAvailable) {
								#  Default MSI exit code for install already in progress
								[int32]$returnCode = 1618
								Throw 'Please complete in progress MSI installation before proceeding with this install.'
							}
						}
						
						Try {
							## Disable Zone checking to prevent warnings when running executables
							$env:SEE_MASK_NOZONECHECKS = 1
							
							## Using this variable allows capture of exceptions from .NET methods. Private scope only changes value for current function.
							$private:previousErrorActionPreference = $ErrorActionPreference
							$ErrorActionPreference = 'Stop'
							
							## Define process
							$processStartInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo -ErrorAction 'Stop'
							$processStartInfo.FileName = $Path
							$processStartInfo.WorkingDirectory = $WorkingDirectory
							$processStartInfo.UseShellExecute = $false
							$processStartInfo.ErrorDialog = $false
							$processStartInfo.RedirectStandardOutput = $true
							$processStartInfo.RedirectStandardError = $true
							$processStartInfo.CreateNoWindow = $CreateNoWindow
							If ($Parameters) { $processStartInfo.Arguments = $Parameters }
							If ($windowStyle) { $processStartInfo.WindowStyle = $WindowStyle }
							$process = New-Object -TypeName System.Diagnostics.Process -ErrorAction 'Stop'
							$process.StartInfo = $processStartInfo
							
							## Add event handler to capture process's standard output redirection
							[scriptblock]$processEventHandler = { If (-not [string]::IsNullOrEmpty($EventArgs.Data)) { $Event.MessageData.AppendLine($EventArgs.Data) } }
							$stdOutBuilder = New-Object -TypeName System.Text.StringBuilder -ArgumentList ''
							$stdOutEvent = Register-ObjectEvent -InputObject $process -Action $processEventHandler -EventName 'OutputDataReceived' -MessageData $stdOutBuilder -ErrorAction 'Stop'
							
							## Start Process
							Write-Log -Message "Working Directory is [$WorkingDirectory]." -Source ${CmdletName}
							If ($Parameters) {
								If ($Parameters -match '-Command \&') {
									Write-Log -Message "Executing [$Path [PowerShell ScriptBlock]]..." -Source ${CmdletName}
								} Else {
									Write-Log -Message "Executing [$Path $Parameters]..." -Source ${CmdletName}
								}
							} Else {
								Write-Log -Message "Executing [$Path]..." -Source ${CmdletName}
							}
							[boolean]$processStarted = $process.Start()
							
							If ($NoWait) {
								Write-Log -Message 'NoWait parameter specified. Continuing without waiting for exit code...' -Source ${CmdletName}
							} Else {
								$process.BeginOutputReadLine()
								$stdErr = $($process.StandardError.ReadToEnd()).ToString() -replace $null, ''
								
								## Instructs the Process component to wait indefinitely for the associated process to exit.
								$process.WaitForExit()
								
								## HasExited indicates that the associated process has terminated, either normally or abnormally. Wait until HasExited returns $true.
								While (-not ($process.HasExited)) { $process.Refresh(); Start-Sleep -Seconds 1 }
								
								## Get the exit code for the process
								[int32]$returnCode = $process.ExitCode
								
								## Unregister standard output event to retrieve process output
								If ($stdOutEvent) { Unregister-Event -SourceIdentifier $stdOutEvent.Name -ErrorAction 'Stop'; $stdOutEvent = $null }
								$stdOut = $stdOutBuilder.ToString() -replace $null, ''
								
								If ($stdErr.Length -gt 0) {
									Write-Log -Message "Standard error output from the process: $stdErr" -Severity 3 -Source ${CmdletName}
								}
							}
						} Finally {
							## Make sure the standard output event is unregistered
							If ($stdOutEvent) { Unregister-Event -SourceIdentifier $stdOutEvent.Name -ErrorAction 'Stop' }
							
							## Free resources associated with the process, this does not cause process to exit
							If ($process) { $process.Close() }
							
							## Re-enable Zone checking
							Remove-Item -Path env:SEE_MASK_NOZONECHECKS -ErrorAction 'SilentlyContinue'
							
							If ($private:previousErrorActionPreference) { $ErrorActionPreference = $private:previousErrorActionPreference }
						}
						
						If (-not $NoWait) {
							## Check to see whether we should ignore exit codes
							$ignoreExitCodeMatch = $false
							If ($ignoreExitCodes) {
								#  Split the processes on a comma
								[int32[]]$ignoreExitCodesArray = $ignoreExitCodes -split ','
								ForEach ($ignoreCode in $ignoreExitCodesArray) {
									If ($returnCode -eq $ignoreCode) { $ignoreExitCodeMatch = $true }
								}
							}
							#  Or always ignore exit codes
							If ($ContinueOnError) { $ignoreExitCodeMatch = $true }
							
							## If the passthru switch is specified, return the exit code and any output from process
							If ($PassThru) {
								Write-Log -Message "Execution completed with exit code [$returnCode]." -Source ${CmdletName}
								[psobject]$ExecutionResults = New-Object -TypeName PSObject -Property @{ ExitCode = $returnCode; StdOut = $stdOut; StdErr = $stdErr }
								Write-Output $ExecutionResults
							} ElseIf ($ignoreExitCodeMatch) {
								Write-Log -Message "Execution complete and the exit code [$returncode] is being ignored." -Source ${CmdletName}
							} ElseIf (($returnCode -eq 3010) -or ($returnCode -eq 1641)) {
								Write-Log -Message "Execution completed successfully with exit code [$returnCode]. A reboot is required." -Severity 2 -Source ${CmdletName}
								Set-Variable -Name msiRebootDetected -Value $true -Scope Script
							} ElseIf (($returnCode -eq 1605) -and ($Path -match 'msiexec')) {
								Write-Log -Message "Execution failed with exit code [$returnCode] because the product is not currently installed." -Severity 3 -Source ${CmdletName}
							} ElseIf (($returnCode -eq -2145124329) -and ($Path -match 'wusa')) {
								Write-Log -Message "Execution failed with exit code [$returnCode] because the Windows Update is not applicable to this system." -Severity 3 -Source ${CmdletName}
							} ElseIf (($returnCode -eq 17025) -and ($Path -match 'fullfile')) {
								Write-Log -Message "Execution failed with exit code [$returnCode] because the Office Update is not applicable to this system." -Severity 3 -Source ${CmdletName}
							} ElseIf ($returnCode -eq 0) {
								Write-Log -Message "Execution completed successfully with exit code [$returnCode]." -Source ${CmdletName}
							} Else {
								[string]$MsiExitCodeMessage = ''
								If ($Path -match 'msiexec') {
									[string]$MsiExitCodeMessage = Get-MsiExitCodeMessage -MsiExitCode $returnCode
								}
								
								If ($MsiExitCodeMessage) {
									Write-Log -Message "Execution failed with exit code [$returnCode]: $MsiExitCodeMessage" -Severity 3 -Source ${CmdletName}
								} Else {
									Write-Log -Message "Execution failed with exit code [$returnCode]." -Severity 3 -Source ${CmdletName}
								}
								Exit-Script -ExitCode $returnCode
							}
						}
					} Catch {
						If ([string]::IsNullOrEmpty([string]$returnCode)) {
							[int32]$returnCode = 60002
							Write-Log -Message "Function failed, setting exit code to [$returnCode]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
						} Else {
							Write-Log -Message "Execution completed with exit code [$returnCode]. Function failed. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
						}
						If ($PassThru) {
							[psobject]$ExecutionResults = New-Object -TypeName PSObject -Property @{ ExitCode = $returnCode; StdOut = If ($stdOut) { $stdOut } Else { '' }; StdErr = If ($stdErr) { $stdErr } Else { '' } }
							Write-Output $ExecutionResults
						} Else {
							Exit-Script -ExitCode $returnCode
						}
					}
				}
				End {
					Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
				}
			}
			#endregion
			
			## Add the custom types required for the toolkit
			#If (-not ([Management.Automation.PSTypeName]'PSADT.UiAutomation').Type) {
			#	[string[]]$ReferencedAssemblies = 'System.Drawing', 'System.Windows.Forms', 'System.DirectoryServices'
			#	Add-Type -Path $appDeployCustomTypesSourceCode -ReferencedAssemblies $ReferencedAssemblies -IgnoreWarnings -ErrorAction 'Stop'
			#}
			
			## Define ScriptBlocks to disable/revert script logging
			[scriptblock]$DisableScriptLogging = { $OldDisableLoggingValue = $DisableLogging; $DisableLogging = $true }
			[scriptblock]$RevertScriptLogging = { $DisableLogging = $OldDisableLoggingValue }
			
			if ($DisableLogging) {
				## Disable logging until log file details are available
				. $DisableScriptLogging
			}
			
			## Define ScriptBlock for getting details for all logged on users
			[scriptblock]$GetLoggedOnUserDetails = {
				[psobject[]]$LoggedOnUserSessions = Get-LoggedOnUser
				[string[]]$usersLoggedOn = $LoggedOnUserSessions | ForEach-Object { $_.NTAccount }
				
				If ($usersLoggedOn) {
					#  Get account and session details for the logged on user session that the current process is running under. Note that the account used to execute the current process may be different than the account that is logged into the session (i.e. you can use "RunAs" to launch with different credentials when logged into an account).
					[psobject]$CurrentLoggedOnUserSession = $LoggedOnUserSessions | Where-Object { $_.IsCurrentSession }
					
					#  Get account and session details for the account running as the console user (user with control of the physical monitor, keyboard, and mouse)
					[psobject]$CurrentConsoleUserSession = $LoggedOnUserSessions | Where-Object { $_.IsConsoleSession }
					
					## Determine the account that will be used to execute commands in the user session when toolkit is running under the SYSTEM account
					#  If a console user exists, then that will be the active user session.
					#  If no console user exists but users are logged in, such as on terminal servers, then the first logged-in non-console user that is either 'Active' or 'Connected' is the active user.
					[psobject]$RunAsActiveUser = $LoggedOnUserSessions | Where-Object { $_.IsActiveUserSession }
				}
			}
			
			. $GetLoggedOnUserDetails
			
			
			$lastInput_Script = {
				Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {

    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@
				
				$Last = [PInvoke.Win32.UserInput]::LastInput
				$Idle = [PInvoke.Win32.UserInput]::IdleTime
				$LastStr = $Last.ToLocalTime().ToString('MM/dd/yyyy hh:mm tt')
				$lPath = 'C:\TempLogs\' + $env:COMPUTERNAME + '.log'
				$null = New-Item -Path $lPath -Force
				#Write-Output ('Current User: ' + $env:USERNAME)
				#Write-Output ('Last user keyboard/mouse input: ' + $LastStr)
				#Write-Output ('Idle for: ' + [PInvoke.Win32.UserInput]::IdleTime)

				Write-Output ('Current User - ' + $env:USERNAME) | Out-File -FilePath $lPath -Append
				Write-Output ('Last user keyboard/mouse input - ' + $LastStr) | Out-File -FilePath $lPath -Append
				Write-Output ('Idle for - ' + $Idle.Days + ' days, ' + $Idle.Hours + ' hours, ' + $Idle.Minutes + ' minutes, ' + $Idle.Seconds + ' seconds.') | Out-File -FilePath $lPath -Append
				Write-Output ('Idle for - ' + [PInvoke.Win32.UserInput]::IdleTime) | Out-File -FilePath $lPath -Append
				
				
			}
			
			#$strCommand = $lastInput_Script.ToString().replace("`r","`" &vbNewLine _")
			#$strCommand = $strCommand.Replace("`n","`n&`"")
			
			$bytes = [System.Text.Encoding]::Unicode.GetBytes($lastInput_Script)
			$encodedcommand = [System.Convert]::ToBase64String($bytes)
			
			$lPath = 'C:\TempLogs\' + $env:COMPUTERNAME + '.log'
			
			Execute-ProcessAsUser -Path "powershell.exe" -Parameters "-encodedcommand $encodedcommand" -Wait
			
			$strResult = Get-Content -Path $lPath
            $strUserName = ($strResult[0].Split("-"))[1].Trim()
            $strLastInput = ($strResult[1].Split("-"))[1].Trim()
            $strIdleTime = ($strResult[2].Split("-"))[1].Trim()

            $objLastInput = [datetime]$strLastInput

            $objIdleTime = [PSCustomObject]@{
                IdleTimeString = $strIdleTime
                IdleTime = ((Get-Date) - $objLastInput)
            }

            $objUser = New-Object System.Security.Principal.NTAccount("$strUserName")
            $strSID = ($objUser.Translate([System.Security.Principal.SecurityIdentifier]).Value)
            $objSID = New-Object System.Security.Principal.SecurityIdentifier("$strSID")
            $objDomainUser = $objSID.Translate([ System.Security.Principal.NTAccount])

            $objResult = [PSCustomObject]@{
                User = $objDomainUser
                SID = $objSID
                LastInput = $objLastInput | Get-Date -Format G
                IdleTimeString = $objIdleTime.IdleTimeString
                IdleTime = $objIdleTime
                LoggedOnUserInfo = Get-LoggedOnUser
            }

            Write-Output $objResult
		}

        foreach($Computer in $ComputerName) {
            Write-Host "Working on $Computer"
            if(Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
                if(Get-User -ComputerName $Computer) {
                    if($PSBoundParameters.ContainsValue("Credential")) {
		                Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -Credential $Credential -ArgumentList @($DisableLogging,$WriteHost)
                    } else {
		                Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList @($DisableLogging,$WriteHost)
                    }
                    $null = Remove-Item -Path "\\$Computer\c$\ToolkitTemp" -Recurse -Force -ErrorAction SilentlyContinue
                    $null = Remove-Item -Path "\\$Computer\c$\TempLogs" -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    Write-Error "$Computer has no logged on users."
                }
            } else {
                Write-Error "$Computer failed to respond to ping."
            }
        }
	}

	end { }

}
