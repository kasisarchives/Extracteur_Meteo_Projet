#!/bin/bash

if [ -z "$1" ]; then
    VILLE="Toulouse"
else
    VILLE="$1"
fi

# Téléchargement au format texte brut sans codes de couleur (?T)
curl -s "wttr.in/${VILLE}?T" > meteo_brute.txt

REGEX_TEMP='[-+]?[0-9]+\+?(\(([-+]?[0-9]+\+)?\))?\ °C'
TEMP_ACTUELLE=$(grep "°C" meteo_brute.txt | head -n 1 | grep -o "$REGEX_TEMP" | head -n 1 | cut -d '(' -f 1 | cut -d ' ' -f 1 | tr -d '+')°C
TEMP_LENDEMAIN=$(grep "°C" meteo_brute.txt | head -n 3 | tail -n 1 | grep -o "$REGEX_TEMP" | head -n 2 | tail -n 1 | cut -d '(' -f 1 | cut -d ' ' -f 1 | tr -d '+')°C

DATE=$(date "+%Y-%m-%d")
HEURE=$(date "+%H:%M")
LIGNE_FORMATEE="${DATE} - ${HEURE} - ${VILLE} : ${TEMP_ACTUELLE} - ${TEMP_LENDEMAIN}"

# V1.4 : enregistrement, une ligne par exécution ajoutée à la fin de meteo.txt
echo "$LIGNE_FORMATEE" >> meteo.txt
