#!/usr/bin/env pwsh
# ##############################################################################
#
#                  Dgraph Installer Script for Windows
#
#   Homepage: https://dgraph.io
#   Requires: Powershell
#
#   Hello! This is a script that installs Dgraph
#   into your PATH (which may require to run as Administrator).
#   Use it like this:
#
#	$ iwr https://get.dgraph.io/install.ps1 -useb | iex
#
# This should work on windows.
# ##############################################################################

param(
	[uri]$base_server_uri = "https://dgraph.io", #origin_uri
	[uri]$URL = "https://get.dgraph.io/latest",
	[uri]$TAGsURI = "https://api.github.com/repos/dgraph-io/dgraph/releases/tags",
	[string]$checksum_file = "dgraph-checksum-windows-amd64.sha256",
	[uri]$releasesURI = "https://github.com/dgraph-io/dgraph/releases/download",
	[switch]$IsRunAsAdmin = $false,
	$ErrorActionPreference = "Stop",
	[string]$Agree = "N",
	[string]$setPath = "C:\",
	$TEMPpath = "$env:TEMP",
	[string]$dgraphIO = "dgraph-io",
	[string]$Version = $Version,
	[string]$acceptLicense = $acceptLicense,
	$ProgressPreference
)

#Requires -Version 7

# Disable Invoke-WebRequest progress bar to speed up download due to bug
$ProgressPreference = "SilentlyContinue"

# GitHub requires TLS 1.2 - This is here for the sake of concern.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$currentAdm = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$currentAdm = $currentAdm.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$ROOTPath = "$setPath$dgraphIO"
$ExecPolicy = (Get-ExecutionPolicy)

function Invoke-Download {
	param(
		[string] $URL_,
		[string] $OutFile,
        [int] $Retries = 20
	)
	while ($Retries -gt 0){
        try{
			if ($OutFile) {
				Invoke-WebRequest -Uri $URL_ -UseBasicParsing -ErrorAction:Stop -TimeoutSec 180 -OutFile $OutFile
			 } else {
				Invoke-WebRequest -Uri $URL_ -UseBasicParsing -ErrorAction:Stop -TimeoutSec 180
			}
            break
		}
		catch {
            Write-Host "There is an error during download:`n $_"
            $Retries--

            if ($Retries -eq 0) {
                Write-Host "File can't be downloaded. url: $_URL"
                exit 1
            }

            Write-Host "Waiting 11 seconds before retrying. Retries left: $Retries"
            Start-Sleep -Seconds 11
		}
	}
}

$latest_release = Invoke-Download $URL | ConvertFrom-Json | Select-Object -Expand tag_name

function Invoke-Elevated ($scriptblock) {
	$_Pwsh = "$psHome\powershell.exe"
	if (-not (Test-Path -LiteralPath "$psHome\powershell.exe")) {
		$_Pwsh = "pwsh"
	}
	if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
		Start-Process "$_Pwsh" -Verb runAs -ArgumentList $scriptblock
	}
}

function Expand-Tar ($tarFile, $dest) {
	tar -xvzf $tarFile -C $dest
}
function Write-Good {
	param($Message,
		[ValidateSet("Progress", "Information")]
		[string]$Type = "Progress")

	[System.ConsoleColor]$color = [System.ConsoleColor]::Green
	switch ($Type) {
		"Information" {
			$color = [System.ConsoleColor]::Gray
		}
	}

	Write-Host -Object "INFO: $Message" -ForegroundColor $color
}

function Write-Error {
	param($Message,
		[ValidateSet("Progress", "Information")]
		[string]$Type = "Progress")

	[System.ConsoleColor]$color = [System.ConsoleColor]::Red
	switch ($Type) {
		"Information" {
			$color = [System.ConsoleColor]::Gray
		}
	}

	Write-Host -Object "ERROR: $Message" -ForegroundColor $color
}

if (($PSVersionTable.PSVersion.Major) -lt 7) {
    Write-Error "PowerShell 7 or later is required to run this Script."
    Write-Error "Upgrade PowerShell: https://www.google.com/search?q=upgrade+powershell"
    break
}

if ($ExecPolicy -ne "RemoteSigned") {
	Write-Error "This script needs to be executed with ExecutionPolicy set as RemoteSigned"
	Write-Error "please run (as Administrator):"
	Write-Error 'Set-ExecutionPolicy -ExecutionPolicy "RemoteSigned"'
	Write-Error "After run the script you can set it to `"-ExecutionPolicy Undefined`""
	break
}

if ((Test-Path -LiteralPath "$ROOTPath\dgraph.exe") -and !($Version)) {
	Write-Good "You already have Dgraph $Version installed."
	#!TODO Without Checksum I can't check the version easily.
	Write-Good "Please, if you wanna updgrade to $selectVersion use the version variable."
	$Version = "" #cleanup variable
	break
} elseif (-not (Test-Path -LiteralPath "$ROOTPath")) {
	Write-Good "Creating install path"
	New-Item -Force -Path "$setPath" -Name "$dgraphIO" -ItemType "directory"
}

###############################################################################
# Pre-steps - Define the Version
###############################################################################

if ($Version) {
	$global:selectVersion = $Version
	Write-Good "Version manually set: $Version"
	$Version = "" #cleanup variable
} else {
	$global:selectVersion = $latest_release
}

function Get-RGDitDetails {
	$RAW_CVer = REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName |
	ConvertTo-Json | ConvertFrom-Json

	$RAW_RLID =REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId |
	ConvertTo-Json | ConvertFrom-Json
	
	$RAW_OS = $RAW_CVer[2].Replace("REG_EXPAND_SZ","").Replace("REG_SZ","").Replace("ProductName","").replace('  ' , '')
	$RAW_RLID = $RAW_RLID[2].Replace("REG_EXPAND_SZ","").Replace("REG_SZ","").Replace("ReleaseId","").replace('  ' , '')

	return @"
INFO: :: OS: $RAW_OS
INFO: :: Build: $RAW_RLID
"@
}

function Get-License () {
	curl.exe -s https://raw.githubusercontent.com/dgraph-io/dgraph/master/licenses/DCL.txt

	$content = @"

By downloading Dgraph you agree to the Dgraph Community License (DCL) terms
shown above. An open source (Apache 2.0) version of Dgraph without any
DCL-licensed enterprise features is available by building from the Dgraph
source code. See the source installation instructions for more info:

https://github.com/dgraph-io/dgraph#install-from-source

"@
	return $content
}

function Get-Agree () {
	param(
		$Agree
	)
	if ($Agree -match "[yY]([eE][sS])?") {
		$script:Agree = "Y"
		Write-Good 'Dgraph Community License terms accepted with "-accept-license yes" option.'
	} else {
		$script:Agree = "NO"
	}
}
function check_license_agreement () {
	Get-License

	# Feels like powershell doesn't work well with copy paste ASCII art. So, let's use this instead. 
	Invoke-RestMethod https://artii.herokuapp.com/make?text=Dgraph

	Write-Host $dg_

	$Agree = Read-Host -Prompt "Do you agree to the terms of the Dgraph Community License? [Y/n]"
	Write-Host "You have signed '$Agree'"
	Get-Agree -Agree $Agree

}
function check_if_exists {
	try {
		$response = Invoke-Download "$TAGsURI/$selectVersion"
		$StatusCode = $Response.StatusCode
	} catch {
		$StatusCode = $_.Exception.Response.StatusCode.value__
		Write-Error "INTERNAL :: HTTP Status Code $StatusCode"
		Write-Error "This version doesn't exist or it is a typo (Tip: You need to add 'v' eg: v20.0.1-rc1)"
		break
	}
	if ($Response) {
		$toCompare = $Response | ConvertFrom-Json | Select-Object -Expand tag_name
		if ($toCompare -eq $latest_release) {
			Write-Good "Downloading latest release: $latest_release"
		}
		if ($toCompare -notmatch $latest_release) {
			Write-Good "Latest Dgraph is $latest_release"
			Write-Good "The version you choose to download is $toCompare Downloading..."
		}
	}

}

function Get-Raw-Env-Path () {
	$RAW_ = REG QUERY "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path |
	Select-String "Path" |
	ConvertTo-Json |
	ConvertFrom-Json  |
	Select-Object -Expand line
	
	$RAW = $RAW_.Replace("REG_EXPAND_SZ","").Replace("REG_SZ","").Replace("Path","").replace('  ' , '').split(";") | ConvertTo-Json |	ConvertFrom-Json
	
	$OutPut=""
	$count=0

	foreach ($key in $RAW) {
		if(($key) -and ($count -ne 0)) { $OutPut += ";$key" } else { $OutPut += "$key"}
		$count+=1
	  }

	return $OutPut
}

function Set-Script () {
	$content = @"
#!/usr/bin/env pwsh
SETX PATH /M "$RawEnvPath;;$ROOTPath"
"@

   Set-Content "$ROOTPath\setEnv.ps1" $content -en ASCII

}

###############################################################################
# Step - license
###############################################################################

if ($acceptLicense) { 
	Get-Agree -Agree $acceptLicense
	$acceptLicense = "" #cleanup variable
} else {
	check_license_agreement
	$acceptLicense = "" #cleanup variable
} 

if ($Agree -eq "NO") {
	Write-Error "You must agree to the license terms to install Dgraph."
	Write-Error "Installation failed. Please try again."
	Write-Host "Press any key to continue..."
	$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
	return
}

###############################################################################
# Step - Check if the version exists
###############################################################################

check_if_exists

###############################################################################
# Step - Checksum
###############################################################################
#!TODO NEED the hash from windows builds. That's wasn't found.

# $checksum_link = "$releasesURI/$selectVersion/$checksum_file"

# Write-Output "Downloading checksum file for $selectVersion build."

# Write-Output "checksum_link $checksum_link build."

# Invoke-Download -URL_ $checksum_link -OutFile $ROOTPath\$checksum_file

# $dgraphBinHash = Get-FileHash C:\dgraph-io\dgraph.exe | select -expand Hash

# Write-Good "dgraphBinHash = ====> $dgraphBinHash"

###############################################################################
# Step - Prepare the install and download Dgraph 
###############################################################################

# Is good to have this log - Users can send us error logs and we gonna know what OS they are running it.
Write-Host -ForegroundColor Green  (Get-RGDitDetails)

Write-Good "Downloading Dgraph wait..."

$dgraph_link = "$releasesURI/$selectVersion/dgraph-windows-amd64.tar.gz"

Invoke-Download -URL_ $dgraph_link -OutFile "$ROOTPath\dgraph-windows-amd64.tar.gz"

Write-Good "Extracting..."

Expand-Tar "$ROOTPath\dgraph-windows-amd64.tar.gz" "$ROOTPath\"

Write-Good "Installing"

$RawEnvPath = Get-Raw-Env-Path
$HasDgraphEnv = $RawEnvPath -Match "dgraph-io"

if ($currentAdm -and !($HasDgraphEnv) -and !($env:GITHUB_OS)) {
	SETX PATH /M "$RawEnvPath;$ROOTPath"
} elseif(!($currentAdm) -and !($HasDgraphEnv)) {
	Set-Script
	Invoke-Elevated  "$ROOTPath\setEnv.ps1"
}

$env:Path += ";$ROOTPath\" # This isnt permanent, just to make dgraph available right away.


###############################################################################
#cleanup variables and TMP
###############################################################################

$Version = ""
# Remove-Item -Path  "C:\dgraph-io" -Force -Recurse UNISTALL

Write-Good "All done, cheers!"
Write-Output "Dgraph was successfully installed"
Write-Output "Open a new terminal and run 'dgraph --help' to get started"
