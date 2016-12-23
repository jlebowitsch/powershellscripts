# This is a standalone login script. It will leave behind a parameter, "myCPHeader", that subsequent scripts can use to authenticate API calls to SmartCenter.
# It also leaves begind a parameter, "myCPSmartCenterIPAddress", that should be used in constructing the URI for calls.

param(

    [Parameter(Mandatory=$true, HelpMessage="username")]
     [String]$username,
	[Parameter(Mandatory=$false, HelpMessage="clear text password")]
     [String]$ClearTextPassword,
	[Parameter(Mandatory=$true, HelpMessage="IP Addess of Management Server")]
     [String]$mySmartCenterAddress,
	[Parameter(Mandatory=$false, HelpMessage="If connecting to a domain in an MDS, specify it")][AllowNull()] 
     [String]$DomainName
	
	 

)


#resetting variables that may have lingered from previous runs
$myresponse=""
$mysid=""
$myaddhostresponse=""
$mypublishresponse=""

$global:myCPSmartCenterIPAddress=$mySmartCenterAddress

# securely prompt for password if none was provided

if ($ClearTextPassword -eq "")
	{	$credential=get-credential -message "Please enter your SmartCenter username and password" -username $username
		$password=$credential.GetNetworkCredential().password
	}
	else {$password=$ClearTextPassword}

#create credential json
$myCredentialhash=@{user=$username;password=$password}
## if($DomainName.length -gt 0){$myCredentialhash.add("domain", $DomainName) }
$myjson=$myCredentialhash | convertto-json -compress

# create login URI
$loginURI="https://${myCPSmartCenterIPAddress}/web_api/login"


#allow self signed certs
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

#log in and capture response

$myresponse=Invoke-WebRequest -Uri $loginURI -Body $myjson -ContentType application/json -Method POST
 
   

#remove objects with password
rv "password"
rv "myjson"
if (!($ClearTextPassword -eq "")) {rv "ClearTextPassword"}
if (!($credential -eq "")) {rv "credential"}

#make the content of the response a powershell object
$myresponsecontent=$myresponse.Content | ConvertFrom-Json

#get the sid of the response into its own object

$mysid=$myresponsecontent.sid

#create an x-chkp-sid header
$global:myCPHeader=@{"x-chkp-sid"=$mysid}

