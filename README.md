# Repos

Sets up all repositories for this GitHub organization.

## Hackertours high scores

`infrastructure/services.tf` registers `highscores.hackertours.by.vincent.mahn.ke`
(HTTP health check `/healthz`, Node.js host port `3020`). Applying Terraform creates
`mahn-ke/highscores-hackertours-by-vincent`, its standard generated scaffolding,
and two independent confidential Keycloak service-account clients:
`highscores-hackertours-3ds` and `highscores-hackertours-xbox`. Interactive and
password grants are disabled; access tokens last one hour. Existing interactive
OAuth clients are unchanged.

The new repository receives Actions secrets `OAUTH_URL`,
`OAUTH_CONSOLE_3DS_CLIENT_ID`, `OAUTH_CONSOLE_3DS_CLIENT_SECRET`,
`OAUTH_CONSOLE_XBOX_CLIENT_ID`, and `OAUTH_CONSOLE_XBOX_CLIENT_SECRET`.
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
