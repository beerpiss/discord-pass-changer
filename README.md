# discord-pass-changer
A simple tool to periodically change your Discord password automatically. By changing the password, you are also changing the token, so old grabbed tokens become useless.

Optionally, allows you to sync the changed password with Bitwarden (requires `bitwarden-cli` to be installed and available on your PATH, and the environment variable `$env:BW_SESSION` to be set)

Requires PowerShell>=7.0.0