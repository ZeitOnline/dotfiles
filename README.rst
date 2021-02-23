Dotfiles für alle
-----------------

Dieses Repository enthält aktuell ein Experiment zur Integration von `Vault <https://www.vaultproject.io/>`_ mit `chezmoi <https://www.chezmoi.io>`_, einem "dotfile manager". Die Idee ist, via Terraform erzeugte und in Vault gespeicherte Credentials automatisiert auszulesen, um so zum Beispiel den Zugriff auf unsere Datenbanken oder GKE Cluster zu ermöglichen.


Installation unter macOS
========================

.. code-block:: shell

    $ brew install vault chezmoi


Installation unter debian/ubuntu
================================

Leider nur als snaps allgemein verfügbar:

.. code-block:: shell

    $ sudo snap install vault chezmoi


Initialisierung
===============

.. code-block:: shell

    $ export VAULT_ADDR="https://vault.ops.zeit.de/"
    $ vault login -method=oidc

Nicht erschrecken: der Vault Login läuft über den Browser. Im Anmeldeformular dann mit den eigenen AD credentials anmelden.
Das Fenster kann anschließend geschlossen werden und es geht weiter im Terminal:

.. code-block:: shell

    $ chezmoi init git@github.com:ZeitOnline/dotfiles.git
    $ chezmoi apply


.. note:: ``chezmoi apply`` ggf. 2x ausführen, falls die Fehlermeldung ``kv list -format=json cloudsql/databases: fork/exec : no such file or directory`` erscheint.


Laufende Aktualisierungen
=========================

Um Updates aufzuspielen reicht dann künftig folgendes::

.. code-block:: shell
    $ vault login -method=oidc
    $ chezmoi update


Was im Preis mit inbegriffen ist
================================

Aktuell wird vor allem folgendes verwaltet: Postgres Zugriff, GKE Cluster Zugriff sowie ein paar sinnvolle, allgemeingültige Einstellungen für die fish shell.


Postgres Services
+++++++++++++++++

Die `Service Definitionen <https://www.postgresql.org/docs/12/libpq-pgservice.html>`_ für unsere CloudSQL Datenbanken erlauben den SSL verschlüsselten Zugriff auf alle Datenbanken (Obacht! Inklusive Production!).

Welche Datenbanken konfiguriert sind läßt sich so herausfinden:

.. code-block:: shell
    $ grep '^\[' .pg_service.conf

Deren Namen kann man dann bei gängigen Postgresl Clients verwenden, bei ``psql`` z.B.::

    $ psql service=quiz-production
    Null display is "(null)".
    Line style is unicode.
    Border style is 2.
    psql (12.4, server 12.1)
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
    Type "help" for help.

    quiz=> \q


GKE Clusterzugriff
++++++++++++++++++

Es werden lediglich die notwendigen ``gcloud`` Befehle ausgefuehrt (``gcloud`` muss installiert sein).
Für fish Benutzer wird zudem die notwendige Einstellung der ``KUBECONFIG`` Umgebungsvariable vorgenommen.
Der Effekt ist, dass in den  diversen ``k8s/(staging|production)`` Verzeichnissen ``kubectl`` und ``k9s`` funktionieren, sowie die ``bin/deploy`` Skripte, die k8s verwenden.
