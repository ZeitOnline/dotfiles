Dotfiles für alle
-----------------

Dieses Repository enthält aktuell ein Experiment zur Integration von `Vault <https://www.vaultproject.io/>`_ mit `chezmoi <https://www.chezmoi.io>`_, einem "dotfile manager". Die Idee ist, via Terraform erzeugte und in Vault gespeicherte Credentials automatisiert auszulesen, um so zum Beispiel den Zugriff auf unsere Datenbanken zu ermöglichen.

Genau das geht jetzt auch schon — ausprobieren läßt es sich so:

.. code-block:: shell

    $ export VAULT_ADDR="https://vault.ops.zeit.de/"
    $ brew install vault chezmoi
    $ vault login -method=oidc
    $ chezmoi init git@github.com:ZeitOnline/dotfiles.git
    $ chezmoi apply  # ggf. 2x ausführen, falls "kv list -format=json cloudsql/databases: fork/exec : no such file or directory" Fehler kommt

Für Linux müsst ihr Vault und chezmoi über die offiziellen Quellen (https://www.vaultproject.io/ / https://www.chezmoi.io/) installieren, aber ansonsten sollte euch das Zugriff auf alle für euch im Vault freigegebenen Datenbank Credendials geben:

.. code-block:: shell
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

Nach späteren Aktualisierungen im Terraform, also wenn neue Projekte und Datenbanken hinzukommen, umziehen oder sich die Credendials ändern, lassen sie die `Service Definitionen <https://www.postgresql.org/docs/12/libpq-pgservice.html>`_ leicht anpassen:

.. code-block:: shell
    $ chezmoi update

