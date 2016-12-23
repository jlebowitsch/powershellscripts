# Interactive prompting for user credentials. run the script by typing .\<file name>. No changes within the file are necearry. you can provide parameters in the command line itself

param(

    [Parameter(Mandatory=$true, HelpMessage="username")]
     [String]$username,
	[Parameter(Mandatory=$false, HelpMessage="clear text password")]
     [String]$ClearTextPassword,
	[Parameter(Mandatory=$true, HelpMessage="IP Addess of Management Server")]
     [String]$ServerIPAddress
)


#resetting variables
$myresponse=""
$mysid=""
$myaddhostresponse=""
$mypublishresponse=""

if ($ClearTextPassword -eq "")
	{	$credential=get-credential -message "Please enter your SmartCenter username and password" -username $username
		$username=$credential.username
		$password=$credential.GetNetworkCredential().password
	}
	else {$password=$ClearTextPassword}

#create credential json
$myjson=@{user=$username;password=$password} | convertto-json -compress
$loginURI="https://${serverIPAddress}/web_api/login"

#allow self signed certs
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

#log in and capture response
$myresponse=Invoke-WebRequest -Uri $loginURI -Body $myjson -ContentType application/json -Method POST

#remove objects with password
rv "password"
rv "myjson"
if (!($ClearTextPassword -eq "")) {rv "ClearTextPassword"}

#make the content of the response a powershell object
$myresponsecontent=$myresponse.Content | ConvertFrom-Json

#get the sid of the response into its own object

$mysid=$myresponsecontent.sid

#create an x-chkp-sid header
$headers=@{"x-chkp-sid"=$mysid}

#create an x-chkp-sid header
$headers=@{"x-chkp-sid"=$mysid}

# create a request body
$mybodyjson=@{
  "offset" = 0;
  "limit" = 50;
  "name" = "Permissive";
  "details-level" = "Standard";
  "use-object-dictionary" = "true";
} | convertto-json -compress

#create the add host uri
$AddHostURI="https://${serverIPAddress}/web_api/show-access-rulebase"

# exect to server

try {$myaddhostresponse=Invoke-WebRequest -uri $AddHostURI -ContentType application/json -Method POST -headers $headers -body $mybodyjson}
  catch [System.Net.WebException] {
        $myaddhostresponse = $_.Exception.Response

    }
    catch {
        Write-Error $_.Exception
        return $null
    }
	$myaddhostresponse
