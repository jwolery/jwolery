$IPAddress = Read-Host -Prompt "Hello $env:USERNAME, Please Enter a valid IP address to query."
$a = $IPAddress
$ipcheck = ($a -as [IPaddress]) -as [Bool]
if($ipcheck)
{
    write-host "Ok, that looks like a Valid ip address, I will check the average latency over 10 pings."
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
    write-host "Sorry friend, that is not a valid address"
    $IPAddress = Read-Host -Prompt "Please re-enter the IP address"
}
try {
    $Ping = Test-Connection -Count 10 -ComputerName $IPAddress
    }
catch {
    Write-Host "Hmm, Looks like this IP is not responding to Pings." -ForegroundColor RED
}
finally {
    $Error.Clear()
}
$Avg = ($Ping | Measure-Object ResponseTime -average)
$Calc = [System.Math]::Round($Avg.average)
"The average response time to $IPAddress is $Calc ms `n"