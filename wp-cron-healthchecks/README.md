# wp-cron-healthchecks

Script Bash pour exécuter les tâches cron WordPress via WP-CLI, avec support du multisite et monitoring Healthchecks.io.

## Usage

```bash
./wp-cron.sh [options]
```

### Options principales

- `-p, --path`      : Chemin vers l'installation WordPress (défaut : répertoire courant)
- `-c, --cli`       : Commande WP-CLI à utiliser (défaut : `wp`)
- `-u, --url`       : URL WordPress (pour multisite, optionnel)
- `-q, --quiet`     : Mode silencieux (seulement les erreurs)
- `-H, --hc-url`    : URL de ping Healthchecks.io (obligatoire)
- `-t, --timeout`   : Temps max d'exécution en secondes (défaut : 300)
- `-h, --help`      : Affiche l'aide

## Exemple Healthchecks.io

1. Crée un check sur https://healthchecks.io, copie l'URL de ping (ex: `https://hc-ping.com/xxxx-xxxx-xxxx-xxxx`).
2. Ajoute le script dans ta crontab :

```cron
*/5 * * * * /chemin/vers/wp-cron-healthchecks/wp-cron.sh -p /var/www/html -H https://hc-ping.com/xxxx-xxxx-xxxx-xxxx
```

## Fonctionnement

- Envoie un ping `/start` à Healthchecks.io avant d'exécuter le cron.
- Envoie un ping de succès (URL sans suffixe) si tout s'est bien passé.
- Envoie un ping `/fail` en cas d'échec ou de timeout.
- Gère automatiquement le multisite WordPress (boucle sur tous les sites).

## Dépendances
- WP-CLI
- curl

## Licence
MIT 