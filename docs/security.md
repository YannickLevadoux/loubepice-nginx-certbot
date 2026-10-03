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

### Candidate Nginx 1.31.6

Le scan local du 3 octobre 2026 utilise Trivy `0.74.0` et la base de
vulnérabilités mise à jour le même jour à `01:08:10 UTC`. Il porte sur l'image
`linux/amd64` construite avec la nouvelle base et le snapshot Debian du
3 octobre 2026. Le build et tous les tests du README ont réussi.

| Sévérité | Total | Correctif indiqué | Sans correctif indiqué |
|---|---:|---:|---:|
| Critique | 1 | 0 | 1 |
| Haute | 81 | 6 | 75 |
| Moyenne | 111 | 3 | 108 |
| Faible | 96 | 0 | 96 |
| Inconnue | 27 | 0 | 27 |

L'occurrence critique concerne `libxml2` (`CVE-2026-6653`), sans correctif
indiqué. Les occurrences hautes avec correctif concernent `msgpack`
(`GHSA-6v7p-g79w-8964`, correctif `1.2.1`), `setuptools`
(`CVE-2025-47273`, correctif `78.1.1`) et `urllib3`
(`CVE-2026-97687` et `CVE-2026-97689`, correctif `2.8.0`). Les occurrences
`urllib3` sont relevées dans deux chemins de l'image. Les versions Python
figées sont conservées pour limiter cette mise à jour à la base et aux
paquets Debian nécessaires ; ces correctifs restent à traiter séparément.

Le scan des sources ne détecte aucun secret et retrouve les deux limites
Dockerfile détaillées ci-dessous. Ces résultats sont informatifs selon la
politique du dépôt. La base de vulnérabilités diffère de celle du relevé
historique : les totaux ne constituent pas une comparaison à base constante.
Les rapports de la CI font foi avant publication.

### Version publiée 1.2.0 (Nginx 1.31.5)

Le scan de référence effectué le 6 septembre 2026 avec Trivy `0.74.0` et sa
base mise à jour donne les occurrences suivantes dans l'image candidate :

| Sévérité | Total | Correctif indiqué | Sans correctif indiqué |
|---|---:|---:|---:|
| Critique | 4 | 0 | 4 |
| Haute | 68 | 2 | 66 |
| Moyenne | 99 | 1 | 98 |
| Faible | 99 | 0 | 99 |
| Inconnue | 34 | 0 | 34 |

Les quatre occurrences critiques sans correctif concernent `perl-base`
(`CVE-2026-13221`, `CVE-2026-42496`, `CVE-2026-8376`) et `libxml2`
(`CVE-2026-6653`). L’image de base de `1.2.0` contient déjà les versions du
snapshot de sécurité final : l'étape `apt-get upgrade` ne trouve donc aucun
paquet supplémentaire à mettre à jour. Par rapport au précédent candidat, le
total haut passe de 84 à 68 et le total moyen de 104 à 99. Les deux occurrences
hautes pour lesquelles Trivy indique un correctif concernent `setuptools` et
`msgpack`, dépendances Python transitives de Certbot. Leur mise à niveau groupée
n'est pas appliquée silencieusement dans cette migration, car elle change
l'ensemble de dépendances fonctionnelles fourni par l'image de base.

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
