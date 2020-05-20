# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubPullRequestReview
{
<#
    .SYNOPSIS
        Retrieve the reviews for a specific pull request.

    .DESCRIPTION
        Retrieve the reviews for a specific pull request.

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
        The ID of the specific pull request to return back reviews for.

    .PARAMETER Review
        The ID of the specific pull request review to return back.  If not supplied,
        will return back all  pull requests for the specified pull request.

    .PARAMETER Comments
        If specified, will return back the comments for the specified pull request review.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [PSCustomObject[]] List of reviews for a specific pull request.

    .EXAMPLE
        $reviews = Get-GitHubPullRequestReview -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 53

    .EXAMPLE
        $review = Get-GitHubPullRequestReview -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 53 -Review 178574729

    .EXAMPLE
        $review = Get-GitHubPullRequestReview -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 59 -Review 181584921 -Comments

        Gets the comments for the review 181584921 on pull request 59 for microsoft/PowerShellForGitHub.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='ElementsAll')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='ElementsAll')]
        [Parameter(ParameterSetName='ElementsSpecific')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='ElementsAll')]
        [Parameter(ParameterSetName='ElementsSpecific')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='UriAll')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriSpecific')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int64] $PullRequest,

        [Parameter(ParameterSetName='ElementsAll')]
        [Parameter(ParameterSetName='UriAll')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsSpecific')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriSpecific')]
        [int64] $Review,

        [Parameter(ParameterSetName='ElementsSpecific')]
        [Parameter(ParameterSetName='UriSpecific')]
        [switch] $Comments,

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
        'ProvidedReview' = $PSBoundParameters.ContainsKey('Review')
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/reviews"
    $description = "Getting reviews for pull request $PullRequest"
    if ($PSBoundParameters.ContainsKey('Review'))
    {
        $uriFragment = $uriFragment + "/$Review"
        $description = "Getting review $Review for pull request $PullRequest"

        if ($Comments)
        {
            $uriFragment = $uriFragment + "/comments"
            $description = "Getting the comments from review $Review for pull request $PullRequest"
        }
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function Remove-GitHubPullRequestReview
{
<#
    .SYNOPSIS
        Deletes a pending review for the specified pull request.

    .DESCRIPTION
        Deletes a pending review for the specified pull request.

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
        The ID of the pull request to delete the pending review from.

    .PARAMETER Review
        The ID of the pending review to delete from the pull request.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubPullRequestReview -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 53 -Review 178574729
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact = 'High')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias('Delete-GitHubPullRequestReview')]
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

        [Parameter(Mandatory)]
        [int64] $Review,

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

    if ($PSCmdlet.ShouldProcess($Review, "Remove review"))
    {
        $params = @{
            'UriFragment' =  "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/reviews/$Review"
            'Method' = 'Delete'
            'Description' =  "Deleting review $Review for pull request $PullRequest"
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
    }
}

function New-GitHubPullRequestReview
{
<#
    .SYNOPSIS
        Create a new pull request in the specified repository.

    .DESCRIPTION
        Opens a new pull request from the given branch into the given branch in the specified repository.

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
        The ID of the pull request that the review is for.

    .PARAMETER Commit
        The SHA of the commit that needs a review.
        Not using the latest commit SHA may render your review comment outdated if a subsequent
        commit modifies the line you specify as the position.
        Defaults to the most recent commit in the pull request when you do not specify a value.

    .PARAMETER Body
        The body text of the pull request review.
        This must be provided when setting Event to RequestChanges or Comment.

    .PARAMETER Event
        The review action you want to perform.
        By leaving this blank, you set the review action state to PENDING, which means you will
        need to submit the pull request review when you are ready.

    .PARAMETER Comment
        Array of draft review comment objects.

        May also include the name of the owner fork, in the form "${fork}:${branch}".

    .PARAMETER Base
        The name of the target branch of the pull request
        (where the changes in the head will be merged to).

    .PARAMETER HeadOwner
        The name of fork that the change is coming from.

        Used as the prefix of $Head parameter in the form "${HeadOwner}:${Head}".

        If unspecified, the unprefixed branch name is used,
        creating a pull request from the $OwnerName fork of the repository.

    .PARAMETER MaintainerCanModify
        If set, allows repository maintainers to commit changes to the
        head branch of this pull request.

    .PARAMETER Draft
        If set, opens the pull request as a draft.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [PSCustomObject] An object describing the created pull request.

    .EXAMPLE
        $prParams = @{
            OwnerName = 'Microsoft'
            Repository = 'PowerShellForGitHub'
            Title = 'Add simple file to root'
            Head = 'octocat:simple-file'
            Base = 'master'
            Body = "Adds a simple text file to the repository root.`n`nThis is an automated PR!"
            MaintainerCanModify = $true
        }
        $pr = New-GitHubPullRequest @prParams

    .EXAMPLE
        New-GitHubPullRequest -Uri 'https://github.com/PowerShell/PSScriptAnalyzer' -Title 'Add test' -Head simple-test -HeadOwner octocat -Base development -Draft -MaintainerCanModify

    .EXAMPLE
        New-GitHubPullRequest -Uri 'https://github.com/PowerShell/PSScriptAnalyzer' -Issue 642 -Head simple-test -HeadOwner octocat -Base development -Draft

    .NOTES
        This endpoind triggers notifications.  Creating content too quickly using this endpoint
        may result in abuse rate limiting.
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='Elements_Title')]
    param(
        [Parameter(ParameterSetName='Elements_Title')]
        [Parameter(ParameterSetName='Elements_Issue')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements_Title')]
        [Parameter(ParameterSetName='Elements_Issue')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri_Title')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri_Issue')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements_Title')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri_Title')]
        [ValidateNotNullOrEmpty()]
        [string] $Title,

        [Parameter(ParameterSetName='Elements_Title')]
        [Parameter(ParameterSetName='Uri_Title')]
        [string] $Body,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements_Issue')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri_Issue')]
        [int64] $Issue,

        [Parameter(Mandatory)]
        [string] $Head,

        [Parameter(Mandatory)]
        [string] $Base,

        [string] $HeadOwner,

        [switch] $MaintainerCanModify,

        [switch] $Draft,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    if (-not [string]::IsNullOrWhiteSpace($HeadOwner))
    {
        if ($Head.Contains(':'))
        {
            $message = "`$Head ('$Head') was specified with an owner prefix, but `$HeadOwner ('$HeadOwner') was also specified." +
                " Either specify `$Head in '<owner>:<branch>' format, or set `$Head = '<branch>' and `$HeadOwner = '<owner>'."

            Write-Log -Message $message -Level Error
            throw $message
        }

        # $Head does not contain ':' - add the owner fork prefix
        $Head = "${HeadOwner}:${Head}"
    }

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/pulls"

    $hashBody = @{
        'head' = $Head
        'base' = $Base
    }

    if ($PSBoundParameters.ContainsKey('Title'))
    {
        $description = "Creating pull request $Title in $RepositoryName"
        $hashBody['title'] = $Title

        # Body may be whitespace, although this might not be useful
        if ($Body)
        {
            $hashBody['body'] = $Body
        }
    }
    else
    {
        $description = "Creating pull request for issue $Issue in $RepositoryName"
        $hashBody['issue'] = $Issue
    }

    if ($MaintainerCanModify)
    {
        $hashBody['maintainer_can_modify'] = $true
    }

    if ($Draft)
    {
        $hashBody['draft'] = $true
        $acceptHeader = 'application/vnd.github.shadow-cat-preview+json'
    }

    $restParams = @{
        'UriFragment' = $uriFragment
        'Method' = 'Post'
        'Description' = $description
        'Body' = ConvertTo-Json -InputObject $hashBody -Compress
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    if ($acceptHeader)
    {
        $restParams['AcceptHeader'] = $acceptHeader
    }

    return Invoke-GHRestMethod @restParams
}

function Update-GitHubPullRequestReview
{
<#
    .SYNOPSIS
        Updates a review on the specified pull request.

    .DESCRIPTION
        Updates a review on the specified pull request.

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
        The ID of the specific pull request that the review is for.

    .PARAMETER Review
        The ID of the specific pull request review to update the text for.

    .PARAMETER Comment
        The new text for the main comment body of the specified review.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Update-GitHubPullRequestReview -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 53 -Review 178574729 -Comment 'New review text'
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
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

        [Parameter(Mandatory)]
        [int64] $Review,

        [Parameter(Mandatory)]
        [string] $Comment,

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

    $hashBody = @{
        'body' = $Comment
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/reviews/$Review"
        'Method' = 'Put'
        'Description' =  $description
        'Body' = ConvertTo-Json -InputObject $hashBody -Compress
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}


function Clear-GitHubPullRequestReview
{
<#
    .SYNOPSIS
        Dismisses a specific pull request review.

    .DESCRIPTION
        Dismisses a specific pull request review.

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
        The ID of the pull request that the review is for.

    .PARAMETER Review
        The ID of the review to dismiss.

    .PARAMETER Message
        The message for the pull request review dismissal.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Dismiss-GitHubPullRequestReview -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 53 -Review 178574729 -Message 'Not relevant'

    .NOTES
        To dismiss a pull request review on a protected branch, you must be a repository
        administrator or be included in the list of people or teams who can dismiss
        pull request reviews.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias('Dismiss-GitHubPullRequestReview')]
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

        [Parameter(Mandatory)]
        [int64] $Review,

        [Parameter(Mandatory)]
        [string] $Message,

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

    $hashBody = @{
        'message' = $Message
    }

    $params = @{
        'UriFragment' =  "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/reviews/$Review/dismissals"
        'Method' = 'Put'
        'Description' =  "Dismissing review $Review for pull request $PullRequest"
        'Body' = ConvertTo-Json -InputObject $hashBody -Compress
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}