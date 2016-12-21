#parameters 
$username="" #Don't enter anything here and for the password parameter if you want to be securely prompted for them
$password=""
$ServerIPAddress="50.16.39.92"
$hostname="addhost1012" #this is the name of host you want to add
$hostIPaddress="2.2.2.3"  # this is the IP address of the host you want to add

# from here down no edits are necessary
#resetting variables
$myresponse=""
$mysid=""
$myaddhostresponse=""
$mypublishresponse=""

#prompt for crendentials if none where given

if ($password -eq "")
	{	$credential=get-credential -message "Please enter your SmartCenter username and password"
		$username=$credential.username
		$password=$credential.GetNetworkCredential().password
	}

#create credential json
$myjson=@{user=$username;password=$password} | convertto-json -compress
$loginURI="https://${serverIPAddress}/web_api/login"

#allow self signed certs
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

#log in and capture response
$myresponse=Invoke-WebRequest -Uri $loginURI -Body $myjson -ContentType application/json -Method POST

#remove objects with password
rv "password"
rv "credential"
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