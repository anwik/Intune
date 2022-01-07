## Get-IntuneDeviceNotes.ps1 - Use this script to lookup or set/modify the notes field on a given Intune device.

The script uses the Microsoft.Graph.Intune Module to connect to MSGraph and then fetch the notes property. The module will be automatically
installed if needed.

## Parameters
```powershell
Get-IntuneDeviceNotes.ps1 [[-DeviceName] <String>] [[-Notes] <String>] [<CommonParameters>]

Required?                    true
Position?                    1
Default value
Accept pipeline input?       false
Accept wildcard characters?  false

Required?                    false
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false

[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction,
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

## Example
```powershell
PS > Get-IntuneDeviceNotes.ps1 -DeviceName "VM-1874-39"
Getting notes for: VM-1874-39
Device: VM-1874-39 has the following note: Laddstation: 33

PS > Get-IntuneDeviceNotes.ps1 -DeviceName "VM-1874-39" -Notes "Laddstation: 99"
VM-1874-39 already has the following note: Laddstation: 33
Are you sure you want to change this note?
[Y] Yes  [N] No  [?] Help (default is "N"): Y
OK, updating note for VM-1874-39
VM-1874-39 now has note: Laddstation: 99
```

## Notes
FileName:    Get-IntuneDeviceNotes.ps1\
Author:      Andreas Wikström\
Contact:     @andreaswkstrom\
Created:     2022-01-07\
Updated:

Version history:\
1.0 - 2022-01-07    Intial script