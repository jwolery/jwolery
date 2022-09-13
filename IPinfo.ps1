$IPAddress = Read-Host -Prompt "Hello $env:USERNAME, Please enter an IP address to query"
$a = $IPAddress
$ErrorActionPreference = "Stop"
$ipcheck = ($a -as [IPaddress]) -as [Bool]
if($ipcheck)
{
    ''
    write-host "Thanks! I will check if this IP ping-able however if its not responsive I won't be able to provide any info."
    ''
    write-host "Please give me a moment to validate, fetch available Geo Location info and calculate an average of 10 Pings"
}
else
{
    write-host "Sorry, that is not a valid address"
    $IPAddress = Read-Host -Prompt "Please re-enter the IP address"
    ''
    write-host "Thanks! I will check if this IP ping-able however if its not responsive I won't be able to provide any info."
    ''
    write-host "Please give me a moment to validate, fetch available Geo Location info and calculate an average of 10 Pings"
}
try {
    $Ping = Test-Connection -Count 10 -ComputerName $IPAddress
    }
catch {
    Write-Host "ERROR: Looks like this IP is either not responding to Pings, offline or possibly Invalid." -ForegroundColor RED
    Exit
}
$Avg = ($Ping | Measure-Object ResponseTime -average)
$Calc = [System.Math]::Round($Avg.average)
if ($Calc -gt 1) {
    <# Action when this condition is true #>
    try {
        Write-Host "Almost done! Next lets TraceRoute to calculate number of hops, this may take a minute or 2."
        $ProgressPreference = 'SilentlyContinue'
        $NumHops = (Test-NetConnection -TraceRoute -ComputerName $IPAddress -ErrorAction Stop).traceroute.count
        ''
        Write-Host 'SUCCESS! Thanks for waiting, Here is what I found:' -ForegroundColor Green
        Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$IPAddress" -ErrorAction SilentlyContinue | Foreach-object {
        $IPCity = [PSCustomObject]$_.City
        $IPRegion = [PSCustomObject]$_.Region
        $IPCountry = [PSCustomObject]$_.Country
        $IPtz = [PSCustomObject]$_.TimeZone
        $IPLat = [PScustomObject]$_.Lat
        $IPLon = [PScustomObject]$_.Lon
        $IPZip = [PScustomObject]$_.Zip
        $IPOrg = [PScustomObject]$_.Org
        $IPISP = [PScustomObject]$_.ISP
        $IPAS = [PScustomObject]$_.as
    }
    ''
    Write-Host "The average latency to $IPAddress (over $NumHops Hops) is $Calc ms and is located in $IPCity, $IPRegion in $IPCountry." -ForegroundColor DarkYellow
    ''
    Write-Host "The reported Latitude & Longitude is $IPLat,$IPLon and the postal code is $IPZip." -ForegroundColor DarkYellow
    ''
    Write-Host "I am showing the Netblock Org/ISP as $IPOrg/$IPISP and the AS number is $IPAS." -ForegroundColor DarkYellow
    ''
    }
    catch {
    Write-Warning -Message "$IPAddress : $_"
    }
}
# Get the current datetime of the IP
Invoke-RestMethod -Method Get -Uri "http://worldtimeapi.org/api/ip/$IPAddress.json" -ErrorAction SilentlyContinue | Foreach-object {
    $IPTime = [PSCustomObject]$_.datetime
    Write-Host "$IPCity is in the $IPtz timezone where it is" -ForegroundColor Cyan ([DateTimeOffset] $_.datetime).ToString('f')
}
# Get the Weather for the Geolocation Data
''
Write-Host 'Here is todays weather around that area:' -ForegroundColor Blue
''
(curl wttr.in/"$IPCity,$IPRegion"?0 -UserAgent "curl" ).Content
# reset variables for next run - this ensures no data is carried over between runs if it is not replaced by new data
$Calc = $null
$Avg = $null
$IPAddress = $null
$NumHops = $null
$IPCity = $null
$IPRegion = $null
$IPCountry = $null
$IPtz = $null
$IPLat = $null
$IPLon = $null
$IPZip = $null
$IPOrg = $null
$IPISP = $null
$IPAS = $null