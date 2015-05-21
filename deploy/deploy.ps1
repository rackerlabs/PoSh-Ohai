#requires -Version 2

#region Variables
$PoshOhaiModuleVersionLatest = '1.4.1'
$TempDir = 'C:\rs-pkgs'
$ModuleDir = $env:PSModulePath.Split(';') | Where-Object -FilterScript {
    $_.StartsWith($env:SystemRoot)
}

$PoshOhaiUrl = 'http://readonly.configdiscovery.rackspace.com/PoSh-Ohai-master.zip'
$PoshOhaiFile = 'PoSh-Ohai-master.zip'
$ZipStoreUrl = 'http://readonly.configdiscovery.rackspace.com/ZipStorer.cs'
#endregion


#region Functions
function Get-PowershellVersion
{
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
}

function Invoke-FileDownload
{
    Param
    (
        $DownloadUrl,
        $DestinationPath
    )
    Write-Output -InputObject "[$(Get-Date)] Status :: Downloading Zip file from $DownloadUrl to $DestinationPath"
    
    try
    {
        (New-Object -TypeName System.Net.WebClient).DownloadFile($DownloadUrl,$DestinationPath)
        Write-Output -InputObject "[$(Get-Date)] Status :: The Zip file was downloaded from $DownloadUrl to $DestinationPath"
    }
    catch
    {
        Write-Output -InputObject "[$(Get-Date)] Error  :: Error downloading the file $DownloadUrl"
        Write-Output -InputObject "[$(Get-Date)] Details:: $_"
    }
}

function Invoke-ZipStorer
{
    Param
    (
        $ZipStoreUrl,
        $DestinationPath,
        $ZipFileName
        
    )
    Write-Host -Object 'Adding ZipStorer Type to decompress downloaded Zip file'
    try
    {
        If (-not ('System.IO.Compression.ZipStorer' -as [type])) 
        {
            Add-Type -TypeDefinition (New-Object -TypeName System.Net.WebClient).DownloadString($ZipStoreUrl) -Language CSharp
        }
        Write-Output -InputObject "[$(Get-Date)] Status :: The Zipstorer assembly has been loaded"
    }
    Catch
    {
        Write-Output -InputObject "[$(Get-Date)] Error  ::  Failed to download zipstore'"
        Write-Output -InputObject "[$(Get-Date)] Details:: $_"     
    }

    Write-Output -InputObject "[$(Get-Date)] Status :: Decompressing zip file to $DestinationPath"
    try
    {
        $zip = [System.IO.Compression.ZipStorer]::Open((Join-Path -Path $DestinationPath -ChildPath $ZipFileName),[System.IO.FileAccess]::Read)
        $extractSuccessful = $true
        foreach ($file in $zip.ReadCentralDir()) 
        {
            if ( -not $zip.ExtractFile($file,(Join-Path -Path $DestinationPath -ChildPath $file.FilenameInZip))) 
            {
                $extractSuccessful = $false
            }
        }
        $zip.Close()
        Write-Output -InputObject "[$(Get-Date)] Status :: The zip file $ZipFileName was decompressed to $DestinationPath"
    }
    catch
    {
        Write-Output -InputObject "[$(Get-Date)] Error  ::  Unzipping failed"
        Write-Output -InputObject "[$(Get-Date)] Details:: $_"      
    }
}

function Remove-ModuleDirectory
{
    Param(
        $Path
    )
    If (Test-Path -Path $Path) 
    {
        try 
        {
            Write-Output -InputObject "[$(Get-Date)] Status :: Found existing directory in $Path, trying to delete!"
            Remove-Item -Force -Recurse -Path $Path -ErrorAction Stop
            Write-Output -InputObject "[$(Get-Date)] Status :: The directory $Path was deleted"
        }
        catch 
        {
            Write-Output -InputObject "[$(Get-Date)] Error  ::  $Path exists and can't be deleted, stopping"
            Write-Output -InputObject "[$(Get-Date)] Details:: $_"          
        }
    }
}

function Install-PoshOhai
{
    Param(
        $ModuleDirectory,
        $TempDirectory
    )
    try
    {
        Remove-Module -Name PoSh-Ohai -ErrorAction SilentlyContinue
        Remove-ModuleDirectory -Path (Join-Path -Path $TempDirectory -ChildPath 'PoSh-Ohai')
        Invoke-FileDownload -DownloadUrl $PoshOhaiUrl -DestinationPath (Join-Path -Path $TempDirectory -ChildPath 'PoSh-Ohai-master.zip')
        Invoke-ZipStorer -ZipStoreUrl $ZipStoreUrl -DestinationPath $TempDirectory -ZipFileName $PoshOhaiFile

        Write-Output -InputObject "[$(Get-Date)] Status :: Renaming PoSh-Ohai-master to PoSh-Ohai"
        Rename-Item -Path (Join-Path -Path $TempDirectory -ChildPath 'PoSh-Ohai-master') -NewName (Join-Path -Path $TempDirectory -ChildPath 'PoSh-Ohai')

        Write-Output -InputObject "[$(Get-Date)] Status :: Copying Posh-Ohai to the $ModuleDirectory"
        Copy-Item -Path (Join-Path -Path $TempDirectory -ChildPath 'PoSh-Ohai') -Destination $ModuleDirectory -Recurse -Force
        
        Write-Output -InputObject "[$(Get-Date)] Status :: Posh-Ohai $((Get-Module -ListAvailable -Name PoSh-Ohai).version) has been installed"
    }
    catch
    {
        Write-Output -InputObject "[$(Get-Date)] Error  ::  Posh-Ohai installation failed'"
        Write-Output -InputObject "[$(Get-Date)] Details:: $_"
    }
}

function Remove-TempFiles
{
    try
    {
        Write-Output -InputObject "[$(Get-Date)] Status :: Deleting Posh-Ohai temp files"
        Remove-Item -Path (Join-Path -Path $TempDir -ChildPath 'PoSh-Ohai') -ErrorAction SilentlyContinue -Recurse -Force
        Remove-Item -Path (Join-Path -Path $TempDir -ChildPath 'PoSh-Ohai-master.zip') -ErrorAction SilentlyContinue -Force
        Write-Output -InputObject "[$(Get-Date)] Status :: Done..."
    }
    catch
    {
        Write-Output -InputObject "[$(Get-Date)] Error  ::  Posh-Ohai installation failed'"
        Write-Output -InputObject "[$(Get-Date)] Details:: $_"    
    }
}

#endregion


#region MAIN
Get-PowershellVersion
$PoshOhaiModuleVersionInstalled = (Get-Module -ListAvailable -Name PoSh-Ohai).version

if ($PoshOhaiModuleVersionInstalled -eq $null)
{
    Write-Output -InputObject "[$(Get-Date)] Status :: The latest version $PoshOhaiModuleVersionLatest of Posh-Ohai is not installed"
    Install-PoshOhai -ModuleDirectory $ModuleDir -TempDirectory $TempDir
    Remove-TempFiles
}
elseif($PoshOhaiModuleVersionLatest -eq $($PoshOhaiModuleVersionInstalled.tostring()))
{
    Write-Output -InputObject "[$(Get-Date)] Status :: The latest version $PoshOhaiModuleVersionLatest of Posh-Ohai matches the installed version $PoshOhaiModuleVersionInstalled"
}
else
{
    Install-PoshOhai -ModuleDirectory $ModuleDir -TempDirectory $TempDir
    Remove-TempFiles
}

#endregion