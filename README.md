# loubepice-nginx-certbot

Image publique Nginx/Certbot de Loub'Epice avec le module dynamique
[`headers-more-nginx-module`](https://github.com/openresty/headers-more-nginx-module).
Ce dépôt construit et publie une image ; il ne contient aucun workflow, secret
ou droit de déploiement et ne contacte jamais la production.

## Composants figés

| Composant | Version | Vérification |
|---|---:|---|
| Image de base `jonasal/nginx-certbot` | `6.0.1-nginx1.29.2` (`linux/amd64`) | manifeste `sha256:47fc0fab81e22a7b2fd75157720b135b25f10b8edead929140e32653517fe2b4` |
| Nginx | `1.29.2` | archive SHA-256 `5669e3c29d49bf7f6eb577275b86efe4504cf81af885c58a1ed7d2e7b8492437` |
| headers-more | `0.34` | archive SHA-256 `0c0d2ced2ce895b3f45eb2b230cd90508ab2a773299f153de14a43e44c1209b3` |
| Certbot | `5.1.0` | fourni par l'image de base figée |
| pip / filelock / urllib3 | `26.2.1` / `3.32.5` / `2.7.0` | wheels PyPI figés et vérifiés par SHA-256 |
| Python | `3.13` | fourni par l'image de base et corrigé depuis le snapshot Debian figé |

La construction utilise le snapshot Debian immuable du 20 octobre 2025 pour
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

La première version autonome est associée au tag Git immuable `v1.2.0` et à
l'unique tag d'image :

```text
yannick7fr/nginx-certbot-custom:1.2.0
```

Aucun tag flottant, notamment `latest`, n'est produit. Le workflow de
publication n'accepte que `v1.2.0`, refuse de continuer si la version existe
déjà sur Docker Hub, teste l'image avant authentification, puis restitue son
digest dans le résumé et un artefact GitHub Actions. Les secrets Actions requis
dans ce dépôt sont `DOCKERHUB_USERNAME` et `DOCKERHUB_TOKEN`, ce dernier étant
un jeton Docker Hub limité en écriture au dépôt d'image concerné. Leurs valeurs
ne doivent jamais être ajoutées aux sources ou aux arguments de construction.

Procédure détaillée : [docs/release.md](docs/release.md).

## Digest publié

`1.2.0` n'est pas encore publiée. Après publication contrôlée, cette section
doit contenir la référence `yannick7fr/nginx-certbot-custom@sha256:<digest>`
restituée par le workflow.

## Corrections strictement nécessaires apportées à l'ancien Dockerfile

- le fichier suit la convention `Dockerfile` à la racine ;
- l'image de base, les sources et leurs empreintes sont figées ;
- le téléchargement Nginx passe de HTTP à HTTPS ;
- le module est compilé comme module dynamique compatible, sans installer une
  seconde copie complète de Nginx ;
- `headers-more` passe de `0.33` à `0.34`, première version officielle qui
  corrige la compilation et la gestion des en-têtes avec Nginx 1.23 ou plus ;
  `0.33` échoue à compiler contre le Nginx 1.29.2 déjà retenu par l'ancien
  Dockerfile ;
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
