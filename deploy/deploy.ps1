#requires -Version 2
trap
{
  Write-Error -ErrorRecord $_
  exit 1
}

$psVersion = $PSVersionTable.PSVersion.Major
if ($psVersion -lt 3)
{
  $psMessage = "Powershell Version $psVersion has been detected. The script is exiting"
  $psSupported = @{
    PsVersion = $psVersion
    Supported = $false
    PsMessage = $psMessage
  }
  $psSupported
}
else
{
  $psMessage = "Powershell Version $psVersion has been detected. The script is running"
  $psSupported = @{
    PsVersion = $psVersion
    Supported = $true
    PsMessage = $psMessage
  }
  $psSupported
}


Function Get-Hash
{
  param(
    [string]$Path
  )

  $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
  $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($Path)))
  $hash.Replace('-','').toLower()
}

If (Test-Path -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai')) 
{
  try 
  {
    Write-Host -Object "Found existing temp dir in $($env:TEMP), trying to delete!"
    Remove-Item -Force -Recurse -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai') -ErrorAction Stop
  }
  catch 
  {
    throw "Temp folder exists and can't be deleted, stopping"
  }
}

Write-Host -Object "Downloading Zip file from github to $(Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai-master.zip')"
(New-Object -TypeName System.Net.WebClient).DownloadFile('http://readonly.configdiscovery.rackspace.com/PoSh-Ohai-master.zip',(Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai-master.zip'))

Write-Host -Object 'Adding ZipStorer Type to decompress downloaded Zip file'
If (-not ('System.IO.Compression.ZipStorer' -as [type])) 
{
  Add-Type -TypeDefinition (New-Object -TypeName System.Net.WebClient).DownloadString('http://readonly.configdiscovery.rackspace.com/ZipStorer.cs') -Language CSharp
}

Write-Host -Object "Decompressing zip file to $env:TEMP"
$zip = [System.IO.Compression.ZipStorer]::Open((Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai-master.zip'),[System.IO.FileAccess]::Read)
$extractSuccessful = $true
foreach ($file in $zip.ReadCentralDir()) 
{
  if ( -not $zip.ExtractFile($file,(Join-Path -Path $env:TEMP -ChildPath $file.FilenameInZip))) 
  {
    $extractSuccessful = $false
  }
}
$zip.Close()


Rename-Item -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai-master') -NewName (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai')
#$manifest = [scriptblock]::Create((Get-Content (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai\PoSh-Ohai.psd1') | Out-String)).Invoke()
$manifest = Test-ModuleManifest -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai\PoSh-Ohai.psd1')

if ($manifest.version -gt (Get-Module -ListAvailable -Name PoSh-Ohai).version) 
{
  Write-Host -Object "Downloaded version ($($manifest.version)) greater than existing version ($( If ((Get-Module -ListAvailable -Name PoSh-Ohai).version) 
    {
           Write-Host (Get-Module -ListAvailable -Name PoSh-Ohai).version
    }
    else 
    {
    'not installed'
  }
  )), trying to copy new version..."
  Remove-Module -Name PoSh-Ohai -ErrorAction SilentlyContinue
  try 
  {
    Copy-Item -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai') -Destination $($env:PSModulePath.Split(';') |
      Where-Object -FilterScript {
        $_.StartsWith($env:SystemRoot)
    }) -Recurse -Force
  }
  catch 
  {
    throw 'The attempt to copy the module to its location failed, stopping'
  }
}
else 
{
  Write-Host -Object "Downloaded version ($($manifest.version)) not greater than existing version ($( If ((Get-Module -ListAvailable -Name PoSh-Ohai).version) 
    {
    (Get-Module -ListAvailable -Name PoSh-Ohai).version
    } else 
    {
    'not installed'
  })), checking plugins for changes..."
  $moduleBase = (Get-Module -ListAvailable -Name PoSh-Ohai).ModuleBase
  $newPlugins = Get-ChildItem -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai\plugins') | ForEach-Object -Process {
    Add-Member -InputObject $_ -MemberType NoteProperty -Name md5 -Value (Get-Hash -Path $_.FullName) -PassThru
  }
  $existingPlugins = Get-ChildItem -Path (Join-Path -Path $moduleBase -ChildPath 'plugins') | ForEach-Object -Process {
    Add-Member -InputObject $_ -MemberType NoteProperty -Name md5 -Value (Get-Hash -Path $_.FullName) -PassThru
  }
  $different = Compare-Object -ReferenceObject $newPlugins -DifferenceObject $existingPlugins -Property md5 -PassThru | Where-Object -FilterScript {
    $_.SideIndicator -eq '<='
  }
  if ($different) 
  {
    Write-Host -Object "The following plugins have been changed or added and will be copied: $(($different | ForEach-Object -Process { $_.name 
    }) -join ', ')"
    $different  | ForEach-Object -Process {
      Copy-Item -Path $_.FullName -Destination (Resolve-Path (Join-Path -Path $moduleBase -ChildPath 'plugins')) 
    }
  }
  Else 
  {
    Write-Host -Object 'No change of plugins detect, nothing to do...'
  }


  $newModule = Get-ChildItem -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai') | ForEach-Object -Process {
    Add-Member -InputObject $_ -MemberType NoteProperty -Name md5 -Value (Get-Hash -Path $_.FullName) -PassThru
  }
  $existingModule = Get-ChildItem -Path (Join-Path -Path $moduleBase) | ForEach-Object -Process {
    Add-Member -InputObject $_ -MemberType NoteProperty -Name md5 -Value (Get-Hash -Path $_.FullName) -PassThru
  }
  $differentModule = Compare-Object -ReferenceObject $newModule -DifferenceObject $existingModule -Property md5 -PassThru | Where-Object -FilterScript {
    $_.SideIndicator -eq '<='
  }
  if ($differentModule) 
  {
    Write-Host -Object "The following module has been changed or added and will be copied: $(($differentModule | ForEach-Object -Process { $_.name 
    }) -join ', ')"
    $differentModule  | ForEach-Object -Process {
      Copy-Item -Path $_.FullName -Destination (Resolve-Path (Join-Path -Path $moduleBase))
    }
  }
  Else 
  {
    Write-Host -Object 'No change of the module detect, nothing to do...'
  }
}



Write-Host -Object 'Done, deleting temp files...'
Remove-Item -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai') -ErrorAction SilentlyContinue -Recurse -Force
Remove-Item -Path (Join-Path -Path $env:TEMP -ChildPath 'PoSh-Ohai-master.zip') -ErrorAction SilentlyContinue -Force
