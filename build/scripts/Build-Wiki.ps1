<#
    .SYNOPSIS
        Builds the markdown documentation for the module.

    .DESCRIPTION
        The Build-Wiki script is used to build the markdown documentation for the module. this uses functions
        from the PlatyPS PowerShell Module to build the markdown from the PowerShell comment based help in the module.

    .EXAMPLE
        Build-Wiki

    .PARAMETER Path
        Specifies the output path for the function markdown files.

    .PARAMETER WikiHomePage
        Specifies the output path for the main module markdown file.

    .PARAMETER ModulePath
        Specifies the path of the main module.

    .PARAMETER Description
        Specifies the description for the module.

    .INPUTS
        None

    .OUTPUTS
        System.IO.FileInfo[]
#>
[CmdletBinding()]
param
(
    [Parameter()]
    [System.String]
    $Path = 'docs',

    [Parameter()]
    [System.String]
    $WikiHomePage = 'HOME.md',

    [Parameter()]
    [System.String]
    $ModulePath = '..\..\PowerShellForGitHub',

    [Parameter()]
    [System.String]
    $Description = 'PowerShellForGitHub is a PowerShell module that provides command-line interaction and '+
        'automation for the [GitHub v3 API](https://developer.github.com/v3/).'
)

Function Remove-MetaData
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String[]]
        $Content
    )

    $inMetadataBlock = $false
    $newContent = @()
    foreach ($line in $Content)
    {
        if ($line -eq '---')
        {
            if ($inMetadataBlock)
            {
                $inMetadataBlock = $false
            }
            else
            {
                $inMetadataBlock = $true
            }
        }
        else
        {
            if (!$inMetadataBlock)
            {
                $newContent += $line
            }
        }
    }

    return $newContent
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 1.0

Write-Verbose -Message 'Installing PlatyPS Module'
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force -Verbose:$false | Out-Null
Install-Module PlatyPS -Scope CurrentUser -Force

If (Test-Path -Path $Path)
{
    Write-Verbose -Message "Removing the current $Path directory"
    Remove-Item -Path $Path -Recurse
}

$module = Import-Module -Name $ModulePath -Force -PassThru -Verbose:$false

Write-Verbose -Message "Creating the new module markdown help files in $Path"
New-MarkdownHelp -Module $module.Name -OutputFolder $Path -UseFullTypeName -AlphabeticParamsOrder `
    -WithModulePage -ModulePagePath $WikiHomePage -Force -FwLink 'N/A'
Update-MarkdownHelpModule -Path $Path -RefreshModulePage -ModulePagePath $WikiHomePage -AlphabeticParamsOrder `
    -UseFullTypeName | Out-Null

Write-Verbose -Message "Getting contents of $WikiHomePage file"
$wikiHomePageContent = Get-Content -Path $WikiHomePage

Write-Verbose -Message 'Fixing README Markdown links'
$wikiHomePageContent = $wikiHomePageContent.Replace('.md)', ')')

Write-Verbose -Message 'Updating README module description'
$descriptionMarker = '{{ Fill in the Description }}'
$wikiHomePageContent = $wikiHomePageContent.Replace($descriptionMarker, $description)

Write-Verbose -Message 'Removing README Metadata'
$newWikiHomePageContent = Remove-MetaData -Content $wikiHomePageContent

Write-Verbose -Message "Writing updated $WikiHomePage file"
$newWikiHomePageContent | Out-File -FilePath $WikiHomePage -Encoding ascii

Write-Verbose -Message 'Intialising SideBar Content'
$sideBarContent = @()
$sideBarContent += "### $($module.Name) Module"
$sideBarContent += ''

Write-Verbose -Message 'Removing Metadata from function markdown files'
$functionMdFiles = Get-ChildItem -Path $Path -Filter '*.md'

foreach ($functionMdFile in $functionMdFiles)
{
    $functionMdFileContent = Get-Content -Path $functionMdFile.FullName
    $newFunctionMdFileContent = Remove-MetaData -Content $functionMdFileContent

    $newFunctionMdFileContent | Out-File -FilePath $functionMdFile.FullName -Encoding ascii

    $sideBarContent += "- [$($functionMdFile.BaseName)]($($functionMdFile.BaseName))"
}

Write-Verbose -Message 'Creating Sidebar Page'
$sideBarContent | Out-File -FilePath '_Sidebar.md' -Encoding ascii -Force

Write-Verbose -Message 'Creating Footer Page'
New-Item -Path '_Footer.md' -ItemType File -Force