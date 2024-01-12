function connect-fs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$username,
        [Parameter(Mandatory = $true)]
        [string]$password
    )

    $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)

    $uri = "https://eu5.fusionsolar.huawei.com/thirdData/login"
    $headers = @{
        "Content-Type" = "application/json"
    }

    $body = @{
        "userName" = $username
        "systemCode" = $password
    } | ConvertTo-Json
    #get response headers
    $responseHeaders = $null
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers -ResponseHeadersVariable responseHeaders

    if($response.success -eq "True"){
        return $responseHeaders.'xsrf-token'
    }else{
        Write-Host $response -ForegroundColor Red
        throw "Login failed"
    }
   
}
function Get-fsPlantList {
    param (
        [Parameter(Mandatory = $true)]
        $xsrfToken
    )
    $uri = "https://eu5.fusionsolar.huawei.com/thirdData/stations"
    $headers = @{
        "Content-Type" = "application/json"
        "xsrf-token" = $xsrfToken
    }
    $body = @{
        "pageNo" = 1
    } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers 
    if($response.success -eq "True"){
        return $response.data
    }else{
        Write-Host $response -ForegroundColor Red
        throw "Get plant list failed"
    }
}
function get-fsStationRealKpi {
    param (
        [Parameter(Mandatory = $true)]
        $xsrfToken,
        [Parameter(Mandatory = $true)]
        $plantCode
    )
    $uri = "https://eu5.fusionsolar.huawei.com/thirdData/getStationRealKpi"
    $headers = @{
        "Content-Type" = "application/json"
        "xsrf-token" = $xsrfToken
    }
    $body = @{
        "stationCodes" = $plantCode
    } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers 
    if($response.success -eq "True"){
        return $response.data
    }else{
        Write-Host $response -ForegroundColor Red
        throw "Get station real kpi failed"
    }

}
function get-fsDeviceList {
    param (
        [Parameter(Mandatory = $true)]
        $xsrfToken,
        [Parameter(Mandatory = $true)]
        $plantCode
    )
    $uri = "https://eu5.fusionsolar.huawei.com/thirdData/getDevList"
    $headers = @{
        "Content-Type" = "application/json"
        "xsrf-token" = $xsrfToken
    }
    $body = @{
        "stationCodes" = $plantCode
    } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers 
    if($response.success -eq "True"){
        return $response.data
    }else{
        Write-Host $response -ForegroundColor Red
        throw "Get device list failed"
    }
}
function get-fsDeviceKpi {
    <#
    .SYNOPSIS
    Short description
    
    .DESCRIPTION
    Long description
    
    .PARAMETER xsrfToken
    Parameter description
    
    .PARAMETER plantCode
    Parameter description
    
    .PARAMETER deviceId
    Parameter description
    
    .PARAMETER devTypeId
    The following device types are supported:

    1: string inverter

    10: EMI

    17: grid meter

    38: residential inverter

    39: battery

    41: ESS

    47: power sensor
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    param (
        [Parameter(Mandatory = $true)]
        $xsrfToken,
        [Parameter(Mandatory = $false)]
        $deviceId,
        [Parameter(Mandatory = $false)]
        $devTypeId,
        [Parameter(Mandatory = $false)]
        #validation 
        [ValidateSet("stringInverter", "EMI", "gridMeter", "residentialInverter", "battery", "ESS", "powerSensor")]
        $devType,
        [Parameter(Mandatory = $false)]
        $plantCode
    )
    if([string]::IsNullOrEmpty($devTypeId)){
        switch($devType){
            "stringInverter" {$devTypeId = 1}
            "EMI" {$devTypeId = 10}
            "gridMeter" {$devTypeId = 17}
            "residentialInverter" {$devTypeId = 38}
            "battery" {$devTypeId = 39}
            "ESS" {$devTypeId = 41}
            "powerSensor" {$devTypeId = 47}
            default {throw "Unknown device type"}
        }
    }
    if ([string]::IsNullOrEmpty($deviceId)){
        #debug
        # $devTypeId = 47
        # $devices| where {$_.devTypeId -eq $devTypeId}
        $device = get-fsDeviceList -xsrfToken $xsrfToken -plantCode $plantCode | where {$_.devTypeId -eq $devTypeId}
        $deviceId = $device.id
    }
    $uri = "https://eu5.fusionsolar.huawei.com/thirdData/getDevRealKpi"
    $headers = @{
        "Content-Type" = "application/json"
        "xsrf-token" = $xsrfToken
    }
    $body = @{
        "devTypeId" = $devTypeId
        "devIds" = $deviceId
    } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers 
    if($response.success -eq "True"){
        return $response.data.dataItemMap
    }else{
        Write-Host $response -ForegroundColor Red
        throw "Get device kpi failed"
    }

}



$xsrfToken = connect-fs -username "michal.pipala" -password "12p34567"
$plant = Get-fsPlantList -xsrfToken $xsrfToken
$plantCode = $plant.list.plantcode
$plandID = "36998658"
$devices = get-fsDeviceList -xsrfToken $xsrfToken -plantCode $plantCode
$realKpi = get-fsStationRealKpi -xsrfToken $xsrfToken -plantCode $plantCode

$device = get-fsDeviceKpi -xsrfToken $xsrfToken -devType powerSensor -plantCode $plantCode
get-fsDeviceKpi -xsrfToken $xsrfToken -devType battery -plantCode $plantCode