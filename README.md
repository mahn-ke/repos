# Repos

Sets up all repositories for this GitHub organization.

## Hackertours race announce server

`infrastructure/services.tf` registers `multiplayer.hackertours.by.vincent.mahn.ke`
(HTTP health check `/healthz`, Node.js host port `3022`): the directory of the
Hackertours race, where the consoles of an event announce the addresses their race
socket can be reached at. It accepts the console service accounts of the high
scores (below): `mahn-ke/multiplayer-hackertours-by-vincent` receives the Actions
secrets `OAUTH_URL` and `OAUTH_CONSOLE_{3DS,XBOX,SWITCH,GBA}_CLIENT_ID`, never the
client secrets.

## Hackertours high scores

`infrastructure/services.tf` registers `highscores.hackertours.by.vincent.mahn.ke`
(HTTP health check `/healthz`, Node.js host port `3020`). Applying Terraform creates
`mahn-ke/highscores-hackertours-by-vincent`, its standard generated scaffolding,
and four independent confidential Keycloak service-account clients:
`highscores-hackertours-3ds`, `highscores-hackertours-xbox`,
`highscores-hackertours-switch` and `highscores-hackertours-gba` (the GBA's link
server, which races for the GBA). Interactive and
password grants are disabled; access tokens last one hour. Existing interactive
OAuth clients are unchanged.

The new repository receives Actions secrets `OAUTH_URL`,
`OAUTH_CONSOLE_3DS_CLIENT_ID`, `OAUTH_CONSOLE_3DS_CLIENT_SECRET`,
`OAUTH_CONSOLE_XBOX_CLIENT_ID`, `OAUTH_CONSOLE_XBOX_CLIENT_SECRET`,
`OAUTH_CONSOLE_SWITCH_CLIENT_ID`, and `OAUTH_CONSOLE_SWITCH_CLIENT_SECRET`.
Only the issuer and client IDs are passed into the backend container; the console
secrets belong in private console `config.ini` files, never Git. After applying,
retrieve them locally with:

```sh
terraform -chdir=infrastructure output -json highscores_console_credentials
```

This output and Terraform state contain sensitive credentials. Do not paste them
into issues or logs. GitHub Actions secrets cannot be read back. Console binaries
and configuration are extractable: these credentials attribute submissions to a
platform, not a trusted human, and do not provide anti-cheat protection. No realm
or administrative roles are granted to either service account.
