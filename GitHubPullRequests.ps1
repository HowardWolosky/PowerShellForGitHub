# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubPullRequestTypeName = 'GitHub.PullRequest'
    GitHubCommitTypeName = 'GitHub.Commit'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubPullRequest
{
<#
    .SYNOPSIS
        Retrieve the pull requests in the specified repository.

    .DESCRIPTION
        Retrieve the pull requests in the specified repository.

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
        The specific pull request id to return back.  If not supplied, will return back all
        pull requests for the specified Repository.

    .PARAMETER State
        The state of the pull requests that should be returned back.

    .PARAMETER Head
        Filter pulls by head user and branch name in the format of 'user:ref-name'

    .PARAMETER Base
        Base branch name to filter the pulls by.

    .PARAMETER Sort
        What to sort the results by.
        * created
        * updated
        * popularity (comment count)
        * long-running (age, filtering by pulls updated in the last month)

    .PARAMETER Direction
        The direction to be used for Sort.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

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
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.PullRequest

    .EXAMPLE
        $pullRequests = Get-GitHubPullRequest -Uri 'https://github.com/PowerShell/PowerShellForGitHub'

    .EXAMPLE
        $pullRequests = Get-GitHubPullRequest -OwnerName microsoft -RepositoryName PowerShellForGitHub -State Closed
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
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest,

        [ValidateSet('Open', 'Closed', 'All')]
        [string] $State = 'Open',

        [string] $Head,

        [string] $Base,

        [ValidateSet('Created', 'Updated', 'Popularity', 'LongRunning')]
        [string] $Sort = 'Created',

        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction = 'Descending',

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
        'ProvidedPullRequest' = $PSBoundParameters.ContainsKey('PullRequest')
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/pulls"
    $description = "Getting pull requests for $RepositoryName"
    if ($PSBoundParameters.ContainsKey('PullRequest'))
    {
        $uriFragment = $uriFragment + "/$PullRequest"
        $description = "Getting pull request $PullRequest for $RepositoryName"
    }

    $sortConverter = @{
        'Created' = 'created'
        'Updated' = 'updated'
        'Popularity' = 'popularity'
        'LongRunning' = 'long-running'
    }

    $directionConverter = @{
        'Ascending' = 'asc'
        'Descending' = 'desc'
    }

    $getParams = @(
        "state=$($State.ToLower())",
        "sort=$($sortConverter[$Sort])",
        "direction=$($directionConverter[$Direction])"
    )

    if ($PSBoundParameters.ContainsKey('Head'))
    {
        $getParams += "head=$Head"
    }

    if ($PSBoundParameters.ContainsKey('Base'))
    {
        $getParams += "base=$Base"
    }

    $params = @{
        'UriFragment' = $uriFragment + '?' +  ($getParams -join '&')
        'Description' = $description
        'AcceptHeader' = $script:symmetraAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubPullRequestAdditionalProperties)
}

filter Get-GitHubPullRequestCommit
{
<#
    .SYNOPSIS
        Retrieve the list of commits for the specified pull request.

    .DESCRIPTION
        Retrieve the list of commits for the specified pull request.

        A maximum of 250 commits for a pull request will be returned.

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
        The ID of the pull request ID to return the commits for.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

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
        GitHub.Repository

    .OUTPUTS
        GitHub.Commit

    .EXAMPLE
        Get-GitHubPullRequestCommit -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 39
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubCommitTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('PullRequestNumber')]
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
        'UriFragment' =  "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/commits"
        'Description' =  "Getting commits for pull request $PullRequest"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubCommitAdditionalProperties)
}

function Get-GitHubPullRequestFile
{
<#
    .SYNOPSIS
        Retrieve the list of files in the specified pull request.

    .DESCRIPTION
        Retrieve the list of files in the specified pull request.
        A maximum of 3000 files will be returned.

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
        'UriFragment' =  "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/files"
        'Description' =  "Getting commits for pull request $PullRequest"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

filter New-GitHubPullRequest
{
<#
    .SYNOPSIS
        Create a new pull request in the specified repository.

    .DESCRIPTION
        Opens a new pull request from the given branch into the given branch
        in the specified repository.

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

    .PARAMETER Title
        The title of the pull request to be created.

    .PARAMETER Body
        The text description of the pull request.

    .PARAMETER Issue
        The GitHub issue number to open the pull request to address.

    .PARAMETER Head
        The name of the head branch (the branch containing the changes to be merged).

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
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.PullRequest

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
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements_Title')]
    param(
        [Parameter(ParameterSetName='Elements_Title')]
        [Parameter(ParameterSetName='Elements_Issue')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements_Title')]
        [Parameter(ParameterSetName='Elements_Issue')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri_Title')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri_Issue')]
        [Alias('RepositoryUrl')]
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
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements_Issue')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri_Issue')]

        [Alias('IssueNumber')]
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

    return (Invoke-GHRestMethod @restParams | Add-GitHubPullRequestAdditionalProperties)
}

function Update-GitHubPullRequestBranch
{
<#
    .SYNOPSIS
        Updates the pull request branch with the latest upstream changes by
        merging HEAD from the base branch into the pull request branch.

    .DESCRIPTION
        Updates the pull request branch with the latest upstream changes by
        merging HEAD from the base branch into the pull request branch.

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
        The ID of the pull request to update.

    .PARAMETER Sha
        The expected SHA of the pull request's HEAD ref.  This is the most recent commit on the
        pull request's branch.  If the expected SHA does not match the pull request's HEAD, you
        will receive a 422 exception.  You can use Get-GitHubPullRequestCommit to find the most
        recent commit SHA.  Defaults to the pull request's current HEAD ref.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Update-GitHubPullRequestBranch -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 39
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='Elements')]
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

        [string] $Sha,

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
        'SpecifiedSha' = (-not [String]::IsNullOrWhiteSpace($Sha))
    }

    $hashBody = @{}
    if (-not [String]::IsNullOrWhiteSpace($Sha)) { $hashBody['expected_head_sha'] = $Sha }

    $restParams = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/update-branch"
        'Method' = 'Put'
        'Description' = "Updating the branch for pull request $PullRequest"
        'AcceptHeader' = 'application/vnd.github.lydian-preview+json'
        'Body' = ConvertTo-Json -InputObject $hashBody
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @restParams
}

function Update-GitHubPullRequest
{
<#
    .SYNOPSIS
        Updates the pull request branch with the latest upstream changes by
        merging HEAD from the base branch into the pull request branch.

    .DESCRIPTION
        Updates the pull request branch with the latest upstream changes by
        merging HEAD from the base branch into the pull request branch.

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
        The ID of the pull request to update.

    .PARAMETER Title
        The new title of the pull request.

    .PARAMETER Body
        The new text description for the pull request.

    .PARAMETER State
        The new state for the pull request.

    .PARAMETER Base
        The name of the branch you want your changes pulled into.
        This should be an existing branch on the current repository.
        You cannot update the base branch on a pull request to point to another repository.

    .PARAMETER MaintainerCanModify
        If provided, indicates whether repository maintainers can commit changes to the
        head branch of this pull request.  To disable this, specify the switch with the value $false
        (e.g. -MaintainerCanModify:$false)

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Update-GitHubPullRequestBranch -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 39

    .NOTES
        To open or update a pull request in a public repository, you must have write access to the
        head or the source branch. For organization-owned repositories, you must be a member of
        the organization that owns the repository to open or update a pull request.
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='Elements')]
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

        [string] $Title,

        [string] $Body,

        [ValidateSet('Open', 'Closed')]
        [string] $State,

        [string] $Base,

        [switch] $MaintainerCanModify,

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
        'ProvidedTitle' = (-not [String]::IsNullOrWhiteSpace($Title))
        'ProvidedBody' = (-not [String]::IsNullOrWhiteSpace($Body))
        'ProvidedBase' = (-not [String]::IsNullOrWhiteSpace($Base))
        'ProvidedMaintainerCanModify' = ($MaintainerCanModify.IsPresent)
    }

    $hashBody = @{}
    if (-not [String]::IsNullOrWhiteSpace($Title)) { $hashBody['title'] = $Title }
    if (-not [String]::IsNullOrWhiteSpace($body)) { $hashBody['body'] = $Body }
    if (-not [String]::IsNullOrWhiteSpace($State)) { $hashBody['state'] = $State.ToLower() }
    if (-not [String]::IsNullOrWhiteSpace($Base)) { $hashBody['base'] = $Base }
    if ($MaintainerCanModify.IsPresent) { $hashBody['maintainer_can_modify'] = $MaintainerCanModify.ToBool() }

    $restParams = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest"
        'Method' = 'Patch'
        'Description' = "Updating the pull request $PullRequest"
        'AcceptHeader' = 'application/vnd.github.sailor-v-preview+json'
        'Body' = ConvertTo-Json -InputObject $hashBody
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @restParams
}

function Test-GitHubPullRequestMerged
{
    <#
    .SYNOPSIS
        Checks to see if a pull request on GitHub has been merged.

    .DESCRIPTION
        Checks to see if a pull request on GitHub has been merged.

        Will return $false if the request has not merged, as well as if the pull request is invalid
        or inaccessible.

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
        The ID of the pull request to be merged.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [bool] $true if the pull request exists, is accessible and has been merged.  $false otherwise.

    .EXAMPLE
        Test-GitHubPullRequestMerged -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 39

        Returns back $true because that pull request was merged.

    .EXAMPLE
        Test-GitHubPullRequestMerged -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest [int64]::MaxValue

        Returns back $false because it is unlikely this repo will ever have _that_ many
        pull requests and/or issues.  If it does, I look forward to the day that this example can
        be updated.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
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
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/merge"
        'Method' = 'Get'
        'Description' = "Checking if pull request $PullRequest has been merged"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'ExtendedResult'= $true
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    try
    {
        $response = Invoke-GHRestMethod @params
        return $response.StatusCode -eq 204
    }
    catch
    {
        return $false
    }
}

function Merge-GitHubPullRequest
{
    <#
    .SYNOPSIS
        Merge a pull request on GitHub.  This is the equivalent of hitting the "Merge" button in
        a pull request.

    .DESCRIPTION
        Merge a pull request on GitHub.  This is the equivalent of hitting the "Merge" button in
        a pull request.

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
        The ID of the pull request to be merged.

    .PARAMETER Title
        Title for the automatic commit message.

    .PARAMETER Message
        Extra detail to append to automatic commit message.

    .PARAMETER Sha
        SHA that pull request head must match to allow merge.

    .PARAMETER MergeMethod
        Merge method to use.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .NOTES
        This endpoind triggers notifications.  Creating content too quickly using this endpoint
        may result in abuse rate limiting.

    .EXAMPLE
        Merge-GitHubPullRequest -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -PullRequest 39 -Title 'Add Merge-GitHubPullRequest' -Message 'Adds support for the merge endpoint for pull requests' -sha 1234567890 -Method Squash

        Completes and merges the pull request #39 at SHA 1234567890 using the squash method,
        with the specified commit title and message.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
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

        [ValidateNotNullOrEmpty()]
        [Alias('CommitTitle')]
        [string] $Title,

        [Alias('CommitMessage')]
        [string] $Message,

        [string] $Sha,

        [ValidateSet('Merge', 'Squash', 'Rebase')]
        [string] $MergeMethod = 'Merge',

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
        'SpecifiedSha' = (-not [String]::IsNullOrWhiteSpace($Sha))
    }

    $hashBody = @{
        'merge_method' = $MergeMethod.ToLower()
    }

    if (-not [String]::IsNullOrWhiteSpace($Title)) { $hashBody['commit_title'] = $Title }
    if (-not [String]::IsNullOrWhiteSpace($Message)) { $hashBody['commit_message'] = $Message }
    if (-not [String]::IsNullOrWhiteSpace($Sha)) { $hashBody['sha'] = $Sha }

    $mergeMethodActionWord = @{
        'Merge' = 'Merging'
        'Squash' = 'Squashing'
        'Rebase' = 'Rebasing'
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/pulls/$PullRequest/merge"
        'Method' = 'Put'
        'Description' = "$($mergeMethodActionWord[$MergeMethod]) pull request $PullRequest"
        'Body' = ConvertTo-Json -InputObject $hashBody
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

   return Invoke-GHRestMethod @params
}

filter Add-GitHubPullRequestAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Repository objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubPullRequestTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.html_url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'PullRequestId' -Value $item.id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'PullRequestNumber' -Value $item.number -MemberType NoteProperty -Force

            @('assignee', 'assignees', 'requested_reviewers', 'merged_by', 'user') |
                ForEach-Object {
                    if ($null -ne $item.$_)
                    {
                        $null = Add-GitHubUserAdditionalProperties -InputObject $item.$_
                    }
                }

            if ($null -ne $item.labels)
            {
                $null = Add-GitHubLabelAdditionalProperties -InputObject $item.labels
            }

            if ($null -ne $item.milestone)
            {
                $null = Add-GitHubMilestoneAdditionalProperties -InputObject $item.milestone
            }

            if ($null -ne $item.requested_teams)
            {
                $null = Add-GitHubTeamAdditionalProperties -InputObject $item.requested_teams
            }

            # TODO: What type are item.head and item.base?
        }

        Write-Output $item
    }
}
