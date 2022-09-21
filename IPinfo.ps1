function Get-IPinfo {
    <#
    .SYNOPSIS
        Gathers information on an IP address - Created as a scripting Challenge for Tim @ Rewst.io
    .DESCRIPTION
        Specify an IPv4 Address to Calculate average of 10 pings, number of hops, GEOIP information and Weather information
    .NOTES
        Script made and tested on Powershell 5.1 which is the default that ships with windows.
        This script is not digitally signed so you must 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
' to use it.
        CmdLetBinding paramaters are still not fully working yet so you cannot use command line input or save to JSON, However IP command line input is now functional.
    .LINK
        
    .EXAMPLE
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\IPinfo
        Get-IPinfo, when prompted input an IPv4 IP Address.
        OR Get-IPinfo 8.8.8.8
    #>
    
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $false,
        ValueFromPipeline = $false,Position=0)]
        $IPAddress,
        [Parameter (Mandatory = $false,
        ValueFromPipeline = $false,Position=1)]
        [string] $JsonFile
        )
        # Prompt for IP if none is specified #
        if($IPAddress -eq $null)
        {
            $IPAddress = Read-Host -Prompt "Hello $env:USERNAME, Please enter an IP address to query"
        }
        # 2 stage IP Validation - attempts to catch bad & blank secondary input#    
        if ($IPAddress -notmatch "(?:(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d)\.){3}(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d)")
        {
            Write-Host "ERROR: $IPaddress not a valid IPv4 address please try again." -ForegroundColor RED -ErrorAction SilentlyContinue
            $IPAddress = Read-Host -Prompt "Let's try this again $env:USERNAME, Please enter an IP address to query"
        }
        $ipcheck = ($IPAddress -as [IPaddress]) -as [Bool]
        if($ipcheck)
            {
                ''
            }
            else
            {
                write-host "ERROR: $IPaddress not a valid IPv4 address" -ForegroundColor RED        
                $IPAddress = Read-Host -Prompt "Please re-enter the IP address"
                if ($IPAddress -notmatch "(?:(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d)\.){3}(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d)")
                {
                    Write-Host "ERROR: $IPaddress not a valid IPv4 address please try again." -ForegroundColor RED -ErrorAction SilentlyContinue
                    $IPAddress = Read-Host -Prompt "Let's try this again $env:USERNAME, Please enter an IP address to query"
                }   
            }
            try {
                if($IPAddress -eq "")
                # Catch for repeated Blank Input #
                {
                    Write-Host "$env:USERNAME, You didn't enter an IP Address I am a powershell script not a psychic!" -ForegroundColor RED
                    Exit
                }
                # IPaddress is valid #
                write-host "Thanks $env:USERNAME! This looks like a Valid IP Address." -ForegroundColor Green
                ''
                write-host "I will check if this IP responds to Pings however if it doesn't I won't be able to provide any info."    
                ''
                write-host "Please give me a moment to validate, fetch Geo Location info and calculate an average of 10 Pings."
                $Ping = Test-Connection -Count 10 -ComputerName $IPAddress  -ErrorAction Stop
            }
            catch {
                Write-Host "ERROR: Looks like this IP is either not responding to Pings, offline or possibly Invalid." -ForegroundColor RED
                Exit
            }
            # Calculates average Ping if pings were returned #
            $Avg = ($Ping | Measure-Object ResponseTime -average)
            $Calc = [System.Math]::Round($Avg.average)
            if ($Calc -gt 1) {
                <# Proceed to fetch GeoLocation Data #>
                try {
                    Write-Host "...Almost done! Next lets TraceRoute to calculate number of hops, this may take a minute."
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
                # Present Geo Location data in a friendly manner #
                ''
                Write-Host "The average latency to $IPAddress (over $NumHops Hops) is $Calc ms and is located in $IPCity, $IPRegion in $IPCountry." -ForegroundColor Yellow
                ''
                Write-Host "The reported Latitude & Longitude is $IPLat,$IPLon and the postal code is $IPZip." -ForegroundColor Yellow
                ''
                Write-Host "I am showing the Netblock Org/ISP as $IPOrg/$IPISP and the AS number is $IPAS." -ForegroundColor Yellow
                ''
            }
            catch {
            Write-Warning -Message "$IPAddress : $_ Something went wrong with GEOIP Fetch."
            }
        }
        # Get the current datetime of the IP
        Invoke-RestMethod -Method Get -Uri "http://worldtimeapi.org/api/ip/$IPAddress.json" -ErrorAction SilentlyContinue | Foreach-object {
            $IPTime = [PSCustomObject]$_.datetime
            Write-Host "$IPCity is in the $IPtz timezone where it is" -ForegroundColor Cyan ([DateTimeOffset] $_.datetime).ToString('f')
        }
        # Get the Weather for the Geolocation Data
        ''
        Write-Host "Now, lets check todays weather around the $IPCity area." -ForegroundColor Blue
        ''
        (curl wttr.in/"$IPCity,$IPRegion"?0 -UserAgent "curl" ).Content
        # Output GEO-IP info to JSON #
        if ($JsonFile -ne $null)
        {
            try {
                Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$IPAddress" -ErrorAction SilentlyContinue | Out-File $JsonFile
                Write-Host "Saved JSON file as $JsonFile"
            }
            catch {
                Write-Host "No json filename specified, if you would like to save a JSON please provide a filename. EXAMPLE: Get-IPinfo 8.8.8.8 googledns.json"
            }
        }
        
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
        $JsonFile = $null  
        }  

Get-IPinfo