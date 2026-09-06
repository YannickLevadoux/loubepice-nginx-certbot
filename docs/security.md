# Sécurité, scans et limites connues

Le dépôt et l'image ne contiennent volontairement ni certificat, ni secret, ni
configuration ou journal de production. Les secrets Docker Hub sont lus
uniquement par le workflow de publication après réussite des tests.

Sur chaque pull request :

- Gitleaks `8.30.1` analyse tout l'historique Git et bloque un secret détecté ;
- Trivy `0.74.0` analyse les sources (vulnérabilités, mauvaises configurations
  et secrets) ;
- Trivy `0.74.0` analyse les paquets système et bibliothèques de l'image ;
- les rapports Trivy complets sont conservés comme artefacts de CI pendant 30
  jours.

Les actions tierces sont épinglées par SHA de commit complet et accompagnées
de leur version lisible. Les scans de vulnérabilités sont informatifs pour
cette migration : l'image de base est figée afin de préserver le comportement,
et un correctif impose une nouvelle version testée au lieu d'une mutation
silencieuse de `1.2.0`. Gitleaks reste bloquant.

## Vulnérabilités connues

Le scan de référence effectué le 6 septembre 2026 avec Trivy `0.74.0` et sa
base mise à jour donne les occurrences suivantes dans l'image candidate :

| Sévérité | Total | Correctif indiqué | Sans correctif indiqué |
|---|---:|---:|---:|
| Critique | 4 | 0 | 4 |
| Haute | 84 | 18 | 66 |
| Moyenne | 104 | 6 | 98 |
| Faible | 101 | 2 | 99 |
| Inconnue | 34 | 0 | 34 |

Les quatre occurrences critiques sans correctif concernent `perl-base`
(`CVE-2026-13221`, `CVE-2026-42496`, `CVE-2026-8376`) et `libxml2`
(`CVE-2026-6653`). Le snapshot de sécurité figé met déjà à jour 44 paquets de
l'image de base et fait passer le total critique de 7 à 4 et le total haut de
184 à 84. Les 18 occurrences hautes pour lesquelles Trivy indique un correctif
restent dans des dépendances Python transitives de Certbot. Leur mise à niveau
groupée n'est pas appliquée silencieusement dans cette migration, car elle
change l'ensemble de dépendances fonctionnelles fourni par l'image de base.

Ce relevé est un instantané : les bases de vulnérabilités évoluent. Le rapport
CI complet fait foi au moment de la revue et de la publication. Une correction
ultérieure doit produire une nouvelle version ; elle ne doit jamais remplacer
`1.2.0`.

Le scan des sources signale aussi deux règles Dockerfile : exécution initiale
en root (haute) et absence de `HEALTHCHECK` embarqué (faible). Elles sont des
limites connues conservées pour compatibilité : le processus maître doit lier
les ports 80/443 et gérer Certbot avant de déléguer les workers à l'utilisateur
`nginx`, tandis que la probe HTTPS dépend de la configuration et du certificat
injectés par l'infrastructure. Le test CI exécute cette probe, mais le
healthcheck reste déclaré par Compose conformément à #80.

## Signalement

Ne jamais ouvrir une issue publique contenant un secret exploitable. Révoquer
d'abord le secret concerné, puis utiliser le canal privé du propriétaire du
dépôt pour transmettre le minimum d'informations nécessaire.
