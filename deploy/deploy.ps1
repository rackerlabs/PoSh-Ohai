trap{
    Write-Error -ErrorRecord $_
    exit 1
}

$psVersion = $PSVersionTable.PSVersion.Major
if ($psVersion -lt 3){
    $psMessage = "Powershell Version $psVersion has been detected. The script is exiting"
    $psSupported = @{
        PsVersion       = $psVersion
        Supported       = $false
        PsMessage       = $psMessage
    }
    $psSupported
    Exit
}
else{
    $psMessage = "Powershell Version $psVersion has been detected. The script is running"
    $psSupported = @{
        PsVersion       = $psVersion
        Supported       = $true
        PsMessage       = $psMessage
    }
    $psSupported
}


Function Get-Hash{
    param(
        [string]$Path
    )

    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($Path)))
    $hash.Replace('-','').toLower()
}

If (Test-Path -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai')) {
    try {
        Write-Host "Found existing temp dir in $($env:TEMP), trying to delete!"
        Remove-Item -Force -Recurse -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai') -ErrorAction Stop
    } catch {
        throw "Temp folder exists and can't be deleted, stopping"
    }
}

Write-Host "Downloading Zip file from github to $(Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai-master.zip')"
(New-Object -TypeName System.Net.WebClient).DownloadFile('http://readonly.configdiscovery.rackspace.com/PoSh-Ohai-master.zip',(Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai-master.zip'))

Write-Host 'Adding ZipStorer Type to decompress downloaded Zip file'
If (-not ('System.IO.Compression.ZipStorer' -as [type])) {
    Add-Type -TypeDefinition (New-Object -TypeName System.Net.WebClient).DownloadString('http://readonly.configdiscovery.rackspace.com/ZipStorer.cs') -Language CSharp
}

Write-Host "Decompressing zip file to $env:TEMP"
$zip = [System.IO.Compression.ZipStorer]::Open((Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai-master.zip'),[System.IO.FileAccess]::Read)
$extractSuccessful = $true
foreach ($file in $zip.ReadCentralDir()) {
    if ( -not $zip.ExtractFile($file,(Join-Path -Path $env:TEMP -ChildPath $file.FilenameInZip))) {
        $extractSuccessful = $false
    }
}
$zip.Close()


Rename-Item -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai-master') -NewName (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai')
$manifest = [scriptblock]::Create((Get-Content (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai\PoSh-Ohai.psd1') -Raw)).Invoke()

if ($manifest.ModuleVersion -gt (Get-Module -ListAvailable PoSh-Ohai).version) {
    Write-Host "Downloaded version ($($manifest.ModuleVersion)) greater than existing version ($( If ((Get-Module -ListAvailable PoSh-Ohai).version) {(Get-Module -ListAvailable PoSh-Ohai).version} else {'not installed'})), trying to copy new version..."
    Remove-Module PoSh-Ohai -ErrorAction SilentlyContinue
    try {
        Copy-Item -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai') -Destination $($env:PSModulePath.Split(';') |
        Where-Object {$_.StartsWith($env:SystemRoot)}) -Recurse -Force
    } catch {
        throw 'The attempt to copy the module to its location failed, stopping'
    }
} else {
    Write-Host "Downloaded version ($($manifest.ModuleVersion)) not greater than existing version ($( If ((Get-Module -ListAvailable PoSh-Ohai).version) {(Get-Module -ListAvailable PoSh-Ohai).version} else {'not installed'})), checking plugins for changes..."
    $moduleBase = (Get-Module -ListAvailable PoSh-Ohai).ModuleBase
    $newPlugins = Get-ChildItem -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai\plugins') | ForEach-Object {Add-Member -InputObject $_ -MemberType NoteProperty -Name md5 -Value (Get-Hash -Path $_.FullName) -PassThru}
    $existingPlugins = Get-ChildItem -Path (Join-Path -Path $moduleBase -ChildPath 'plugins') | ForEach-Object {Add-Member -InputObject $_ -MemberType NoteProperty -Name md5 -Value (Get-Hash -Path $_.FullName) -PassThru}
    $different = Compare-Object -ReferenceObject $newPlugins -DifferenceObject $existingPlugins -Property md5 -PassThru | Where-Object { $_.SideIndicator -eq '<='}
    if ($different) {
        Write-Host "The following plugins have been changed or added and will be copied: $(($different | ForEach-Object { $_.name }) -join ', ')"
        $different  | ForEach-Object { Copy-Item -Path $_.FullName -Destination (Resolve-Path (Join-Path -Path $moduleBase -ChildPath 'plugins')) }
    } Else {
        Write-Host 'No change of plugins detect, nothing to do...'
    }


    $newModule = Get-ChildItem -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai') | ForEach-Object {
        Add-Member -InputObject $_ -MemberType NoteProperty -Name md5 -Value (Get-Hash -Path $_.FullName) -PassThru
    }
    $existingModule = Get-ChildItem -Path (Join-Path -Path $moduleBase) | ForEach-Object {
        Add-Member -InputObject $_ -MemberType NoteProperty -Name md5 -Value (Get-Hash -Path $_.FullName) -PassThru
    }
    $differentModule = Compare-Object -ReferenceObject $newModule -DifferenceObject $existingModule -Property md5 -PassThru | Where-Object {
        $_.SideIndicator -eq '<='
    }
    if ($differentModule) {
        Write-Host "The following module has been changed or added and will be copied: $(($differentModule | ForEach-Object { $_.name }) -join ', ')"
        $differentModule  | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination (Resolve-Path (Join-Path -Path $moduleBase))
        }
    } Else {
        Write-Host 'No change of the module detect, nothing to do...'
    }

}



Write-Host 'Done, deleting temp files...'
Remove-Item -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai') -ErrorAction SilentlyContinue -Recurse -Force
Remove-Item -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai-master.zip') -ErrorAction SilentlyContinue -Force
