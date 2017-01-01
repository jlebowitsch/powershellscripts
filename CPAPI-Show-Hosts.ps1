
<#


.SYNOPSIS
This Powershell Script retrieves the list of hosts from the SmartCenter database.

.DESCRIPTION
this Script uses the get-hosts API to retrieve hosts from Smartcenter. It creates two global objects, myCPhostsObjecs and myCPhostsjson, the first is a hashtable of the hosts, and the other is a json of the same. 
it exposes the parameters of the API as optional.

.EXAMPLE


.NOTES
Some options of the Add-host API are not implemented in this script!


.LINK
https://github.com/jlebowitsch/powershellscripts
https://sc1.checkpoint.com/documents/R80/APIs/?#web/show-hosts


#>


param(

    [Parameter(Mandatory=$false, HelpMessage="No more than that many results will be returned")][ValidateRange(1,9999)][Int] $limit,
	[Parameter(Mandatory=$false, HelpMessage="Skip that many results before beginning to return them")][ValidateRange(0,99999)][Int] $offset,
	[Parameter(Mandatory=$false, HelpMessage="Sorts results by the given field. The default is the random order")][ValidateSet("ASC", "DESC")][String] $order,
	[Parameter(Mandatory=$false, HelpMessage="The level of detail for some of the fields in the response can vary from showing only the UID value of the object to a fully detailed representation of the object.")][ValidateSet("uid", "standard","full")][String]$details_level
	
	 

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


#Prep objects  requests 
$myShowHostsURI="https://${myCPSmartCenterIPAddress}/web_api/show-hosts"


$myrequestbody=@{} 
if ($limit.Length -gt 0){$myrequestbody.add("limit", $limit)}
if ($offset.Length -gt 0){$myrequestbody.add("offset", $offset)}
if ($order.Length -gt 0){$myrequestbody.add("order", $order)}
if ($details_level.Length -gt 0){$myrequestbody.add("details-level", $details_level)}
$myrequestbodyjson=$myrequestbody | convertto-json -compress

$myRequestforHosts=Invoke-WebRequest -Uri $myShowHostsURI -Body $myrequestbodyjson -ContentType application/json -Method POST -headers $myCPHeader
$global:myCPhostsObjecs=$myRequestforHosts.content | ConvertFrom-Json
$global:myCPhostsjson=$myRequestforHosts.content
$myCPhostsjson