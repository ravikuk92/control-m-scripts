function Join-String (
[string[]] $list,
[string] $separator = ' ',
[switch] $Collapse
)
{ 
    [string] $string = ''
    $first = $true
    # if called with a list parameter, rather than in a pipeline...
    if ( $list.count -ne 0 ) {
        $input = $list
    }
    foreach ( $element in $input ) {
        #Skip blank elements if -Collapse is specified
        if ( $Collapse -and [string]::IsNullOrEmpty ( $element) ) {
            continue
        }
        if ($first) {
            $string = $element
            $first = $false
        } else {
            $string += $separator + $element
        }
    }
    write-output $string
}

$confRegArray = Get-ChildItem -Path "HKLM:\SOFTWARE\BMC Software\" -Recurse -ErrorAction Ignore | Where-Object { $_.Name -like "*\CONFIG" } | %{ $_.PSPath } | %{ $_.ToString().split(":")[-1] } | %{ $_.replace('HKEY_LOCAL_MACHINE', 'HKLM:') }
Write-Output "Contents of confRegArray:"
$confRegArray | ForEach-Object { Write-Output $_ }

if ( $confRegArray.count -eq 1 ) {
    $VHKLM = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore }
    if ( !$VHKLM ) {
        $confRegArray = $confRegArray | %{ $_.replace('HKLM:', 'Registry::HKEY_LOCAL_MACHINE') }
    }
}

$agDir = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.AGENT_DIR}
$agFDVer = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.FD_NUMBER}
$agFXVer = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.FIX_NUMBER}
$agctmHst = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.CTMHOST}
$agSSL = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.COMMOPT}
$agsrvport = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.AGCMNDATA}
$srvagport = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.ATCMNDATA}
$agPersistent = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.PERSISTENT_CONNECTION}
$agProtocol = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.PROTOCOL_VERSION}

# New parameter collection added
$JavaAR = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.JAVA_AR}
$agLogicalName = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.LOGICAL_AGENT_NAME}
$JavaSrc = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.AG_JAVA_HOME}
$agJavaSrc = (Get-Item $JavaSrc).Target
$agJavapath = "$agJavaSrc\release"
$agJavaVersion = (Get-Content -Path $agJavapath | Where-Object { $_ -match "JAVA_VERSION" } | Select-Object -First 1 | ForEach-Object { ($_ -split '"')[1] })
$agNumber = (%{ ($agDir -match "ctmag.*") | Out-Null; $Matches[1] }).Trim('\')
$agStartType = (Get-CimInstance -ClassName Win32_Service -Filter "Name = 'ctmag_$agNumber'").StartMode
$cmlist = %{ Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore } | %{$_.CMLIST}
$cmlist = $cmlist -replace '\|', ':'
$PACOBname = %{ Select-String -Pattern "РАСОВ" $(Join-Path -Path "$agDir" -ChildPath "installed-versions.txt") -ErrorAction Ignore } | %{$_.Line}
$DRCOBname = %{ Select-String -Pattern "DRCOB" $(Join-Path -Path "$agDir" -ChildPath "installed-versions.txt") -ErrorAction Ignore } | %{$_.Line}

# Read installed versions
$moduleVersions = @{}
$moduleInstallDate = @{}
$installedVersionsFile = Join-Path -Path $agDir -ChildPath "installed-versions.txt"
Write-Output "Path to installed-versions.txt: $installedVersionsFile"

if (Test-Path $installedVersionsFile) {
    Write-Output "Contents of installed-versions.txt:"
    Get-Content $installedVersionsFile | ForEach-Object { Write-Output $_ }

    Get-Content $installedVersionsFile | ForEach-Object {
        $line = $_.Trim()
        if ($line) {
            $parts = $line -split '\s+'
            if ($parts.Length -ge 7) {
                $module = $parts[0]
                $installDate = [datetime]::ParseExact($parts[4], "MMM-dd-yyyy", $null)
                $version = $parts[5]
                Write-Output "Processing module: $module, version: $version, install date: $installDate"
                $moduleKey = $module.Substring(2)
                if ($moduleKey -match '^[A-Z0-9\.]+$') {
                    Write-Output "Validation passed for module: $moduleKey, version: $version"
                    if (-not $moduleInstallDate[$moduleKey] -or $installDate -gt $moduleInstallDate[$moduleKey]) {
                        $moduleVersions[$moduleKey] = "$module ($parts[4]): $version"
                        $moduleInstallDate[$moduleKey] = $installDate
                    }
                } else {
                    Write-Output "Skipping invalid entry: $line"
                }
            } else {
                Write-Output "Skipping invalid line: $line"
            }
        }
    }
}

$moduleVersionsOutput = ""
foreach ($moduleKey in $moduleVersions.Keys) {
    $moduleVersionsOutput += "$($moduleVersions[$moduleKey]), "
}

# Ping information
$unixPing = "OK"
$agPing = "OK"
if ($unixPing -lt 1) {
    $unixPing = "NOTOK"
}
if ($agPing -lt 1) {
    $agPing = "NOTOK"
}

$previousDay = (Get-Date).AddDays(-1).ToString("yyyyMMdd")
$logFile = Join-Path -Path $agDir -ChildPath "ctm/dailylog/diag_ctmag_$previousDay.log"
if (Test-Path $logFile) {
    $pingInfo = Get-Content $logFile | Select-String -Pattern "EXECUTION ENDED" | Select-Object -Last 1
    $pingFrom = ($pingInfo -split "FROM CONTROL-M SERVER:")[1] -split " " | Select-Object -First 1
    $pingTo = ($pingInfo -split "TO LOCAL AGENT:")[1] -split " " | Select-Object -First 1
    $ctmPing = "$pingDateTime:$pingFrom:$pingTo"
} else {
    $taskExecutedCount = "null"
    $ctmPing = "NoPingfromCTM"
}

# Output results
Write-Output "$agDir: Version=$agFXVer, CTMSRV=$agctmHst, AG2SRV=$agProtocol"
Write-Output "$agDir: Persistent=$agPersistent, Mode=$agMode, SSL=$agSSL, Protocol=$agProtocol"
Write-Output "$agDir: JavaSource=$agJavaSrc, Java=$agJavaVersion, LogicalName=$agLogicalName"
Write-Output "$agDir: ctm_agent_status=$ctmAgentStatus, TasksExecuted=$taskExecutedCount"
Write-Output "$agDir: InstalledVersions=${moduleVersionsOutput.TrimEnd(', ')}, unixPing=$unixPing, agPing=$agPing"

if ($PACOBname -ne "" -or $DRCOBname -ne "" -or $PAPMCname -ne "" -or $DRPMCname -ne "") {
    Write-Output "$agDir, $PACOBname, $DRCOBname, $PAPMCname, $DRPMCname"
}
if ($PACBDname -ne "" -or $DRCBDname -ne "" -or $PAMQLname -ne "" -or $DRMQLname -ne "") {
    Write-Output "$agDir, $PACBDname, $DRCBDname, $PAMQLname, $DRMQLname"
}
if ($PAAFPname -ne "" -or $DRAFPname -ne "") {
    Write-Output "$agDir, $PAAFPname, $DRAFPname"
} else {
    exit 1
}

exit 0
