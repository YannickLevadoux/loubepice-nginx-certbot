# loubepice-nginx-certbot

Image publique Nginx/Certbot de Loub'Epice avec le module dynamique
[`headers-more-nginx-module`](https://github.com/openresty/headers-more-nginx-module).
Ce dépôt construit et publie une image ; il ne contient aucun workflow, secret
ou droit de déploiement et ne contacte jamais la production.

## Composants figés

| Composant | Version | Vérification |
|---|---:|---|
| Image de base `jonasal/nginx-certbot` | `6.2.0-nginx1.31.5` (`linux/amd64`) | manifeste `sha256:133f39cd8897f6987b56d1f6a182ec7ec4173490c10009a745a91dc94e0e9de4` |
| Nginx | `1.31.5` | archive SHA-256 `e951607d534836624bd36b6b45a71dbfb055237deae3738da6bbf3270dada279` |
| headers-more | `0.40` | archive SHA-256 `c14cb5e6c998590c209efbf77bd7637ce2cab02332e4192756a8af5b26ba4284` |
| Certbot | `5.8.0` | fourni par l'image de base figée |
| pip / filelock / urllib3 | `26.2.1` / `3.32.5` / `2.7.0` | wheels PyPI figés et vérifiés par SHA-256 |
| Python | `3.13` | fourni par l'image de base et corrigé depuis le snapshot Debian figé |

La construction utilise le snapshot Debian immuable du 24 août 2026 pour
les seuls outils du stage de compilation, puis celui du 5 septembre 2026 pour
reproduire les mises à jour de sécurité de l'image finale. Les outils, les
archives et les caches de compilation ne sont pas copiés dans l'image finale.

## Construire et tester localement

Docker 27 avec BuildKit est recommandé. La première plateforme prise en charge
et publiée est `linux/amd64`.

```bash
docker build \
  --platform linux/amd64 \
  --build-arg SOURCE_DATE_EPOCH=1766416952 \
  --build-arg SOURCE_REVISION="$(git rev-parse HEAD)" \
  --tag loubepice-nginx-certbot:test \
  .
bash tests/test-image.sh loubepice-nginx-certbot:test
```

Le test exécute `nginx -t`, vérifie la présence du module, démarre une
configuration minimale, contrôle l'en-tête produit par `headers-more`, effectue
une requête HTTP locale et exécute exactement la probe HTTPS attendue par le
contrat de healthcheck de l'infrastructure.

La CI des pull requests construit et teste sans publier, puis analyse
l'historique à la recherche de secrets et produit des rapports Trivy pour les
sources et l'image. Voir [docs/security.md](docs/security.md) pour la politique
et les limites des scans.

## Version et publication

Chaque tag Git immuable au format `vX.Y.Z` déclenche la publication du tag
Docker correspondant, sans le préfixe `v`. Par exemple, `v1.3.0` publie :

```text
yannick7fr/nginx-certbot-custom:1.3.0
```

Aucun tag flottant, notamment `latest`, n'est produit. Les tags de préversion
et les versions avec des zéros initiaux sont refusés. Le workflow refuse de
continuer si la version existe déjà sur Docker Hub, teste l'image avant
authentification, puis restitue son digest dans le résumé et un artefact
GitHub Actions. La version est aussi inscrite dans le label OCI de l'image.
Les builds locaux et de pull request utilisent la version `dev` par défaut ;
pour tester une version précise, passer `--build-arg IMAGE_VERSION=1.3.0` au
build et `1.3.0` en deuxième argument à `tests/test-image.sh`.

Les secrets Actions requis
dans ce dépôt sont `DOCKERHUB_USERNAME` et `DOCKERHUB_TOKEN`, ce dernier étant
un jeton Docker Hub limité en écriture au dépôt d'image concerné. Leurs valeurs
ne doivent jamais être ajoutées aux sources ou aux arguments de construction.

Procédure détaillée : [docs/release.md](docs/release.md).

## Digest publié

`1.2.0`  

```
yannick7fr/nginx-certbot-custom@sha256:93de185acd7fdf6d1591a868579cfdb64a5393b2276d2f8938c40b52b53c8fa3
```

## Corrections strictement nécessaires apportées à l'ancien Dockerfile

- le fichier suit la convention `Dockerfile` à la racine ;
- l'image de base, les sources et leurs empreintes sont figées ;
- le téléchargement Nginx passe de HTTP à HTTPS ;
- le module est compilé comme module dynamique compatible, sans installer une
  seconde copie complète de Nginx ;
- l'image de base passe à `jonasal/nginx-certbot:6.2.0-nginx1.31.5` et reste
  figée par le manifeste propre à `linux/amd64` ;
- `headers-more` passe à `0.40` et est recompilé contre Nginx `1.31.5` ;
- l'`apt-get upgrade` non figé est remplacé par les mises à jour du snapshot
  Debian immuable du 5 septembre 2026 ;
- les mises à niveau `pip`, `filelock` et `urllib3` sont conservées mais leurs
  versions et hashes de wheels sont désormais figés ;
- les outils, sources et caches de compilation restent dans le stage builder ;
- les métadonnées OCI de source et de révision sont renseignées.

Ces changements rendent les entrées de construction immuables et le résultat
fonctionnel reproductible sans modifier le rôle de l'image : Nginx/Certbot
avec `headers-more` et Python 3. Les métadonnées internes générées par `apt` et
`pip` ne garantissent pas un identifiant d'image identique bit à bit entre deux
builds sans cache ; le digest du build publié reste donc la référence
autoritative. Aucun certificat, configuration de production ou journal n'est
inclus.
