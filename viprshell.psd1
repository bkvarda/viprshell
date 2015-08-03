#
# Module manifest for module 'viprshell'
#
# Generated by: Brandon Kvarda
#
# Generated on: 8/3/2015
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'viprshell'

# Version number of this module.
ModuleVersion = '1.0'

# ID used to uniquely identify this module
GUID = '67b7fb41-4a0a-40c7-abe5-81e7e0af1235'

# Author of this module
Author = 'Brandon Kvarda'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 8/3/2015 Brandon Kvarda'

# Description of the functionality provided by this module
Description = 'Powershell Functions for Working with the ViPR REST API'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
DotNetFrameworkVersion = '4.5'

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = 'New-ViPRProxyToken', 'New-ViprProxyUserAuthToken', 'Get-ViPRTenant', 'Get-ViPRProject', 'Get-ViPRHost', 'Get-ViprExportGroup', 'Get-ViPRVolume', 'Get-ViPRVolumes', 'Get-ViPRVolumeTags', 'Set-ViPRVolumeTag', 'Get-ViPRSnapshot', 'Get-ViPRSnapshotsByParent', 'Get-ViPRSnapshotTags', 'Set-ViPRSnapshotTag',
                    'Get-ViPRSnapshotExports', 'Get-ViPROrder', 'New-ViPRSnapshot-Order', 'Remove-ViprSnapshot-Order', 'Export-ViPRSnapshot-Order', 'Unexport-ViPRSnapshot-Order', 'Mount-ViPRWindowsVolume-Order', 'Unmount-ViPRWindowsVolume-Order', 'Get-ViPROrderStatus'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

