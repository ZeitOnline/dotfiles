# Dotfiles für alle

Dieses Repository enthält aktuell ein Experiment zur Integration von [Vault](https://www.vaultproject.io/) mit [chezmoi](https://www.chezmoi.io), einem "dotfile manager". Die Idee ist, via Terraform erzeugte und in Vault gespeicherte Credentials automatisiert auszulesen, um so zum Beispiel den Zugriff auf unsere Datenbanken zu ermöglichen.

Genau das geht jetzt auch schon — ausprobieren läßt es sich so:

```shell
$ export VAULT_ADDR="https://vault.ops.staging.zeit.de/"
$ brew install vault chezmoi
$ vault login -method=oidc role=zon-sudo
$ chezmoi init https://github.com/ZeitOnline/dotfiles.git
$ chezmoi apply
```

Für Linux müsst ihr Vault und chezmoi natürlich anders installieren, aber ansonsten sollte euch das Zugriff auf alle für euch im Vault freigegebenen Datenbank Credendials geben:

```shell
$ grep '^\[' .pg_service.conf
[alerta-production]
[bitpoll-production]
[bitpoll-staging]
[bitpoll_devel-staging]
[comments-production]
[comments-staging]
[digitalabo-staging]
[keycloak-staging]
[kickerticker-production]
[kickerticker-staging]
[premium-media-staging]
[quiz-devel-staging]
[quiz-production]
[quiz-staging]
[sharebert-staging]
[sudoku-production]
[sudoku-staging]
[umdieecke-production]
[umdieecke-staging]
[zg-corona-production]
[zg-hasura-staging]
~ $ psql service=quiz-production
Null display is "(null)".
Line style is unicode.
Border style is 2.
psql (12.4, server 12.1)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

quiz=> \q
```

Nach späteren Aktualisierungen im Terraform, also wenn neue Projekte und Datenbanken hinzukommen, umziehen oder sich die Credendials ändern, lassen sie die [Service Definitionen](https://www.postgresql.org/docs/12/libpq-pgservice.html) leicht anpassen:

```shell
$ chezmoi update
```

