$DISCORD_API = 'https://discord.com/api/v7/'

function main {
    $USER_TOKEN = Read-Host -Prompt "Discord user token (I'm not dabezt, I promise)"
    $INTERVAL = Read-Host -Prompt "How often do you want to change your password (in hour, leave blank to change once)"
    $CURRENT_PASSWORD = Read-Host -Prompt "Your current Discord password"
    $BW_ID = Read-Host -Prompt "Bitwarden ID, leave blank to disable syncing to Bitwarden"

    $CHANGE_ONCE = [string]::IsNullOrWhiteSpace($INTERVAL)
    $BITWARDEN_SYNC = ![string]::IsNullOrWhiteSpace($BW_ID)

    while($true){
        $oldPass = $CURRENT_PASSWORD
        $CURRENT_PASSWORD, $USER_TOKEN = Set-Password -oldPass "$CURRENT_PASSWORD" -token "$USER_TOKEN"
        if ($BITWARDEN_SYNC) {
            Update-Bitwarden -id "$BW_ID" -password "$CURRENT_PASSWORD"
        }
        Update-Changes -oldPass "$oldPass" -newPass "$CURRENT_PASSWORD" -dabezt $USER_TOKEN
        if ($CHANGE_ONCE) { 
            break
        } 
        else {
            Start-Sleep -Seconds ([double]$INTERVAL*3600)
        }
    }
}

function New-Password {
    param (
        [string]$length = 32
    )
    return (bw generate -ulns --length $length)
}

function Get-Headers {
    param (
        [Parameter(Mandatory=$true)]
        [string]$token
    )
    $json = @"
{
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.130 Safari/537.36",
    "Content-Type": "application/json",
    "Authorization": "$token"
}
"@
    return $json
}

function Set-Password {
    param (
        [Parameter(Mandatory=$true)]
        [string]$oldPass,
        [Parameter(Mandatory=$true)]
        [string]$token
    )
    $userInfo = ConvertFrom-Json (Invoke-WebRequest -Uri ($DISCORD_API + 'users/@me') -Headers (ConvertFrom-Json -AsHashtable (Get-Headers -token $token))).Content
    $newPass = (New-Password -length 64)
    $discriminator = $userInfo.discriminator
    $email = $userInfo.email
    $avatar = $userInfo.avatar
    $payload = @"
{
    "password": "$oldPass",
    "new_password": "$newPass",
    "discriminator": "$discriminator",
    "email": "$email",
    "avatar": "$avatar"
}
"@
    $receive_request=(Invoke-RestMethod -Uri ($DISCORD_API + 'users/@me') -Method Patch -Headers (ConvertFrom-Json -AsHashtable (Get-Headers -token $token)) -Body $payload)
    return $newPass, $receive_request.token
}

function Update-Bitwarden {
    param (
        [Parameter(Mandatory=$true)]
        [string]$id,
        [Parameter(Mandatory=$true)]
        [string]$password
    )
    bw sync | Out-Null
    bw get item $id | jq --arg v $password '.login.password=$v' | bw encode | bw edit item $id | Out-Null
    bw sync | Out-Null
}

function Update-Changes {
    param (
        [Parameter(Mandatory=$true)]
        [string]$oldPass,
        [Parameter(Mandatory=$true)]
        [string]$newPass,
        [Parameter(Mandatory=$true)]
        [string]$dabezt
    )
    Write-Output "===============================" | Tee-Object -Append -file log.txt
    Write-Output "Current date: " + (Get-Date) | Tee-Object -Append -file log.txt
    Write-Output "Old password: $oldPass" | Tee-Object -Append -file log.txt
    Write-Output "New password: $newPass" | Tee-Object -Append -file log.txt
    #Write-Output "Token: $dabezt" | Tee-Object -Append -file log.txt
    Write-Output "`n"
    Write-Output "To relogin, run this in Console"
    $code = @"
setInterval(() => {
    document.body.appendChild(document.createElement ``iframe``).contentWindow.localStorage.token = ``"$dabezt"``
}, 50);
setTimeout(() => {
    location.reload();
}, 2500);


"@
    Write-Output $code
}

main
