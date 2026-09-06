# Publication immuable

Le dépôt publie une image mais ne possède aucun droit ni workflow de
déploiement. La procédure ne contacte aucun serveur de production.

## Prérequis du propriétaire

Créer dans les secrets GitHub Actions du seul dépôt
`YannickLevadoux/loubepice-nginx-certbot` :

- `DOCKERHUB_USERNAME` : identifiant Docker Hub autorisé à pousser vers
  `yannick7fr/nginx-certbot-custom` ;
- `DOCKERHUB_TOKEN` : jeton d'accès limité autant que Docker Hub le permet à
  l'écriture de ce dépôt.

Ne jamais transmettre leurs valeurs dans une issue, une pull request, un
fichier, un argument de build ou un journal.

## Procédure 1.2.0

1. Faire valider humainement le commit exact à publier et tous ses contrôles.
2. Confirmer que `yannick7fr/nginx-certbot-custom:1.2.0` n'existe pas.
3. Créer une seule fois le tag Git annoté `v1.2.0` sur ce commit et le pousser.
4. Le workflow `Publish immutable image` reconstruit et teste l'image sur un
   runner GitHub hébergé, recontrôle l'absence du tag distant, puis publie
   uniquement `1.2.0`.
5. Télécharger l'artefact `published-digest-1.2.0` ou lire le résumé du job.
6. Reporter ici et dans le README la référence complète :
   `yannick7fr/nginx-certbot-custom@sha256:<digest>`.

Le workflow n'a aucun déclenchement manuel et ne génère ni `latest`, ni autre
alias flottant. Sa concurrence est sérialisée. Si la version existe déjà, le
job échoue avant l'authentification et il faut créer une nouvelle version : le
tag Git et le tag Docker existants ne sont jamais déplacés ou écrasés.

## Digest 1.2.0

État : publié.

Digest : yannick7fr/nginx-certbot-custom@sha256:93de185acd7fdf6d1591a868579cfdb64a5393b2276d2f8938c40b52b53c8fa3
