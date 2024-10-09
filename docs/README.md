# Dotfiles für alle

Dieses Repository enthält eine Integration von [Vault](https://www.vaultproject.io/) mit [chezmoi](https://www.chezmoi.io), einem "dotfile manager".
Die Idee ist, für alle Entwickler einheitliche Credentials und Konfigurationen zu erzeugen, um so zum Beispiel den Zugriff auf unsere Datenbanken oder GKE Cluster zu ermöglichen.
Dazu werden zum einen in Vault gespeicherte Credentials automatisiert ausgelesen und/oder Skripte wie `gcloud` ausgeführt.

Darüber hinaus werden einige (wenige) Konfigurationen vorgenommen, die Konventionen und best practices abbilden. Dabei wird aber nur so wenig wie möglich konfiguriert, um nicht die Vorlieben der Mitarbeiter unnötig zu überschreiben. Hier gilt: weniger ist mehr :)

## Installation unter macOS

```shell
brew install vault chezmoi mise
```

Nach Installation von mise, [activate mise](https://mise.jdx.dev/getting-started.html#_2a-activate-mise) beachten.
Pfad entsprechend der Pfad zum brew Verzeichnis `/opt/homebrew/bin/`.

`mise` ist ein tool version manager.
Es kann tools wie asdf, nvm, pyenv, rbenv, etc. ersetzen.

## Installation unter debian/ubuntu

Leider nur als snaps allgemein verfügbar:

```shell
sudo snap install vault chezmoi
```

## Initialisierung

```shell
export VAULT_ADDR="https://vault.ops.zeit.de/"
vault login -method=oidc
```

Nicht erschrecken: der Vault Login läuft über den Browser. Im Anmeldeformular dann mit den eigenen AD credentials anmelden (`nachname` und *nicht* `vnachname`).
Das Fenster kann anschließend geschlossen werden und es geht weiter im Terminal:

```shell
chezmoi init git@github.com:ZeitOnline/dotfiles.git
chezmoi apply
mise install
```

!!! note
    `chezmoi apply` ggf. 2x ausführen, falls die Fehlermeldung `kv list -format=json cloudsql/databases: fork/exec : no such file or directory` erscheint.

## Laufende Aktualisierungen

Um Updates aufzuspielen reicht dann künftig folgendes:

```shell
vault login -method=oidc
chezmoi update
mise install
```

## chezmoi für eigene dotfiles und zon dotfiles

Falls chezmoi nicht nur für die ZON dotfiles, sondern auch für seperate (private) dotfiles genutzt werden soll, empfiehlt es sich sowohl die config als auch das die dotfiles selbst in einen non-default Ordner zu legen.

Am einfachsten ist dies mit den folgenden beiden Aliasen umzusetzen:

```shell
alias chezzon='chezmoi --source ~/.chezzon/repo --config ~/.chezzon/chezmoi.toml'
alias chezzon_init='chezmoi init git@github.com:ZeitOnline/dotfiles.git --source ~/.chezzon/repo --config-path ~/.chezzon/chezmoi.toml'
```

!!! note
    Die beiden Aliase lassen sich nicht kombinieren, da `chezmoi init` das Flag `--config-path` benötigt, das nicht identisch mit `--config` ist, welches von allen anderen `chezmoi` Kommandos genutzt wird.

Die Initialisierung erfolgt dann mit `chezzon-init`, für alles weitere kann `chezzon` wie sonst `chezmoi` genutzt werden:

```shell
chezzon_init
chezzon apply
mise install
```

Damit wird das zon-dotfiles repo in `~/.chezzon/repo` initialisiert, das config file landet in `~/.chezzon/chezmoi.toml`.

## Was im Preis mit inbegriffen ist

Aktuell wird vor allem folgendes verwaltet: Postgres Zugriff, GKE Cluster Zugriff, Tools durch `mise`, sowie ein paar sinnvolle, allgemeingültige Einstellungen für die fish shell.

### Postgres Services

Die [Service Definitionen](https://www.postgresql.org/docs/12/libpq-pgservice.html) für unsere CloudSQL Datenbanken erlauben den SSL verschlüsselten Zugriff auf alle Datenbanken (Obacht! Inklusive Production!).

Welche Datenbanken konfiguriert sind läßt sich so herausfinden:

```shell
grep '^\[' .pg_service.conf
```

Deren Namen kann man dann bei gängigen Postgresl Clients verwenden, bei `psql` z.B.:

```bash
$ psql service=quiz-production
Null display is "(null)".
Line style is unicode.
Border style is 2.
psql (12.4, server 12.1)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

quiz=> \q
```

### GKE Clusterzugriff

Es werden lediglich die notwendigen `gcloud` Befehle ausgefuehrt (`gcloud` muss installiert sein).
In Kurzform:

```shell
gcloud init gcloud auth login
```

Der Effekt ist, dass in den  diversen `k8s/(staging|production)` Verzeichnissen `kubectl` und `k9s` funktionieren, sowie die `bin/deploy` Skripte, die k8s verwenden.

### fish config

Für fish Benutzer wird zudem die notwendige Einstellung der `VAULT_ADDR` und `KUBECONFIG` Umgebungsvariablen vorgenommen.
Diese werden in einer dedizierten `conf.d/zon.fish` Datei verwaltet, um nicht die komplette fish config zu "kapern".
