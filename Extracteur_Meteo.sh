#!/bin/bash

# V2 : cron lance le script depuis le dossier personnel ; on se place dans le
# dossier du script pour que meteo_brute.txt et meteo.txt soient créés à côté.
if [[ "$0" == */* ]]; then
    cd "${0%/*}" || exit 1
fi

# V3 : lecture des options
#   -a, --archive : enregistre dans le fichier du jour meteo_AAAAMMJJ.txt
#   -h, --help    : affiche l'aide
ARCHIVE=0
VILLE=""
while [ $# -gt 0 ]; do
    case "$1" in
        -a|--archive) ARCHIVE=1 ;;
        -h|--help)    echo "Usage : $0 [-a] [Ville]   (ville par défaut : Toulouse)"; exit 0 ;;
        -*)           echo "Option inconnue : $1" >&2; echo "Usage : $0 [-a] [Ville]" >&2; exit 1 ;;
        *)            VILLE="$1" ;;
    esac
    shift
done

# V2.1 : ville par défaut si aucune ville n'est fournie
if [ -z "$VILLE" ]; then
    VILLE="Toulouse"
fi

# Télécharge la météo en texte brut, avec un délai maximal de 30 secondes.
curl --fail --silent --show-error --connect-timeout 10 --max-time 30 \
    "https://wttr.in/${VILLE// /%20}?T" > meteo_brute.txt

# Récupère le code de retour de curl : 0 signifie que le téléchargement a réussi.
CODE_CURL=$?
# En cas d’échec, écrit une erreur datée dans le journal et arrête le script.
if [ "$CODE_CURL" -ne 0 ]; then
    MESSAGE="[$(date '+%Y-%m-%d %H:%M:%S')] Échec de la récupération météo pour $VILLE (curl : $CODE_CURL)."
    echo "$MESSAGE" >> meteo_error.log
    echo "$MESSAGE" >&2
    exit "$CODE_CURL"
fi

# Motif d'une température wttr.in : "+9(8) °C", "13 °C" ou "-1(-5) °C" (ressenti entre parenthèses)
REGEX_TEMP='[-+]?[0-9]+([(][-+]?[0-9]+[)])? °C'
# 1re ligne contenant °C = conditions actuelles
TEMP_ACTUELLE=$(grep "°C" meteo_brute.txt | head -n 1 | grep -oE "$REGEX_TEMP" | head -n 1 | cut -d '(' -f 1 | cut -d ' ' -f 1 | tr -d '+')°C
# 3e ligne contenant °C = tableau du lendemain (Matin | Midi | Soir | Nuit) : on garde Midi
TEMP_LENDEMAIN=$(grep "°C" meteo_brute.txt | head -n 3 | tail -n 1 | grep -oE "$REGEX_TEMP" | head -n 2 | tail -n 1 | cut -d '(' -f 1 | cut -d ' ' -f 1 | tr -d '+')°C

DATE=$(date "+%Y-%m-%d")
HEURE=$(date "+%H:%M")
LIGNE_FORMATEE="${DATE} - ${HEURE} - ${VILLE} : ${TEMP_ACTUELLE} - ${TEMP_LENDEMAIN}"

# V1.4 : enregistrement, une ligne par exécution ajoutée à la fin du fichier
# V3   : avec -a, on archive dans un fichier différent chaque jour (meteo_AAAAMMJJ.txt)
if [ $ARCHIVE -eq 1 ]; then
    FICHIER_SORTIE="meteo_$(date "+%Y%m%d").txt"
else
    FICHIER_SORTIE="meteo.txt"
fi
echo "$LIGNE_FORMATEE" >> "$FICHIER_SORTIE"
echo "$LIGNE_FORMATEE  ->  $FICHIER_SORTIE"
