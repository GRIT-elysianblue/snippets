# Get Temp Directory for Current User Environment and Create Triage Dir
$temp = $env:TEMP 
New-Item -Path $temp -Name "GPS_Triage" -ItemType "directory"

#Get Hostname
$hostname = $env:COMPUTERNAME

# Get Current Volume Drive Name
$drive = $pwd.Drive.Name

# Download and Install PowerForensics


$n = Get-PackageProvider -name NuGet

if ($n.version.major -lt 2) {
    if ($n.version.minor -lt 8) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force 
    }
}

if (-NOT (Get-Module -ListAvailable -Name PowerForensics)) {
    Write-Host "[-] Installing PowerForensics"
    Install-Module -name PowerForensics -Scope CurrentUser -Force
} else {
    Write-Host "[+] PowerForensics Already Installed. Continuing."
}

# 1 Acquire NTFS Master File Table via Get-ForensicFileRecord to Snapshot Filesystem Before Any Other Action

$mft_csv = $temp_dir + "\" + $hostname + "-" + $drive + "-" + "\mft.csv"

Get-ForensicFileRecord |Export-Csv -NoTypeInformation -Path $mft_csv -Force 

# Copy System-Level Registry Hives

$hives = @("C:\Windows\System32\config\SYSTEM", "C:\Windows\System32\config\SOFTWARE", "C:\Windows\AppCompat\Programs\Amcache.hve", "C:\Windows\System32\config\SAM")

foreach ($hive in $hives) {
    $hname = $hive.Split("\")
    Write-Host "[-] Acquiring $hname[4] Registry Hive from $hive"
    Copy-ForensicFile -Path $hive -Destination $temp_dir\$hostname-$hname[4]
    Write-Host "[+] Registry Hive $hname[4] Copied to $temp_dir\$hostname-$hname[4]"
}

# Get User Directories

$user_dirs = Get-ChildItem -Path C:\Users

foreach ($user in $user_dirs) {
    Write-Host "[-] Acquiring User Registry Hives NTUSER.DAT and USRCLASS.DAT for User $user"
    Copy-ForensicFile -Path C:\Users\$user\NTUSER.DAT -Destination $temp_dir\$hostname-$user-NTUSER.DAT 
    Write-Host "[+] NTUSER.DAT User Registry for User $user Acquired."
    Copy-ForensicFile -Path C:\Users\$user\AppData\Local\Microsoft\Windows\USRCLASS.DAT -Destination $temp_dir\$hostname-$user-USRCLASS.DAT 
    Write-Host "[+] USRCLASS.DAT User Registry for User $user Acquired."
}

# Get Windows Prefetch

$prefetch = Get-ChildItem C:\Windows\Prefetch 

foreach ($pf in $prefetch) {
    Write-Host "[-] Acquiring Windows Prefetch Files"
    Copy-ForensicFile -Path C:\Windows\Prefetch\$pf -Destination $temp_dir\$hostname-$pf 
    
}
Write-Host "[+] Windows Prefetch Files Acquired"

# Get Critical Event Logs

$event_logs = Get-ChildItem C:\Windows\System32\winevt\Logs 

foreach ($evtx in $event_logs) {
    if ($evtx -Match "PowerShell") {
        Write-Host "[-] Acquiring Event Log $evtx"
        Copy-ForensicFile -Path C:\Windows\System32\winevt\Logs\$evtx -Destination $temp_dir\$hostname-$evtx 
        Write-Host "[+] Event Log $evtx Acquired."
    } elseif ($evtx -Match "Security") {
        Write-Host "[-] Acquiring Event Log $evtx"
        Copy-ForensicFile -Path C:\Windows\System32\winevt\Logs\$evtx -Destination $temp_dir\$hostname-$evtx 
        Write-Host "[+] Event Log $evtx Acquired."
    } elseif ($evtx -Match "System") {
        Write-Host "[-] Acquiring Event Log $evtx"
        Copy-ForensicFile -Path C:\Windows\System32\winevt\Logs\$evtx -Destination $temp_dir\$hostname-$evtx 
        Write-Host "[+] Event Log $evtx Acquired."
    } elseif ($evtx -Match "Application") {
        Write-Host "[-] Acquiring Event Log $evtx"
        Copy-ForensicFile -Path C:\Windows\System32\winevt\Logs\$evtx -Destination $temp_dir\$hostname-$evtx 
        Write-Host "[+] Event Log $evtx Acquired."
    } elseif ($evtx -Match "Terminal") {
        Write-Host "[-] Acquiring Event Log $evtx"
        Copy-ForensicFile -Path C:\Windows\System32\winevt\Logs\$evtx -Destination $temp_dir\$hostname-$evtx 
        Write-Host "[+] Event Log $evtx Acquired."
    }
}

# Get Web Histories


foreach ($user in $user_dirs) {
    $webcache = Get-ChildItem C:\Users\$user\AppData\Local\Microsoft\Windows\WebCache\WebCacheV*.dat 
    foreach ($dat in $webcache) {
        $dat_file = $dat.PSChildName
        Write-Host "[-] Acquiring File $dat"
        Copy-ForensicFile -Path $dat -Destination $temp_dir\$hostname-$dat_file 
        Write-Host "[+] File $dat Acquired."
    }
    
    if (Test-Path C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles) {
        $ff_hist = Get-ChildItem C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.sqlite
        foreach ($hist in $ff_hist) {
            $hist_file = $hist.PSChildName
            Write-Host "[-] Acquiring File $hist"
            Copy-ForensicFile -Path $hist -Destination $temp_dir\$hostname-$hist_file 
            Write-Host "[+] File $hist Acquired."
        }
    } else {
        Write-Host "Firefox not found on host."
    }
    
    if (Test-Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\History"){
        $chrome_hist = Get-ChildItem "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\History"
        foreach ($chist in $chrome_hist) {
            $chist_file = $chist.PSChildName
            Write-Host "[-] Acquiring File $chist"
            Copy-ForensicFile -Path $chist -Destination $temp_dir\$hostname-$chist_file
            Write-Host "[+] File $chist Acquired."
        }
    } else {
        Write-Host "Chrome not found on host."
    }
}

# Get USB History
 if (Test-Path "C:\Windows\inf\setupapi.dev.log"){ 
     Write-Host "[-] Acquiring USB History file C:\Windows\inf\setupapi.dev.log"
     Copy-ForensicFile -Path C:\Windows\inf\setupapi.dev.log -Destination $temp_dir\$hostname-setupapi.dev.log 
     Write-Host "[+] USB History File Acquired."
 }

 # Archive Triage Acquisitions for Submission to GPS DFIR
 
 Get-ChildItem $temp_dir |Compress-Archive -DestinationPath $temp\GPS_Triage.zip 

 if (Test-Path "$temp\GPS_Triage.zip"){
     Rename-Item -Path "$temp\GPS_Triage.zip" -NewName "$hostname-GPS_Triage.zip"
     Write-Host "Triage Archive $temp\$hostname-GPS_Triage.zip Created Successfully.  Please Upload $temp\$hostname-GPS_Triage.zip to Location Designated by your GPS DFIR Analyst."
 } else {
     Write-Host "Triage Archive $temp\$hostname-GPS_Triage.zip Not Created.  Please Contact Your GPS DFIR Analyst and Submit GPS_log.txt for review."
 } 