PoSh-Ohai
=========

PowerShell interpretation of opscode's Ohai

* Installation
After cpoying the module in the Module directory of your powershell profile, run:
```Import-Module -Name Posh-Ohai```

* Perform a system discovery
Running the command below will discover the server config and return either a JSON or XML data.
```Get-computerComfiguration```