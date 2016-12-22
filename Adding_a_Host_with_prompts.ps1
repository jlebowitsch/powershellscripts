# Interactive prompting for user credentials. run the script by typing .\<file name>. No changes within the file are necearry. you can provide parameters in the command line itself

param(

    [Parameter(Mandatory=$true, HelpMessage="username")]
     [String]$username,
	[Parameter(Mandatory=$false, HelpMessage="clear text password")]
     [String]$ClearTextPassword,
	[Parameter(Mandatory=$true, HelpMessage="IP Addess of Management Server")]
     [String]$ServerIPAddress,
	[Parameter(Mandatory=$true, HelpMessage="New Host Name")]
     [String]$hostname,
	 [Parameter(Mandatory=$true, HelpMessage="New Host IP Address")]
     [String]$hostIPaddress

)


#resetting variables that may have lingered from previous runs
$myresponse=""
$mysid=""
$myaddhostresponse=""
$mypublishresponse=""

# securely prompt for password if none was provided

if ($ClearTextPassword -eq "")
	{	$credential=get-credential -message "Please enter your SmartCenter username and password" -username $username
		$password=$credential.GetNetworkCredential().password
	}
	else {$password=$ClearTextPassword}

#create credential json
$myjson=@{user=$username;password=$password} | convertto-json -compress

# create login URI
$loginURI="https://${serverIPAddress}/web_api/login"


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
$headers=@{"x-chkp-sid"=$mysid}

# create a request body
$mybodyjson=@{name=$hostname;"ip-address"=$hostIPaddress} | convertto-json -compress

#create the add host uri
$AddHostURI="https://${serverIPAddress}/web_api/add-host"

# add host to server

$myaddhostresponse=Invoke-WebRequest -uri $AddHostURI -ContentType application/json -Method POST -headers $headers -body $mybodyjson

# publish

$mypublishURI="https://${serverIPAddress}/web_api/publish"
$mypublishbodyjson=@{} | convertto-json -compress

$mypublishresponse=Invoke-WebRequest -uri $mypublishURI -ContentType application/json -Method POST -headers $headers -body $mypublishbodyjson

#show happy ending
if ($mypublishresponse.statuscode -eq 200){"Script completed. Host was added"}