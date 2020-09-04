# Sitecore Remote Toolset
A powershell library that leverages the Sitecore Powershell Extension Remoting tools, to enable event logging and decoupling of scripts from Sitecores Powershell ISE. 

This was cerated with CI/CD in mind, to allow for script changes to run within a deployment pipeline.

## Summary
Have you ever needed to create a content change or update an exisitng item at a field level accross multiple enviroments? 
With Unicorn you can seralize an entire item and push the changes to each environment, but this overwrites the entire item.

This library gives you the flexability of writing decoupled Powershell scripts for Sitecore that either can run once (unless changes detected) or can be set to always run on execution. 

## Getting started

### Prerequisites
- Sitecore Powershell (SPE must be installed on Sitecore first) 
- Download Sitecore Powershell Remoting Library (Default location: .\PowershellExtensions\v{version}\SPE)
- Remoting must be enabled. See example patch config [ShieldsDown.config](./Configs/ShieldsDown.config)

#### Links
- Sitecore Powershell Releases: https://github.com/SitecorePowerShell/Console/releases

### Steps 
1. New Script File
Create a Powershell script within the "_Current" folder. Sub folders are recomened to help categories your scripts. 

2. Write Script
Write the contents of your script. See example [01-Home-Content-Update.ps1](./_Current/02-TestScripts/01-Home-Content-Update.ps1)
The script does not need any connection details or session references to Sitecore. 

3. Execute 
Execute the the SPE-Executer. This will iterate through all scripts and attempt to execute them on the selected environment. 
 - Scripts within "_RunAways" will always be executed. 
 - Scripts within "_Current" will only run *[once per change](#once-per-change). 


## Executing
```
.\SPE-Executer.ps1 ` 
    -SitecoreInstanceUri http://my-sitecore-cm-instance.com `
    -SitecoreUsername "admin" `
    -SitecorePassword "b"
    -PathToSPEModule "{Remoteing-Library-Path}" # Default is .\PowershellExtensions\v5.0\SPE
```

### Deployment Pipeline
This can be setup to execute within a deployment pipeline. 
Cerate a deployment step that allows Powershell script execution and simply per environment deployment change the URI and Sitecore credentials. 


##### *Once per Change
Each time a script is executed on an environment this is logged with hash value of of the script. 
- If an script has already been executed on an environment and not changed, it **won't run again**. 
- If an script has already been executed on an environment and the script contents have been changed, the script **will run again**.