[string[]] #list,
[string] $separator = '
[switch] $Collapse
{ [string] $string = ''
§first = $true
# if called with a list parameter, rather than in a pipeline...
if ( $list.count -ne 0 )
$input = $list
｝
foreach ( $element in $input )
1
#Skip blank elements if -Collapse is specified if ( $Collapse -and [string]::IsNullOrEmpty ( $element) )
1
continue
if ($first)
1
$string = $element
$first = $false
else
1
$string += $separator + $element
}
write-output string
}


$confRegArray=Get-ChildItem -Path "HKLM: \SOFTWARE\BMC Software\" -Recurse -ErrorAction Ignore| Where-Object {$_ name -like "*\CONFIG" }|
%{$_PSPath} |% $_. Tostring().split(":")[-1] }| %$_.replace('HKEY_LOCAL_MACHINE', 'HKLM: ')}
if ( $confRegArray.count -eq 1 )
$VHKLM=%{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore if ( !$VHKLM )
｝
$confRegArray=$confRegArray | %{$_. replace('HKLM:', 'Registry:: HKEY_LOCAL_MACHINE ')}
$agDir=%{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore} | %{$_. AGENT_DIR} $agFDVer=%{Get-ItemProperty -Path "$confRegArray"-ErrorAction Ignore} | %{$_. FD_NUMBER} $agFXVer=%{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore} | %{$_. FIX_NUMBER} $agctmHst=%{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore} | %{$_. CMSHOST}
$agSSL=%{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore} | %{$_. COMT}
$agsrvport=%{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore} | %{$_. AGCMNDATA}
$srvagport= %{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore} | %{$_. ATCMNDATA}
$agPersistent=%{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore} | %{$_. PERSISTENT_CONNECTION}
$agProtocol=%{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore} | %{$_. PROTOCOL_VERSION}
#new paramter collection added
$JavaAR=%{Get-ItemProperty -Path
"$confRegArray" -ErrorAction Ignore} | %{$_. JAVA_AR}
$agLogicalName=%{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore} | %{$_. LOGICAL_AGENT_NAME }
$JavaSrc=%{Get-ItemProperty -Path "$confRegArray" -ErrorAction Ignore} | %{$_. AG_JAVA_HOME }
$agJavaSrc = (Get-Item $JavaSrc).Target
$agJavapath= "$agJavaSrc\release"
$agJavaVersion=(Get-Content -Path $agJavapath | where-Object { $_ -match "JAVA_VERSION"} | Select-Object -First 1 | ForEach-Object { ($_ -spli $agNumber= (%{($agDir -match "ctmag.*") | Out-Null ; Matches[®] }) Trim('\')
$agStartType = (Get-CimInstance -ClassName Win32_Service -Filter "Name = 'ctmag_$agNumber'"). StartMode
#$cmlist = %{Get-ItemProperty -Path $confRegArray -ErrorAction Ignore | %{$_. CMLIST}}
$PACOBname=%{select-string -pattern "РАСОВ" $(Join-Path -Path "$agDir" -ChildPath "installed-versions.txt") -ErrorAction Ignore} | %{$_. Line. sp.
$DRCOBname=%{select-string -pattern "DRCOB" $(Join-Path -Path "$agDir" -ChildPath "installed-versions.txt") -ErrorAction 

write-output "$agDir, $agFDVer, 'CTMSRV= $agctmHst, 'AG2SRV= *$agsrvport, 'SRV2AG='$srvagport"
自證
"$agDir" -ChildPath "installed-versions.txt") -ErrorAction Ignore}
%{$_. Li
"$agDir" -ChildPath "installed-versions.txt") -ErrorAction Ignore}
%{$_.Li
"$agDir" -ChildPath "installed-versions.txt") -ErrorAction Ignore}
| %{$_.Li
"PAAFP" $(Join-Path -Path "$agDir" -ChildPath "installed-versions.txt") -ErrorAction Ignore}
| %{$_.Li
write-output
'Persistent='$agPersistent, $agFXVer,$agSSL, 'Protoco1='$agProtocol"
write-output
"$agDir, 'JavaSource='$agJavaSrc, 'JavaVersion='$agJavaVersion, 'LogicalName'=$agLogicalName, 'AgentStatus='$agStartType"
Write-Output "$agDir, 'Java_AR=*$JavaAR" #Write-Output "$agDir, 'CMLIST='$cmlist"
if ( $PACOBname -ne "" -or $DRCOBname -ne "" -or $PAPMCname-ne "" -or $DRPMCname -ne "" )
{
write-output "$agDir, $PACOBname, $DRCOBname, $PAPMCname, $DRPMCname"
}
{
if ( $PACBDname -ne "" -or $DRCBDname -ne "" -or $PAMQLname -ne "" -or $DRMQLname -ne "" )
Write-output "$agDir, $PACBDname, $DRCBDname, $PAMQLname, $DRMQLname"
}
{
if ( $PAAFPname -ne "" -or $DRAFPname -ne "" )
write-output "$agDir, $PAAFPname, $DRAFPname"
elseif ( $confRegArray.count -gt 1 )
for ( Sindex = 0; $index -It $confRegArray.count; $index++)
$VHKLM=%{Get-ItemProperty -Path $confRegArray[$index] -ErrorAction Ignore }
if ( !$HKLM )
{
Ln