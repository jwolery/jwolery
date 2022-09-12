$IPAddress = Read-Host -Prompt "Hello $env:USERNAME, Please enter an IP address to query"
$a = $IPAddress
$ErrorActionPreference = "Stop"
$ipcheck = ($a -as [IPaddress]) -as [Bool]
if($ipcheck)
{
    ''
    write-host "Thanks! Initial validation check thinks this is a Valid ip address, if its not responsive we'll know shortly."
    ''
    write-host "Please give me a moment to fetch available Geo Location info and calculate an average of 10 Pings"
}
elseif($a -like "*/*" -or $a -like "*-*")
{
    $cidr = $a.split("/")
    if($cidr[1] -ge '0' -and $cidr[1] -le '32')
    {
        write-host "Ok, that looks like a valid subnet"
    }
    elseif($a -like "*-*")
    {
        $ip = $a.split("-")
        $ip1 = $ip[0] -as [IPaddress] -as [Bool]
        $ip2 = $ip[1] -as [IPaddress] -as [Bool]
        if($ip -and $ip)
        {
            write-host "Ok, that looks like a valid ip address range"
        }
        else
        {
            write-host "invalid range"
        }
 
    }
    else {
        write-host "invalid subnet"
    }
}
else
{
    write-host "Sorry, that is not a valid address"
    $IPAddress = Read-Host -Prompt "Please re-enter the IP address"
}
try {
    $Ping = Test-Connection -Count 10 -ComputerName $IPAddress
    }
catch {
    Write-Host "Looks like this IP is either not responding to Pings or possibly Invalid." -ForegroundColor RED
    Exit
}
finally {
    $Error.Clear()
}
$Avg = ($Ping | Measure-Object ResponseTime -average)
$Calc = [System.Math]::Round($Avg.average)
if ($Calc -eq 0) {
    <# Action to perform if the condition is true #>
}
elseif ($Calc -gt 1) {
    <# Action when this condition is true #>
    try {
        ''
        Write-Host 'Thanks for waiting, Here is the GeoIP Data:' -ForegroundColor Green
        Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$IPAddress" -ErrorAction SilentlyContinue | Foreach-object {
            [pscustomobject]@{
            Country       = $_.Country
            CountryCode   = $_.CountryCode
            Region        = $_.Region
            City          = $_.City
            'Postal Code' = $_.Zip
            'Network Org' = $_.Org
            ISP           = $_.ISP
            AS            = $_.as
            Lat           = $_.Lat
            Lon           = $_.Lon
            TimeZone      = $_.TimeZone
        }
        $IPCity = [PSCustomObject]$_.City
        $IPRegion = [PSCustomObject]$_.Region
        $IPCountry = [PSCustomObject]$_.Country
        $IPtz = [PSCustomObject]$_.TimeZone
    }
    "The average response time to $IPAddress is $Calc ms and is located in $IPCity, $IPRegion in $IPCountry `n"
    Write-Host 'Here is todays weather around that area:' -ForegroundColor Blue
    }
    catch {
    Write-Warning -Message "$IPAddress : $_"
    }
}
# Get the Weather for the Geolocation Data

(curl wttr.in/"$IPCity,$IPRegion"?0 -UserAgent "curl" ).Content

# Get the current datetime of the IP

Invoke-RestMethod -Method Get -Uri "http://worldtimeapi.org/api/ip/$IPAddress.json" -ErrorAction SilentlyContinue | Foreach-object {
    [PSCustomObject]@{
    }
    $IPTime = $_.datetime
    Write-Host "$IPCity is in the $IPtz timezone where it is" -ForegroundColor Cyan ([DateTimeOffset] $_.datetime).ToString('f')
}
# reset variables for next run
$Calc = $null
$Avg = $null