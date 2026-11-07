# Extracteur Météo — `Extracteur_Meteo.sh`

Script Shell qui récupère la **température actuelle** d'une ville et la **prévision du lendemain**
depuis le service [wttr.in](https://wttr.in) (format **texte** uniquement), puis les enregistre dans
`meteo.txt`, **une ligne par exécution**.

## Prérequis

- Bash (macOS, Linux ou WSL) et `curl`, avec une connexion internet
- Commandes utilisées pour le traitement : `grep`, `head`, `tail`, `tr`, `cut`, `echo` (+ `date`)

## Installation

```bash
git clone https://github.com/kasisarchives/Extracteur_Meteo_Projet.git
cd Extracteur_Meteo_Projet
chmod +x Extracteur_Meteo.sh
```

## Utilisation

```bash
./Extracteur_Meteo.sh Toulouse     # ville passée en argument
./Extracteur_Meteo.sh              # sans argument : ville par défaut (Toulouse)
./Extracteur_Meteo.sh "New York"   # nom composé : entre guillemets
```

Chaque exécution ajoute une ligne à `meteo.txt` :

```
2026-11-06 - 08:00 - Toulouse : 7°C - 13°C
```

Format : `[Date] - [Heure] - Ville : [Température actuelle] - [Prévision du lendemain]`
(complété par le vent, l'humidité et la visibilité depuis la variante 1)

## Fonctionnement

1. **Récupération** : `curl` télécharge `wttr.in/<Ville>?T` (texte sans codes couleur) dans `meteo_brute.txt`.
2. **Extraction** : la 1re ligne contenant `°C` donne la température actuelle ; la 3e ligne contenant
   `°C` est le tableau du lendemain (Matin | Midi | Soir | Nuit), dont on garde la valeur de **midi**.
   `grep -oE` isole les motifs `+9(8) °C` / `13 °C`, puis `cut` garde la température réelle
   (sans le ressenti entre parenthèses) et `tr` retire le signe `+`.
3. **Formatage** : date et heure avec `date`, construction de la ligne.
4. **Enregistrement** : ajout en fin de `meteo.txt` (`>>`).

## Exécution périodique avec cron (version 2)

Le script se place lui-même dans son dossier (`cd "${0%/*}"`) : `meteo.txt` est donc toujours créé
à côté du script, même lancé par cron (qui démarre dans le dossier personnel de l'utilisateur).

1. **Récupérer le chemin absolu du projet** :
   ```bash
   pwd
   ```
   Exemple de résultat : `/Users/etudiant/Extracteur_Meteo_Projet`

2. **Ouvrir la table cron** de l'utilisateur :
   ```bash
   crontab -e
   ```

3. **Ajouter une ligne**. Format : `minute heure jour_du_mois mois jour_de_la_semaine commande`
   ```cron
   # tous les jours à 8h00, pour Toulouse
   0 8 * * * /Users/etudiant/Extracteur_Meteo_Projet/Extracteur_Meteo.sh Toulouse >/dev/null 2>&1
   ```
   Autres exemples :

   | Ligne cron | Fréquence |
   |---|---|
   | `0 * * * * …/Extracteur_Meteo.sh` | toutes les heures, ville par défaut |
   | `*/30 * * * * …/Extracteur_Meteo.sh Paris` | toutes les 30 minutes |
   | `0 8,18 * * 1-5 …/Extracteur_Meteo.sh` | à 8h et 18h, du lundi au vendredi |

   `>/dev/null 2>&1` évite que cron envoie un mail à chaque exécution.

4. **Enregistrer et quitter** l'éditeur (avec `vi` : `Échap`, puis `:wq` et `Entrée` ;
   avec `nano` : `Ctrl+O`, `Entrée`, `Ctrl+X`).

5. **Vérifier** la tâche installée :
   ```bash
   crontab -l
   ```
   puis, après l'heure prévue : `cat meteo.txt`.

6. **Supprimer** la tâche : `crontab -e` et effacer la ligne (ou `crontab -r` pour tout supprimer).

Remarques :
- Sous **WSL**, le service cron doit être démarré : `sudo service cron start`.
- Sous **macOS**, si rien ne s'écrit, autoriser `cron` dans Réglages Système → Confidentialité et
  sécurité → Accès complet au disque.
- Le fichier [`meteo.cron`](meteo.cron) contient des exemples prêts à copier.

## Historique quotidien (version 3)

L'option `-a` (ou `--archive`) enregistre le relevé dans le fichier du jour `meteo_AAAAMMJJ.txt`
au lieu de `meteo.txt`. Le nom dépend de la date : un nouveau fichier est créé automatiquement chaque
jour, et chaque exécution du même jour y ajoute sa ligne. On garde ainsi un historique jour par jour,
utilisable pour des statistiques.

```bash
./Extracteur_Meteo.sh -a Paris      # -> meteo_20261106.txt
./Extracteur_Meteo.sh -a            # ville par défaut, fichier du jour
./Extracteur_Meteo.sh -h            # aide
```

Avec cron, relevé toutes les heures archivé par jour :

```cron
0 * * * * /Users/etudiant/Extracteur_Meteo_Projet/Extracteur_Meteo.sh -a Toulouse >/dev/null 2>&1
```

## Variante 1 — Informations supplémentaires

Chaque ligne contient aussi la vitesse du vent, le taux d'humidité et la visibilité :

```
2026-11-06 - 14:30 - Toulouse : 11°C - 13°C - Vent : 8 km/h - Humidité : 70% - Visibilité : 10 km
```

| Information | Méthode |
|---|---|
| Vent | 1er motif `xx km/h` du bloc des conditions actuelles (`grep -oE`) |
| Visibilité | motif `xx km` en fin de ligne (le `$` exclut les `km/h`) |
| Humidité | absente de l'affichage texte standard : requête texte `wttr.in/<Ville>?format=%h` |

Si une information n'est pas disponible, `N/A` est écrit à sa place.

## Variante 3 — Gestion des erreurs

Si le téléchargement météo échoue, le script écrit une erreur datée dans
`meteo_error.log` avec la ville demandée, puis s’arrête sans ajouter de relevé.
Le script s'arrête aussi, avec une erreur datée dans le journal, si wttr.in répond sans
erreur mais sans données météo (service saturé, message d'information) : aucune ligne
incomplète n'est alors écrite dans `meteo.txt`.

| Cas détecté | Code de sortie |
|---|---|
| Échec de connexion, délai dépassé, ville inconnue (erreur HTTP) | code de `curl` |
| Réponse reçue mais sans température | 3 |

Pour lire la dernière erreur, utilise `tail -n 1 meteo_error.log`.

## Fichiers générés

| Fichier | Contenu |
|---|---|
| `meteo_brute.txt` | dernière réponse brute de wttr.in |
| `meteo.txt` | un relevé par ligne |
| `meteo_humidite_brute.txt` | réponse texte brute pour l'humidité (variante 1) |
| `meteo_AAAAMMJJ.txt` | relevés du jour (option `-a`) |
| `meteo_error.log` | erreurs horodatées (variante 3) |

## Versions

| Tag | Contenu |
|---|---|
| `v1.0` | Script de base : récupération, extraction, formatage, enregistrement |
| `v2.0` | Ville par défaut + exécution périodique avec cron |
| `v3.0` | Historique : archivage quotidien (`-a`) |
| `v4.0` | Variante 3 : gestion des erreurs et journal `meteo_error.log` |
| `v5.0` | Variante 1 : vent, humidité et visibilité |


## Description détaillée de notre travail collaboratif

Nous avons adopté un flux de travail collaboratif asynchrone basé sur le gestionnaire de versions Git et la plateforme GitHub. Le développement a été réparti entre les cinq membres du groupe sous forme de relais. Pour garantir la stabilité du code, chaque nouvelle fonctionnalité ou correction a été développée sur des branches isolées (par exemple, `feature/v2-cron-doc` ou `feature/v3-archivage`). 

L'intégration au projet commun s'est faite par des fusions (`merge`) régulières sur la branche principale (`main`). Cette méthode nous a permis de confronter et de résoudre formellement les conflits de fusion, assurant ainsi un historique clair, traçable et un apprentissage concret des outils de collaboration en entreprise.

## Description de notre approche de gestion de projet

Notre gestion de projet s'est articulée autour d'un développement itératif et incrémental, matérialisé par des versions strictes validées par des étiquettes (tags Git : `v1.0`, `v2.0`, `v3.0`). 

Nous avons mis un point d'honneur à respecter rigoureusement le cahier des charges. Face à la contrainte d'interdiction d'outils avancés comme `awk`, `sed` ou les expressions régulières complexes (`grep -E`), nous avons privilégié une approche algorithmique par contournement. La communication au sein du groupe et la vérification du code avant chaque fusion ont permis de maintenir un script robuste face à l'instabilité du formatage ASCII renvoyé par l'API externe.

## Description des solutions implémentées par version

### Version 1 : Extraction de base et parsing
L'objectif initial était l'extraction fiable des données textuelles. Nous avons utilisé `curl` pour récupérer le bulletin de `wttr.in`. Pour isoler les températures actuelles et celles du lendemain au sein d'un tableau ASCII très instable (espaces variables, caractères de dessin de tableau), nous avons conçu une chaîne de traitement (`pipe`) stricte utilisant `grep`, `head`, `tail`, `tr`, et `cut`. L'utilisation de `xargs` a permis de nettoyer les espaces résiduels, garantissant une écriture propre dans le fichier `meteo.txt`.

### Version 2 : Automatisation et portabilité
Cette version s'est concentrée sur l'autonomie du script. Nous avons implémenté la gestion d'une ville par défaut (Toulouse) en cas d'absence d'argument. Pour l'automatisation, nous avons documenté et mis en place une exécution planifiée via le démon système `cron`. Techniquement, nous avons ajouté une routine de sécurisation des chemins relatifs dans le script (`cd "${0%/*}"`) afin de garantir que les fichiers de sortie soient toujours générés dans le répertoire du script, indépendamment de l'environnement d'exécution du `cron`.

### Version 3 : Archivage, options et extraction avancée
La version finale intègre une gestion professionnelle des paramètres via une boucle `while` et un `case`, permettant l'interprétation des options `-a` (archivage) et `-h` (aide). 
L'option d'archivage génère dynamiquement des fichiers de sortie horodatés (`meteo_AAAAMMJJ.txt`). Les capacités d'extraction ont été étendues au vent, à la visibilité et à l'humidité. Pour extraire ces données en respectant les contraintes de commandes, nous avons utilisé une astuce technique reposant sur l'inversion des chaînes (`rev`) couplée à `cut`, permettant d'isoler la fin des lignes sans être affecté par la longueur variable de la météo affichée au début de la ligne. Enfin, une gestion stricte des erreurs HTTP et des délais d'attente (timeout) a été ajoutée à `curl`, avec journalisation dans un fichier `meteo_error.log`.

