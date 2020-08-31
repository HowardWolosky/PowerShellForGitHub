# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubReferenceTypeName = 'GitHub.Reference'
    GitHubTagTypeName = 'GitHub.Tag'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubReference
{
<#
    .SYNOPSIS
        Retrieve a reference from a given GitHub repository.

    .DESCRIPTION
        Retrieve a reference from a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER TagName
        The name of the Tag to be retrieved.

    .PARAMETER BranchName
        The name of the Branch to be retrieved.

    .PARAMETER MatchPrefix
        When specified, this will return all references from the Git repository that start with the
        provided BranchName or TagName.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api. Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        GitHub.Reference

    .EXAMPLE
        Get-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName powershellTagV1

    .EXAMPLE
        Get-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName master

    .EXAMPLE
        Get-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName '0.' -MatchPrefix

        Returns all of the references that have a tag which begins with "0."

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubReference

        You can also pipe in the output from a previous command. In this case, this will return
        back all of the references in the microsoft/PowerShellForGitHub repository.

#>
    [CmdletBinding(DefaultParameterSetName='Uri')]
    [OutputType({$script:GitHubReferenceTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagElements')]
        [string] $TagName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchElements')]
        [string] $BranchName,

        [Parameter(ParameterSetName='BranchUri')]
        [Parameter(ParameterSetName='BranchElements')]
        [Parameter(ParameterSetName='TagUri')]
        [Parameter(ParameterSetName='TagElements')]
        [switch] $MatchPrefix,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git"
    $reference = Resolve-GitHubReference -TagName $TagName -BranchName $BranchName

    if ([String]::IsNullOrEmpty($reference))
    {
        # Invoke-GHRestMethod removes the last trailing slash.
        # Calling this endpoint without the slash causes a 404, so we must add an extra slash at
        # the end to ensure we have it.
        $uriFragment = $uriFragment + "/matching-refs//"
        $description = "Getting all references for $RepositoryName"
    }
    elseif ($MatchPrefix)
    {
        $uriFragment = $uriFragment + "/matching-refs/$reference"
        $description = "Getting references matching $reference for $RepositoryName"
    }
    else
    {
        $uriFragment = $uriFragment + "/ref/$reference"
        $description = "Getting reference $reference for $RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubReferenceAdditionalProperties)
}

filter New-GitHubReference
{
    <#
    .SYNOPSIS
        Create a reference in a given GitHub repository.

    .DESCRIPTION
        Create a reference in a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER TagName
        The name of the Tag to be created.

    .PARAMETER BranchName
        The name of the Branch to be created.

    .PARAMETER Sha
        The SHA1 value for the reference to be created.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        GitHub.Reference

    .EXAMPLE
        New-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName powershellTagV1 -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

    .EXAMPLE
        New-GitHubReference  -Uri https://github.com/You/YourRepo -BranchName master -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | New-GitHubReference -BranchName release -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

        Create a new branch named "release" in the given repository
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType({$script:GitHubReferenceTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName='TagUri')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $TagName,

        [Parameter(
            Mandatory,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [string] $BranchName,

        [Parameter(Mandatory)]
        [string] $Sha,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $reference = Resolve-GitHubReference -TagName $TagName -BranchName $BranchName

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs"
    $description = "Creating Reference $reference for $RepositoryName from SHA $Sha"

    $hashBody = @{
        'ref' = "refs/" + $reference
        'sha' = $Sha
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Post'
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if (-not $PSCmdlet.ShouldProcess($reference, "Create reference from SHA $Sha"))
    {
        return
    }

    return (Invoke-GHRestMethod @params | Add-GitHubReferenceAdditionalProperties)
}

filter Set-GithubReference
{
    <#
    .SYNOPSIS
        Update a reference in a given GitHub repository.

    .DESCRIPTION
        Update a reference in a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER TagName
        The name of the tag to be updated to the given SHA.

    .PARAMETER BranchName
        The name of the branch to be updated to the given SHA.

    .PARAMETER Sha
        The updated SHA1 value to be set for this reference.

    .PARAMETER Force
        If not set, the update will only occur if it is a fast-forward update.
        Not specifying this (or setting it to $false) will make sure you're not overwriting work.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

     .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        Github.Reference
        GitHub.Repository

    .OUTPUTS
        GitHub.Reference

    .EXAMPLE
        Set-GithubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName myBranch -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

    .EXAMPLE
        Set-GithubReference -Uri https://github.com/You/YourRepo -TagName myTag -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

    .EXAMPLE
        Set-GithubReference -Uri https://github.com/You/YourRepo -TagName myTag -Sha aa218f56b14c9653891f9e74264a383fa43fefbd -Force

        Force an update even if it is not a fast-forward update

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $ref = $repo | Get-GitHubReference -BranchName powershell
        $ref | Set-GithubReference -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

        Get the "powershell" branch from the given repo and update its SHA
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Uri')]
    [OutputType({$script:GitHubReferenceTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagElements')]
        [string] $TagName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchElements')]
        [string] $BranchName,

        [Parameter(Mandatory)]
        [string] $Sha,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $reference = Resolve-GitHubReference -TagName $TagName -BranchName $BranchName

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/$reference"
    $description = "Updating SHA for Reference $reference in $RepositoryName to $Sha"

    $hashBody = @{
        'force' = $Force.IsPresent
        'sha' = $Sha
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Patch'
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    if (-not $PSCmdlet.ShouldProcess($Sha, "Update Sha for $reference"))
    {
        return
    }

    return (Invoke-GHRestMethod @params | Add-GitHubReferenceAdditionalProperties)
}

filter Remove-GitHubReference
{
    <#
    .SYNOPSIS
        Delete a reference in a given GitHub repository.

    .DESCRIPTION
        Delete a reference in a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER TagName
        The name of the tag to be deleted.

    .PARAMETER BranchName
        The name of the branch to be deleted.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        Github.Reference
        GitHub.Repository

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName powershellTagV1

    .EXAMPLE
        Remove-GitHubReference -Uri https://github.com/You/YourRepo -BranchName master

    .EXAMPLE
        Remove-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName milestone1 -Confirm:$false
        Remove the tag milestone1 without prompting for confirmation

    .EXAMPLE
        Remove-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName milestone1 -Force
        Remove the tag milestone1 without prompting for confirmation

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $ref = $repo | Get-GitHubReference -TagName powershellV1
        $ref | Remove-GithubReference

        Get a reference to the "powershellV1" tag using Get-GithubReference on the repository. Pass it to this method in order to remove it
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact="High")]
    [Alias('Delete-GitHubReference')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagElements')]
        [string] $TagName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchElements')]
        [string] $BranchName,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $reference = Resolve-GitHubReference -TagName $TagName -BranchName $BranchName

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($reference, "Remove reference"))
    {
        return
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/$reference"
    $description = "Deleting Reference $reference from repository $RepositoryName"

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Delete'
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Add-GitHubReferenceAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Reference objects
        (which includes GitHub.Branch and GitHub.Tag as well).

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Branch
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject
    )

    foreach ($item in $InputObject)
    {
        # It will always be a GitHub.Reference
        $item.PSObject.TypeNames.Insert(0, $script:GitHubReferenceTypeName)

        # However, depending on what the ref is, it will _also_ be a Branch or a Tag type as well.
        if ($item.ref.StartsWith('refs/heads/'))
        {
            $item.PSObject.TypeNames.Insert(0, $script:GitHubBranchTypeName)
        }
        elseif ($item.ref.StartsWith('refs/tags/'))
        {
            $item.PSObject.TypeNames.Insert(0, $script:GitHubTagTypeName)
        }

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if ($null -ne $item.url)
            {
                $elements = Split-GitHubUri -Uri $item.url
            }
            else
            {
                $elements = Split-GitHubUri -Uri $item.commit.url
            }

            $repositoryUrl = Join-GitHubUri @elements

            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force


            if ($item.ref.StartsWith('refs/heads/'))
            {
                $branchName = $item.ref -replace ('refs/heads/', '')
                Add-Member -InputObject $item -Name 'BranchName' -Value $branchName -MemberType NoteProperty -Force
            }
            elseif ($item.ref.StartsWith('refs/tags'))
            {
                $tagName = $item.ref -replace ('refs/tags/', '')
                Add-Member -InputObject $item -Name 'TagName' -Value $tagName -MemberType NoteProperty -Force
            }
            else
            {
                Add-Member -InputObject $item -Name 'BranchName' -Value $item.name -MemberType NoteProperty -Force
            }

            if ($null -ne $item.commit)
            {
                Add-Member -InputObject $item -Name 'Sha' -Value $item.commit.sha -MemberType NoteProperty -Force
            }
            elseif ($null -ne $item.object)
            {
                Add-Member -InputObject $item -Name 'Sha' -Value $item.object.sha -MemberType NoteProperty -Force
            }
        }

        Write-Output $item
    }
}

filter Resolve-GitHubReference
{
    <#
    .SYNOPSIS
        Get the given tag or branch in the form of a Github reference.

    .DESCRIPTION
        Get the given tag or branch in the form of a Github reference
        (e.g. tags/<TAG> for a tag and heads/<BRANCH> for a branch).

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER TagName
        The tag for which we need the reference string

    .PARAMETER BranchName
        The branch for which we need the reference string

    .OUTPUTS
        System.String

    .EXAMPLE
        Resolve-GitHubReference -TagName powershellTag

    .EXAMPLE
        Resolve-GitHubReference -BranchName powershellBranch
    #>
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([String])]
    param(
        [string] $TagName,

        [string] $BranchName
    )

    if ((-not [String]::IsNullOrEmpty($TagName)) -and (-not [String]::IsNullOrEmpty($BranchName)))
    {
        $message = "Can't resolve _both_ a tag and branch reference at the same time."
        Write-Log -Message $message -Level Error
        throw $message
    }

    if (-not [String]::IsNullOrEmpty($TagName))
    {
        return "tags/$TagName"
    }
    else
    {
        return "heads/$BranchName"
    }

    return [String]::Empty
}