## Automatisation avec Cron (Version 2)

Pour exécuter automatiquement le script chaque jour à 08h00 :
1. Ouvrir l'éditeur cron :
   ```bash
   crontab -e
Ajouter la ligne suivante :
0 8 * * * /Users/ks/MIAGE/L2/S1/Projet/Extracteur_Meteo.sh Toulouse

