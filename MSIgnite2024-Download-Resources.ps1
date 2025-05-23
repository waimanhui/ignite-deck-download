Param (
    ## The directory into which the user wishes to download the files.
    [string]$directory = $PSScriptRoot,
    ## Optional parameter allowing the user to specifiy the code (or comma seperated codes) of the video(s) they wish to download.
    [string]$sessionCodes = ""
)

### Variables ###
$api = 'https://api-v2.ignite.microsoft.com/api/session/all/en-US'

function FetchSessionData() {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host("Pulling session data...");

    $Headers = @{
        'Content-Type'  = 'application/json'
    }

    $sessionsJson = Invoke-WebRequest -Uri $api -Headers $Headers -Method 'GET';
    $sessions = $sessionsJson | ConvertFrom-Json;
    return $sessions
}

function FilterSessions($sessions, $sessionCodes) {
    if ($sessionCodes.length -eq 0) {
        Write-Host("All sessions containing slides will be downloaded");
        return $sessions;
    }
    else {
        $splitSessionCodes = $sessionCodes.Split(",");
        $filteredSessions = @();
        $codesOfSessionsFound = @();
        foreach ($s in $sessions) {
            if ($splitSessionCodes -contains $s.sessionCode) {
                $filteredSessions += $s;
                $codesOfSessionsFound += $s.sessionCode;
            }
        }
        if ($filteredSessions.Count -eq 0) {
            Write-Host("None of the session codes entered could be found. This program will now terminate.");
            Exit;

        }
        if ($splitSessionCodes.Count -ne $codesOfSessionsFound.Count) {
            Write-Host("Some of the session codes entered could not be found. The following sessions will not be downloaded:");
            foreach ($sc in $splitSessionCodes) {
                if (-not ($codesOfSessionsFound -contains $sc)) {
                    Write-Host($sc);
                }
            }
        }
        return $filteredSessions;
    }
}

function DownloadSession($sessionObject, $sessionSearchCount, $directory) {
    if (($sessionObject.slideDeck.Length -ne 0)) {
        $code = $sessionObject.sessionCode;
        $title = $sessionObject.title;

        if ($code.Length -eq 0) {
            $code = "NoCodeSession$sessionSearchCount"
        }
        if ($title.Length -eq 0) {
            $title = "NoTitleSession$sessionSearchCount";
        }

        Write-Host("===== $title ($code) =====");

        $slideFile = "$directory\$code\$code.pptx";
        $slideFileDes = "$directory\$code.pptx";

        #Slides download.
        if ($sessionObject.slideDeck.Length -ne 0) {
            if (!(test-path $slideFile)) {
                Write-Host "Downloading slides for: $title ($code).";
                Start-BitsTransfer -Source $sessionObject.slideDeck -Destination $slideFileDes;
            }
            else {
                Write-Host "Slides exist: $slideFile"
            }
        }
        else {
            Write-Host "The session $title ($code) does not contain a slide deck."
        }

        Write-Host "Downloading data for: $title ($code).";
        Write-Host("`r`n");
        return $true;
    }
    return $false;
}

### Main ###
$sessions = FetchSessionData;
$sessions = FilterSessions $sessions $sessionCodes;
$sessionSearchCount = 0;
$sessionDownloadCount = 0;
foreach ($s in $sessions) {
    if (DownloadSession $s $sessionDownloadCount $directory) {
        $sessionDownloadCount++;
        $metaData += "Session ID: " + $s.sessionId;
        $metaData += "`tSession Code: " + $s.sessionCode;
        $metaData += "`tSession Title: " + $s.title;
        $metaData += "`rSession Description: " + $s.description;
        $metaData += "`r`n`r`n"
    }
    $sessionSearchCount ++;
}
$dataFile = "$directory\download-report.txt";
Out-File -FilePath $dataFile -InputObject $metaData -Encoding ASCII;
Write-Host("$sessionSearchCount session(s) searched.");
Write-Host("$sessionDownloadCount session(s) downloaded.");
