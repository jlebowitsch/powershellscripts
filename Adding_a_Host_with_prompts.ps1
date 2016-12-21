# Interactive prompting for user credentials

param(

    [Parameter(Mandatory=$true, HelpMessage="username")]
     [String]$username,
	[Parameter(Mandatory=$true, HelpMessage="Password?")]
     [SecureString]$password,
	[Parameter(Mandatory=$true, HelpMessage="IP Addess of Management Server")]
     [String]$ServerIPAddress,
	[Parameter(Mandatory=$true, HelpMessage="New Host Name")]
     [String]$hostname,
	 [Parameter(Mandatory=$true, HelpMessage="New Host IP Address")]
     [String]$hostIPaddress

)

# from here down no edits are necessary
#resetting variables
$myresponse=""
$mysid=""
$myaddhostresponse=""
$mypublishresponse=""


#create credential json
$myjson=@{user=$username;password=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))} | convertto-json -compress
$loginURI="https://${serverIPAddress}/web_api/login"

#allow self signed certs
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

#log in and capture response
$myresponse=Invoke-WebRequest -Uri $loginURI -Body $myjson -ContentType application/json -Method POST

#remove objects with password
rv "password"
rv "myjson"

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