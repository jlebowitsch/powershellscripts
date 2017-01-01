
<#


.SYNOPSIS
This Powershell Script adds hosts to the SmartCenter database.

.DESCRIPTION
This script adds a single host to SmartCenter. Unless the user enters the parameters to the call itself,  it prompts the user to add a host name and host IP address. 
The script first tries to use shell objects to send a keepalive to the management server. 
If that fails, the CPAPI-Authenticate is invoked and the user is prompted to enter his credentials and the smartcenter details. 
If NAT settings need to be added, use them as parameters in the command line themselves (try typing "-" after the script name. 
you'll need to add "true" to NATSettings and then all the required information)

.EXAMPLE
PS C:\Users\lebowits\Documents\GitHub\powershellscripts> .\CPAPI-Add-Host.ps1 -hostname NewHost -hostIPaddress 10.10.10.10 -NATSettings TRUE -autorule TRUE -Method hide -HideBehind gateway -Installon MyGateway

.NOTES
Some options of the Add-host API are not implemented in this script!


.LINK
https://github.com/jlebowitsch/powershellscripts
https://sc1.checkpoint.com/documents/R80/APIs/?#cli/add-host


#>

param(

	[Parameter(Mandatory=$true, HelpMessage="New Host Name")]
     [String]$hostname,
	
     [Parameter(Mandatory=$true, HelpMessage="New Host IP Address")]
     [String]$hostIPaddress,
	
     [Parameter(Mandatory=$false, HelpMessage="define NAT?")][Validateset("TRUE", "FALSE")]
     [String]$NATSettings,
	
     [Parameter(Mandatory=$false, HelpMessage="Whether to add automatic address translation rule")][Validateset("TRUE", "FALSE")]
     [String]$autorule,
	 
    [Parameter(Mandatory=$false)]
     [String]$NATIPv4Address,
	 
    [Parameter(Mandatory=$false)]
     [String]$NATIPv6Address,
	 
    [Parameter(Mandatory=$false)][Validateset("gateway", "ip-address")]
     [String]$HideBehind,
	  
    [Parameter(Mandatory=$false)]
     [String]$Installon,
	
    [Parameter(Mandatory=$false)][Validateset("hide", "static")]
     [String]$Method

)


# do a sanity check to see that the user is logged in. If not call the login script


try {
    $mykeepaliveURI="https://${myCPSmartCenterIPAddress}/web_api/keepalive"
    $myemptyjson=@{} | convertto-json -compress
    $keepalive=Invoke-WebRequest -uri $mykeepaliveURI -ContentType application/json -Method POST -headers $myCPHeader -body $myemptyjson -ErrorAction Stop
    }

   catch  {
        $keepalive = $_.Exception.Response
        & ((Split-Path $MyInvocation.InvocationName) + "\CPAPI-Authenticate.ps1")

    }
  
    

# create a request body
$mybodyhost=@{name=$hostname;"ip-address"=$hostIPaddress} 
if ($NATSettings -eq "TRUE")
	{$nat=@{}
	if ($autorule.length -gt 0){$nat.add("auto-rule",$autorule)}
	if ($NATIPv4Address.length -gt 0){$nat.add("ipv4-address",$NATIPv4Address)}
	if ($NATIPv6Address.length -gt 0){$nat.add("ipv6-address",$NATIPv6Address)}
	if ($HideBehind.length -gt 0){$nat.add("hide-behind",$HideBehind)}
	if ($Installon.length -gt 0){$nat.add("install-on",$Installon)}
	if ($Method.length -gt 0){$nat.add("method",$Method)}
	# $natjason=$nat | convertto-json -compress
	$mybodyhost.add("nat-settings", $nat)
	}
	
$mybodyjson=$mybodyhost | convertto-json -compress

#create the add host uri
$AddHostURI="https://${myCPSmartCenterIPAddress}/web_api/add-host"

#allow self signed certs
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

# add host to server

$myaddhostresponse=Invoke-WebRequest -uri $AddHostURI -ContentType application/json -Method POST -headers $myCPHeader -body $mybodyjson

# publish

$mypublishURI="https://${myCPSmartCenterIPAddress}/web_api/publish"
$mypublishbodyjson=@{} | convertto-json -compress

$mypublishresponse=Invoke-WebRequest -uri $mypublishURI -ContentType application/json -Method POST -headers $myCPHeader -body $mypublishbodyjson

#show happy ending
if ($mypublishresponse.statuscode -eq 200){"Script completed. Host was added"}