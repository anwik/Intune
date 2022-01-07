<#
.SYNOPSIS
Use this script to lookup or set/modify the notes field on a given Intune device.
.DESCRIPTION
The script uses the Microsoft.Graph.Intune Module to connect to MSGraph and then fetch the notes property. The module will be automatically
installed if needed.

.PARAMETER DeviceName
The name of the device that you want to get the notes field from as it appears in Intune.

.PARAMETER Notes
The text that you wish to enter as a note on the given device. If the device already have any notes defined, you will be prompted to continue.

.EXAMPLE 
Check the currently set notes of a device:  Get-IntuneDeviceNotes.ps1 -DeviceName Computer1
Set or modify the notes of a device:        Get-IntuneDeviceNotes.ps1 -DeviceName Computer1 -Notes "Charging bay: 205"
.NOTES
FileName:    Get-IntuneDeviceNotes.ps1
Author:      Andreas Wikström
Contact:     @andreaswkstrom
Created:     2022-01-07
Updated:     

Version history:
1.0 - 2022-01-07    Intial script
#>

[CmdletBinding()]
param ([string]$DeviceName, [string]$Notes

)

Function Get-IntuneDeviceNotes {
    <#
    .SYNOPSIS
    Gets the notes of a device in intune.
    
    .DESCRIPTION
    Gets the notes property on a device in intune using the beta Graph api
    
    .PARAMETER DeviceName
    The name of the device that you want to get the notes field from as it appears in intune.
    
    .EXAMPLE
    Get-IntuneDeviceNotes -DeviceName TestDevice01
    
    .NOTES
    Must connect to the graph api first with Connect-MSGraph.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $DeviceName
    )
    Try {
        $DeviceID = (Get-IntuneManagedDevice -filter "deviceName eq '$DeviceName'" -ErrorAction Stop).id
    } Catch {
        Write-Error $_.Exception.Message
        break
    }
    $Resource = "deviceManagement/managedDevices('$deviceId')"
    $properties = 'notes'
    $uri = "https://graph.microsoft.com/beta/$($Resource)?select=$properties"
    Try {
        (Invoke-MSGraphRequest -HttpMethod GET -Url $uri -ErrorAction Stop).notes
    } Catch {
        Write-Error $_.Exception.Message
        break
    }
}

Function Set-IntuneDeviceNotes {
    <#
    .SYNOPSIS
    Sets the notes on a device in intune.
    
    .DESCRIPTION
    Sets the notes property on a device in intune using the beta Graph api
    
    .PARAMETER DeviceName
    The name of the device as it appears in intune.
    
    .PARAMETER Notes
    A string of the notes that you would like recorded in the notes field in intune.
    
    .EXAMPLE
    Set-IntuneDeviceNotes -DeviceName TestDevice01 -Notes "This is a note on the stuff and things for this device."
    
    .NOTES
    Must connect to the graph api first with Connect-MSGraph.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $DeviceName,
        [Parameter(Mandatory = $true)]
        [String]
        $Notes
    )
    Try {
        $DeviceID = (Get-IntuneManagedDevice -filter "deviceName eq '$DeviceName'" -ErrorAction Stop).id
    } Catch {
        Write-Error $_.Exception.Message
        break
    }
    If (![string]::IsNullOrEmpty($DeviceID)) {
        $Resource = "deviceManagement/managedDevices('$DeviceID')"
        $GraphApiVersion = 'Beta'
        $URI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        $JSONPayload = @"
{
notes:"$Notes"
}
"@
        Try {
            Write-Verbose "$URI"
            Write-Verbose "$JSONPayload"
            Invoke-MSGraphRequest -HttpMethod PATCH -Url $uri -Content $JSONPayload -Verbose -ErrorAction Stop
        } Catch {
            Write-Error $_.Exception.Message
            break
        }
    }
}

function Connect-MSGraphIntune {
    <#
    .SYNOPSIS
    Connects to MSGraph through the Microsoft.Graph.Intune Module. 
    The module will be automatically installed.
#>
        #region Connect to MSGraph
        Try{
            $IntuneConnected = Connect-MSGraph
        }
        Catch{}
        #endregion

        if ($IntuneConnected -eq ''){
        #region Install the Microsoft.Graph.Intune module
        $Module = 'Microsoft.Graph.Intune'
        Write-Host -ForegroundColor Yellow "Checking whether module is installed: $Module."
        $installedModule = Get-Module -Name $Module -ListAvailable -ErrorAction 'SilentlyContinue' | `
                Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | `
                Select-Object -First 1
        $publishedModule = Find-Module -Name $Module -ErrorAction 'SilentlyContinue'
        If (($Null -eq $installedModule) -or ([System.Version]$publishedModule.Version -gt [System.Version]$installedModule.Version)) {
            Write-Host -ForegroundColor Yellow "Installing module: $Module $($publishedModule.Version)."
            $params = @{
                Name               = $Module
                SkipPublisherCheck = $true
                Force              = $true
                ErrorAction        = 'Stop'
            }
            Install-Module @params
        }
        #endregion

        #region Connect to MSGraph
        Connect-MSGraph
        #endregion

    }
}

$ConnectGraph = Connect-MSGraphIntune

if ($Notes -ne '') {
    $CurrentNote = Get-IntuneDeviceNotes -DeviceName $DeviceName
    if ($CurrentNote -ne '') {
        $title = "$DeviceName already has the following note: $CurrentNote"
        $question = 'Are you sure you want to change this note?'
        $choices = '&Yes', '&No'
        $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
        if ($decision -eq 0) {
            Write-Host -ForegroundColor Yellow "OK, updating note for $DeviceName"
            Set-IntuneDeviceNotes -DeviceName $DeviceName -Notes $Notes
            $NewNote = Get-IntuneDeviceNotes -DeviceName $DeviceName
            Write-Host -ForegroundColor Green "$DeviceName now has note: $NewNote"
        } else {
            Write-Host -ForegroundColor Yellow "OK, will not update the note for: $DeviceName"
        }
    }
    
    if ($CurrentNote -eq '') {
        Write-Host -ForegroundColor Yellow "Setting notes for: $DeviceName"
        Set-IntuneDeviceNotes -DeviceName $DeviceName -Notes $Notes
        $NewNote = Get-IntuneDeviceNotes -DeviceName $DeviceName
        Write-Host -ForegroundColor Green "$DeviceName now has the following note: $NewNote"
    }
    
}

if (!$Notes) {
    Write-Host -ForegroundColor Yellow "Getting notes for: $DeviceName"
    $CurrentNote = Get-IntuneDeviceNotes -DeviceName $DeviceName
    if ($CurrentNote -eq '') {
        Write-Host -ForegroundColor Yellow "Device: $DeviceName doesn't have any notes set yet"
    } else {
        Write-Host -ForegroundColor Green "Device: $DeviceName has the following note: $CurrentNote"
    }
}