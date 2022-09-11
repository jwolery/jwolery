$IPAddress = Read-Host -Prompt "Enter IP address"
$a = $IPAddress
$ipcheck = ($a -as [IPaddress]) -as [Bool]
if($ipcheck)
{
    write-host "Valid ip address"
}
elseif($a -like "*/*" -or $a -like "*-*")
{
    $cidr = $a.split("/")
    if($cidr[1] -ge '0' -and $cidr[1] -le '32')
    {
        write-host "valid subnet"
    }
    elseif($a -like "*-*")
    {
        $ip = $a.split("-")
        $ip1 = $ip[0] -as [IPaddress] -as [Bool]
        $ip2 = $ip[1] -as [IPaddress] -as [Bool]
        if($ip -and $ip)
        {
            write-host "valid ip address range"
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
    write-host "not valid address"
    $IPAddress = Read-Host -Prompt "Enter IP address"
}
$Ping = Test-Connection -Count 10 -ComputerName $IPAddress
$Avg = ($Ping | Measure-Object ResponseTime -average)
$Calc = [System.Math]::Round($Avg.average)
"The average response time to $IPAddress is $Calc ms `n"