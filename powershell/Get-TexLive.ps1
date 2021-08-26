Function Get-TexLive {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

    $tempFolder = "$ENV:UserProfile\.tmp"
    if ( -not(Test-Path -Path "$tempFolder") ) {
        New-Item -ItemType directory -Path "$tempFolder" | Out-Null
    }

    try {
        $tempTexTargetFolder = "$tempFolder\texlive-install"
        if ( -not(Test-Path -Path "$tempTexTargetFolder\install-tl-windows.bat" -PathType Leaf) ) {
            $tempTexFolder = "$tempFolder\texlive-tmp"
            $tempTexArchive = "$tempFolder\install-tl.zip"

            if ( -not(Test-Path -Path "$tempTexArchive" -PathType Leaf) ) {
                $url = 'https://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip'
                Start-BitsTransfer -Source $url -Destination $tempTexArchive
                Write-Host "Downloaded TeX Live archive: '$url'"
            }

            # Remove tex folder if it exists
            If (Test-Path "$tempTexFolder" -PathType Any) {
                Remove-Item -Recurse -Force "$tempTexFolder" | Out-Null
            }
            Expand-Archive "$tempTexArchive" -DestinationPath "$tempTexFolder" -Force

            Get-ChildItem -Path "$tempTexFolder" -Force -Directory | Select-Object -First 1 | Move-Item -Destination "$tempTexTargetFolder"

            Remove-Item -Recurse -Force "$tempTexFolder" | Out-Null
            Write-Host "Removed intermediate folder: '$tempTexFolder'"

            Remove-Item -Recurse -Force "$tempTexArchive" | Out-Null
            Write-Host "Removed intermediate archive: '$tempTexArchive'"
        }
    }
    catch [Exception] {
        Write-Host "Failed to download and extract TeX Live.", $_.Exception.Message
    }
}

Get-TexLive
