#!/usr/bin/env bash
#
# figure_status.sh — interroga i file .status delle figure in figure/fig/.
#
# Ogni figura ha un file gemello <chiave>.status con i campi:
#   stato: mancante | generata | verificata
#   data: YYYY-MM-DD
#   fattibilita: facile | fattibile-da-verificare | non-conveniente
#   lezione-origine: NN
#   riferimento-prof: ...
#   note: ...
#
# Significato degli stati:
#   mancante   -> l'ancoraggio \figura{...} esiste nella lezione, ma il .tex
#                 non e' ancora stato scritto: nel PDF compare il bollino blu
#   generata   -> il .tex esiste ma non e' ancora stato controllato a vista
#   verificata -> rendering controllato e confermato corretto
#
# USO:
#   ./scripts/figure_status.sh                  # figure NON ancora verificate
#   ./scripts/figure_status.sh --stato generata # solo quelle da controllare
#   ./scripts/figure_status.sh --stato mancante # solo quelle da disegnare
#   ./scripts/figure_status.sh --lezione 02     # tutte quelle della lezione 02
#   ./scripts/figure_status.sh --fattibilita facile   # solo le facili
#   ./scripts/figure_status.sh --all            # tutto, con riepilogo
#
# I filtri --stato e --lezione si possono combinare.
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FIG_DIR="figure/fig"

FILTRO_STATO=""
FILTRO_LEZIONE=""
FILTRO_FATT=""
MOSTRA_TUTTO=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stato)       FILTRO_STATO="${2:-}"; shift 2 ;;
    --lezione)     FILTRO_LEZIONE="${2:-}"; shift 2 ;;
    --fattibilita) FILTRO_FATT="${2:-}"; shift 2 ;;
    --all)         MOSTRA_TUTTO=1; shift ;;
    -h|--help) sed -n '3,25p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "Opzione non riconosciuta: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -d "$FIG_DIR" ]]; then
  echo "Cartella $FIG_DIR non trovata." >&2
  exit 1
fi

# Legge il valore di un campo da un file .status (prima occorrenza).
campo () {
  local file="$1" nome="$2"
  sed -n "s/^${nome}:[[:space:]]*//p" "$file" | head -n1
}

trovate=0
# Log degli stati incontrati, uno per riga: il riepilogo (--all) lo aggrega con
# sort|uniq -c. Evita "declare -A" (array associativi), assente in bash 3.2
# (la versione di serie su macOS), così lo script gira anche lì.
stati_log=""

# Ordina per categoria e poi per chiave.
while IFS= read -r status_file; do
  [[ -z "$status_file" ]] && continue

  categoria="$(basename "$(dirname "$status_file")")"
  chiave="$(basename "$status_file" .status)"
  stato="$(campo "$status_file" "stato")"
  lezione="$(campo "$status_file" "lezione-origine")"
  riferimento="$(campo "$status_file" "riferimento-prof")"
  fattibilita="$(campo "$status_file" "fattibilita")"

  [[ -z "$stato" ]] && stato="(campo stato assente)"
  [[ -z "$fattibilita" ]] && fattibilita="?"
  stati_log="${stati_log}${stato}
"

  # --- filtri ---
  if [[ -n "$FILTRO_STATO" && "$stato" != "$FILTRO_STATO" ]]; then continue; fi
  if [[ -n "$FILTRO_LEZIONE" && "$lezione" != "$FILTRO_LEZIONE" ]]; then continue; fi
  if [[ -n "$FILTRO_FATT" && "$fattibilita" != "$FILTRO_FATT" ]]; then continue; fi
  # senza filtri espliciti e senza --all: mostra solo cio' che resta da fare
  if [[ $MOSTRA_TUTTO -eq 0 && -z "$FILTRO_STATO" && -z "$FILTRO_LEZIONE" \
        && -z "$FILTRO_FATT" && "$stato" == "verificata" ]]; then continue; fi

  # Coerenza: il .tex esiste davvero?
  tex_file="${status_file%.status}.tex"
  if [[ -f "$tex_file" ]]; then
    presenza="tex presente"
  else
    presenza="tex ASSENTE"
  fi

  # Un .status che dice generata/verificata ma senza .tex e' un'incoerenza:
  # nel PDF comparirebbe il bollino blu nonostante lo stato dica il contrario.
  incoerenza=""
  if [[ ! -f "$tex_file" && "$stato" != "mancante" ]]; then
    incoerenza="   <-- INCOERENTE: stato '$stato' ma il .tex non esiste"
  fi
  if [[ -f "$tex_file" && "$stato" == "mancante" ]]; then
    incoerenza="   <-- INCOERENTE: il .tex esiste ma lo stato dice 'mancante'"
  fi

  printf '%-12s %-24s %-42s lez %-4s %s\n' \
    "[$stato]" "$fattibilita" "$categoria/$chiave" "$lezione" "$presenza"
  [[ -n "$incoerenza" ]] && printf '%s\n' "$incoerenza"

  trovate=$(( trovate + 1 ))
done < <(find "$FIG_DIR" -name '*.status' -type f | sort)

echo ""
if [[ $trovate -eq 0 ]]; then
  echo "Nessuna figura corrisponde ai criteri."
else
  echo "$trovate figure elencate."
fi

if [[ $MOSTRA_TUTTO -eq 1 ]]; then
  echo ""
  echo "Riepilogo per stato:"
  printf '%s' "$stati_log" | sed '/^$/d' | sort | uniq -c \
    | while read -r n s; do printf '  %-12s %s\n' "$s" "$n"; done
fi

# Ancoraggi \figura{} presenti nelle lezioni ma senza .status: sfuggirebbero
# a qualunque tracciamento, quindi vanno segnalati.
if [[ -d lezioni ]]; then
  mancanti=""
  while IFS= read -r k; do
    [[ -z "$k" ]] && continue
    if ! find "$FIG_DIR" -name "$k.status" -type f | grep -q .; then
      mancanti="$mancanti $k"
    fi
  done < <(grep -ho '\\figura{[^}]*}' lezioni/*.tex 2>/dev/null \
           | sed 's/.*\\figura{\([^}]*\)}.*/\1/' | sort -u)

  if [[ -n "$mancanti" ]]; then
    echo ""
    echo "ATTENZIONE — ancoraggi \\figura senza file .status:"
    for k in $mancanti; do echo "  $k"; done
  fi
fi
