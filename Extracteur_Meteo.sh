#!/bin/bash

VILLE=$1

# Téléchargement au format texte brut sans codes de couleur (?T)
curl -s "wttr.in/${VILLE}?T" > meteo_brute.txt

