# Sitecore Remote Toolset
A powershell library that leverages the Sitecore Powershell Extension Remoting tools, to enable event logging and decoupling of scripts from Sitecores Powershell ISE. 

This was cerated with CI/CD in mind, to allow for script changes to run within a deployment pipeline.

## Summary
Have you ever needed to create a content change or update an exisitng item at a field level accross multiple enviroments? 
With Unicorn you can seralize an entire item and push the changes to each environment, but this overwrites the entire item.

This library gives you the flexability of writing decoupled Powershell scripts for Sitecore that either can run once (unless changes detected) or can be set to always run on execution. 

## Getting started
