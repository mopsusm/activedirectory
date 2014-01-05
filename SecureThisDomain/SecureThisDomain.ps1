# PreRequisites
#	1. User running the script must be a Domain Admin
#	2. ActiveDirectory and GroupPolicy modules must be available from RSAT. http://www.microsoft.com/en-us/download/details.aspx?id=7887
#	3. Machine running the script must be a domain member.


############### GLOBAL VARS ###############

#Current User Name
$struser = $env:USERNAME

#Current Domain Name
$strdomain = $env:USERDOMAIN

#Current Domain Object
$domain = $null

#Current User Object
$currentuser = $null

# XML based list of domain GPOs
$gpos = $null

############### SUPPORTING FUNCTIONS ###############

# Load a module if it's available
Function Get-MyModule { 
	Param([string]$name) 
	if(-not(Get-Module -name $name)) 
	{ 
		if(Get-Module -ListAvailable | 
		Where-Object { $_.name -eq $name }) 
		{ 
			Import-Module -Name $name 
			$true 
		}  
		else { $false } 
		}	 
	else { $true }
}

# Write messages to console
Function Write-Message {
	Param(	[string] $message,
			[string] $type)
	switch ($type) {
		"error" {Write-Host "[!] - $message" -ForegroundColor Red}
		"warning" {Write-Host "[!] - $message" -ForegroundColor Yellow}
		"debug" {$Host.UI.WriteDebugLine($message)}
		"success" {Write-Host "[+] - $message" -ForegroundColor Green}
		"prereq" {Write-Host "[+] - PREREQ CHECK: $message" -ForegroundColor Blue}
		default {Write-Host $message}
	}
}

# Perform Prereq checks and load modules
Function DoPreReqs {
	# Load AD Module
	if ((Get-MyModule -name "ActiveDirectory") -eq $false) {
		Write-Message "ActiveDirectory module not available. Please load the Remote Server Administration Tools from Microsoft." "error"
		exit
	} else {Write-Message "ActiveDirectory module successfully loaded." "prereq"}

	#Load GPO Module
	if ((Get-MyModule -name "GroupPolicy") -eq $false) {
		Write-Message "GroupPolicy module not available. Please load the Remote Server Administration Tools from Microsoft." "error"
		exit
	} else {Write-Message "GroupPolicy module successfully loaded." "prereq"}

	# Check if machine is on a domain
	if ([string]::IsNullOrEmpty($env:USERDOMAIN)) {
		Write-Message "Bad news. Looks like this machine is not a member of a domain. Please run from a member server or workstation, or a domain controller" "error"
		exit
	} else { Write-Message "Machine is member of $strdomain domain." "prereq" }

	$global:domain = Get-ADDomain $strdomain
	$global:currentuser = Get-ADUser $struser -Properties memberOf

	#Domain Admin Check
	if ($currentuser.MemberOf | Select-String "CN=Domain Admins") {
		Write-Message "Current user is a Domain Admin." "prereq"
	} else { 
		Write-Message "Bad news. The user running this script must be a Domain Admin. Exiting.." "error"
		exit
	}
	
	# Export all gpo settings to xml
	try {
		$global:gpos = Get-GPOReport -All -ReportType Xml
		Write-Message "Successfully exported GPOs from domain $strdomain" "prereq"
	} catch [Exception] {
		$err = $_.Exception.Message
		Write-Message "Failed to export GPOs from domain $strdomain. Error: $err. Exiting..." "error"
		exit
	}
}
############### MAIN SCRIPT BLOCK ###############

DoPreReqs

