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

## Procédure de publication

Choisir une nouvelle version stable `X.Y.Z` (par exemple `1.3.0`). Le numéro
est déduit du tag Git par la CI ; aucun fichier ne doit être modifié pour
changer uniquement le numéro de publication.

1. Faire valider humainement le commit exact à publier et tous ses contrôles.
2. Confirmer que `yannick7fr/nginx-certbot-custom:X.Y.Z` n'existe pas.
3. Créer une seule fois le tag Git annoté `vX.Y.Z` sur ce commit et le pousser.
4. Le workflow `Publish immutable image` reconstruit et teste l'image sur un
   runner GitHub hébergé, recontrôle l'absence du tag distant, puis publie
   uniquement `X.Y.Z`, avec cette version dans son label OCI.
5. Télécharger l'artefact `published-digest-X.Y.Z` ou lire le résumé du job.
6. Reporter ici et dans le README la référence complète :
   `yannick7fr/nginx-certbot-custom@sha256:<digest>`.

Le workflow n'a aucun déclenchement manuel et ne génère ni `latest`, ni autre
alias flottant. Sa concurrence est sérialisée. Si la version existe déjà, le
job échoue avant l'authentification et il faut créer une nouvelle version : le
tag Git et le tag Docker existants ne sont jamais déplacés ou écrasés.

## Candidate Nginx 1.31.6

La base `jonasal/nginx-certbot:6.2.0-nginx1.31.6` est figée au digest
`sha256:ccd7b8b4fbb538a493012b52edfddeb51cbfec974ef7f8cd341894c5dae02925`.
Le build et les tests locaux `linux/amd64` ont réussi le 3 octobre 2026.
Cette candidate n’est pas publiée : choisir un nouveau tag `vX.Y.Z` après
validation de la CI, puis suivre la procédure ci-dessus. Le digest historique
de `1.2.0` reste celui de l’image publiée avec Nginx `1.31.5`.

## Digest 1.2.0

État : publié.

Digest : yannick7fr/nginx-certbot-custom@sha256:93de185acd7fdf6d1591a868579cfdb64a5393b2276d2f8938c40b52b53c8fa3
