# This script adds a single host to SmartCenter. It prompts the user to add a host name and host IP address. 
# If nat settings need to be added, use them as parameters in the command line themselves (try typing "-" after the script name. 
# you'll need to add true to NATSettings and then all the required information)

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

if(($myCPHeader.length -lt 1) -OR ($myCPSmartCenterIPAddress.length -lt 1)){& ((Split-Path $MyInvocation.InvocationName) + "\CPAPI-Authenticate.ps1")}

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