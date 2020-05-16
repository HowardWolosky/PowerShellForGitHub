# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubPullRequestReviewRequest
{
<#
    .SYNOPSIS
        Retrieve the review requests for a pull request.

    .DESCRIPTION
        Retrieve the review requests for a pull request.

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

    .PARAMETER PullRequest
        The ID of pull request for which to retrieve the requested reviewers.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [PSCustomObject[]] List of requested reviewers for the specified pull request.

    .EXAMPLE
        Get-GitHubPullRequestReviewRequest -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 39
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias('Get-GitHubReviewRequest')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int64] $PullRequest,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/requested_reviewers"
        'Description' =  "Getting the requested reviewers for pull request $PullRequest"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function New-GitHubPullRequestReviewRequest
{
<#
    .SYNOPSIS
        Create a new review request for a pull request on GitHub.

    .DESCRIPTION
        Create a new review request for a pull request on GitHub.

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

    .PARAMETER PullRequest
        The ID of the pull request ID that the requested reviews are for.

    .PARAMETER Reviewer
        An array of user logins to request reviews from.

    .PARAMETER TeamReviewer
        An array of team slugs to request reviews from.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        Will throw an exception (422) if one or more of the specified reviewers are not collaborators.

    .EXAMPLE
        New-GitHubPullRequestReviewRequest -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 39 -Reviewer @('octocat', 'PowerShellForGitHubTeam')

        Requests a review from 'octocat' and 'PowerShellForGitHubTeam' for the specified pull request.

    .NOTES
        This endpoind triggers notifications.  Creating content too quickly using this endpoint
        may result in abuse rate limiting.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias('New-GitHubReviewRequest')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int64] $PullRequest,

        [string[]] $Reviewer,

        [string[]] $TeamReviewer,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'NumReviewers' = $Reviewer.Count
        'NumTeamReviewers' = $TeamReviewer.Count
    }

    $hashBody = @{}
    if ($Reviewer.Count -gt 0) { $hashBody['reviewers'] = $Reviewer}
    if ($TeamReviewer.Count -gt 0) { $hashBody['team_reviewers'] = $TeamReviewer}

    $params = @{
        'UriFragment' =  "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/requested_reviewers"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Requesting reviews for pull request $PullRequest"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Remove-GitHubPullRequestReviewRequest
{
<#
    .SYNOPSIS
        Remove one or more requested reviewers from a pull request.

    .DESCRIPTION
        Remove one or more requested reviewers from a pull request.

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

    .PARAMETER PullRequest
        The ID of the pull request ID to return the files for.

    .PARAMETER Reviewer
        An array of user logins to remove from request reviews.

    .PARAMETER TeamReviewer
        An array of team slugs to remove from request reviews.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [PSCustomObject[]] List of commits for the specified pull request.

    .EXAMPLE
        Get-GitHubPullRequestFile -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 39
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias('Remove-GitHubReviewRequest')]
    [Alias('Delete-GitHubReviewRequest')]
    [Alias('Delete-GitHubPullRequestReviewRequest')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int64] $PullRequest,

        [string[]] $Reviewer,

        [string[]] $TeamReviewer,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'NumReviewers' = $Reviewer.Count
        'NumTeamReviewers' = $TeamReviewer.Count
    }

    $hashBody = @{}
    if ($Reviewer.Count -gt 0) { $hashBody['reviewers'] = $Reviewer}
    if ($TeamReviewer.Count -gt 0) { $hashBody['team_reviewers'] = $TeamReviewer}

    $params = @{
        'UriFragment' =  "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/requested_reviewers"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Delete'
        'Description' =  "Getting commits for pull request $PullRequest"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}
