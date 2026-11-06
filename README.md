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

## Fichiers générés

| Fichier | Contenu |
|---|---|
| `meteo_brute.txt` | dernière réponse brute de wttr.in |
| `meteo.txt` | un relevé par ligne |
| `meteo_AAAAMMJJ.txt` | relevés du jour (option `-a`) |

## Versions

| Tag | Contenu |
|---|---|
| `v1.0` | Script de base : récupération, extraction, formatage, enregistrement |
| `v2.0` | Ville par défaut + exécution périodique avec cron |
| `v3.0` | Historique : archivage quotidien (`-a`) |
