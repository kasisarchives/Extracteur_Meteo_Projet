#!/bin/bash

# V2 : cron lance le script depuis le dossier personnel ; on se place dans le
# dossier du script pour que meteo_brute.txt et meteo.txt soient créés à côté.
if [[ "$0" == */* ]]; then
    cd "${0%/*}" || exit 1
fi

if [ -z "$1" ]; then
  VILLE="Toulouse"
else
  VILLE="$1"
fi

# Téléchargement au format texte brut sans codes de couleur (?T)
curl -s "wttr.in/${VILLE}?T" > meteo_brute.txt

# Motif d'une température wttr.in : "+9(8) °C", "13 °C" ou "-1(-5) °C" (ressenti entre parenthèses)
REGEX_TEMP='[-+]?[0-9]+([(][-+]?[0-9]+[)])? °C'
# 1re ligne contenant °C = conditions actuelles
TEMP_ACTUELLE=$(grep "°C" meteo_brute.txt | head -n 1 | grep -oE "$REGEX_TEMP" | head -n 1 | cut -d '(' -f 1 | cut -d ' ' -f 1 | tr -d '+')°C
# 3e ligne contenant °C = tableau du lendemain (Matin | Midi | Soir | Nuit) : on garde Midi
TEMP_LENDEMAIN=$(grep "°C" meteo_brute.txt | head -n 3 | tail -n 1 | grep -oE "$REGEX_TEMP" | head -n 2 | tail -n 1 | cut -d '(' -f 1 | cut -d ' ' -f 1 | tr -d '+')°C

DATE=$(date "+%Y-%m-%d")
HEURE=$(date "+%H:%M")
LIGNE_FORMATEE="${DATE} - ${HEURE} - ${VILLE} : ${TEMP_ACTUELLE} - ${TEMP_LENDEMAIN}"

# V1.4 : enregistrement, une ligne par exécution ajoutée à la fin de meteo.txt
echo "$LIGNE_FORMATEE" >> meteo.txt
