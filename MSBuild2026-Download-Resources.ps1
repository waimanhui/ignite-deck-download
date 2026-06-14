Param (
    ## The directory into which the user wishes to download the files.
    [string]$directory = $PSScriptRoot,
    ## Optional parameter allowing the user to specify the code (or comma separated codes) of the video(s) they wish to download.
    [string]$sessionCodes = "",
    ## Maximum number of concurrent downloads (PowerShell 7+ only).
    [int]$throttleLimit = 5
)

### Variables ###
$api = 'https://api-v2.build.microsoft.com/api/session/all/en-US'

function FetchSessionData() {
    Write-Host "Pulling session data..."
    # Invoke-RestMethod parses JSON directly, skipping the intermediate string conversion
    return Invoke-RestMethod -Uri $api -Method GET -Headers @{ 'Content-Type' = 'application/json' }
}

function FilterSessions($sessions, $sessionCodes) {
    if ($sessionCodes.Length -eq 0) {
        Write-Host "All sessions containing slides will be downloaded"
        return $sessions
    }

    $splitCodes = $sessionCodes.Split(",")
    # Use Where-Object pipeline instead of manual foreach loop
    $filtered = @($sessions | Where-Object { $splitCodes -contains $_.sessionCode })

    if ($filtered.Count -eq 0) {
        Write-Host "None of the session codes entered could be found. This program will now terminate."
        Exit
    }

    $foundCodes = $filtered | Select-Object -ExpandProperty sessionCode
    $notFound = $splitCodes | Where-Object { $foundCodes -notcontains $_ }
    if ($notFound) {
        Write-Host "Some session codes could not be found and will not be downloaded:"
        $notFound | ForEach-Object { Write-Host $_ }
    }

    return $filtered
}

### Main ###
$sessions = FetchSessionData
$sessions = FilterSessions $sessions $sessionCodes

# Pre-filter sessions that have a slide deck before entering the parallel loop
$sessionsWithSlides = @($sessions | Where-Object { $_.slideDeck.Length -ne 0 })
$sessionSearchCount = @($sessions).Count

Write-Host "$($sessionsWithSlides.Count) session(s) with slides found. Starting parallel downloads (throttle: $throttleLimit)..."

# Thread-safe bag to collect metadata from parallel workers
$metaBag = [System.Collections.Concurrent.ConcurrentBag[string]]::new()

$sessionsWithSlides | ForEach-Object -Parallel {
    $s          = $_
    $dir        = $using:directory
    $bag        = $using:metaBag

    $code  = if ($s.sessionCode.Length -ne 0) { $s.sessionCode } else { "NoCodeSession_$([guid]::NewGuid().ToString('N').Substring(0,6))" }
    $title = if ($s.title.Length       -ne 0) { $s.title }       else { "NoTitleSession" }

    Write-Host "===== $title ($code) ====="

    $slideFileDes    = "$dir\$code.pptx"
    $slideFileNested = "$dir\$code\$code.pptx"

    if (!(Test-Path $slideFileNested)) {
        Write-Host "Downloading slides for: $title ($code)"
        Start-BitsTransfer -Source $s.slideDeck -Destination $slideFileDes
    } else {
        Write-Host "Slides exist: $slideFileNested"
    }

    # Build metadata entry and add to thread-safe collection
    $entry  = "Session ID: $($s.sessionId)`tSession Code: $code`tSession Title: $title`r"
    $entry += "Session Description: $($s.description)`r`n`r`n"
    $bag.Add($entry)

    Write-Host "Done: $title ($code)`r`n"
} -ThrottleLimit $throttleLimit

# Write all collected metadata at once using a List (avoids repeated string concatenation)
$dataFile = "$directory\download-report.txt"
[System.Collections.Generic.List[string]]$lines = $metaBag
$lines | Out-File -FilePath $dataFile -Encoding ASCII

Write-Host "$sessionSearchCount session(s) searched."
Write-Host "$($sessionsWithSlides.Count) session(s) downloaded."
