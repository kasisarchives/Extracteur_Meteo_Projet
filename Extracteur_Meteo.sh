#!/bin/bash

VILLE=$1


# Téléchargement au format texte brut sans codes de couleur (?T)
curl -s "wttr.in/${VILLE}?T" > meteo_brute.txt


TEMP_ACTUELLE=$(grep "°C" meteo_brute.txt | head -n 1 | tr -s ' ' | cut -d ' ' -f 4 | xargs)
TEMP_LENDEMAIN=$(grep "°C" meteo_brute.txt | head -n 3 | tail -n 1 | tr -s ' ' | cut -d ' ' -f 4 | xargs)

DATE=$(date "+%Y-%m-%d")
HEURE=$(date "+%H:%M")
LIGNE_FORMATEE="${DATE} - ${HEURE} - ${VILLE}: ${TEMP_ACTUELLE} - ${TEMP_LENDEMAIN}"
