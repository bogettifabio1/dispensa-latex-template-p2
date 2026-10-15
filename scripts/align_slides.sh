#!/usr/bin/env bash
#
# align_slides.sh — costruisce la MAPPA DI COVERAGE annotata<->vergine per una
# lezione del modello M2 (slide-scheletro annotate dal professore, confini di
# lezione non rigidi).
#
# Perché serve: nel modello M2 una lezione attraversa più set di slide (può
# iniziare/finire a metà di un set) e il prof inserisce pagine di calcolo che
# nelle vergini non esistono. Per trascrivere bisogna sapere, pagina per pagina
# della copia annotata, a quale slide vergine corrisponde (contenuto pulito) e
# quali pagine sono invece inserite dal prof (contenuto tutto suo).
#
# Come funziona: la penna del professore è inchiostro, NON testo. Quindi il testo
# estratto con pdftotext da una pagina annotata coincide col testo stampato della
# slide vergine corrispondente. Lo script:
#   1. estrae il testo pagina-per-pagina (pdftotext) da annotata e vergini
#      -> dump ispezionabili in align/<lez>/annot/ e align/<lez>/vergine/;
#   2. chiama Claude (Haiku, compito banale: match di testo quasi identico +
#      ordine monotòno) per emettere la mappa in align/<lez>/coverage.json e un
#      riassunto leggibile in align/<lez>/coverage.txt.
#
# La mappa è ISPEZIONABILE e CORREGGIBILE a mano: rivedila prima di trascrivere.
#
# USO:
#   ./scripts/align_slides.sh <nome_lez> \
#       --annotata copia_annotata.pdf \
#       --vergine deckA.pdf [deckB.pdf ...]
#
# --annotata: esattamente un PDF (la copia annotata della lezione).
# --vergine:  uno o più PDF dei set di slide vergini che la lezione attraversa,
#             nell'ordine del corso (deck 0, 1, ...).
#
# Modello: default claude-haiku-4-5, override con la variabile d'ambiente
#   ALIGN_MODEL (es. ALIGN_MODEL=claude-sonnet-5 ./scripts/align_slides.sh ...).
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODEL="${ALIGN_MODEL:-claude-haiku-4-5}"

OUT_NAME="${1:-}"
if [[ -z "$OUT_NAME" ]]; then
  echo "Uso: $0 <nome_lez> --annotata file.pdf --vergine deckA.pdf [deckB.pdf ...]"
  exit 1
fi
shift

ANNOT=""
VERGINE=()
MODE=""
for arg in "$@"; do
  case "$arg" in
    --annotata) MODE="annot" ;;
    --vergine)  MODE="vergine" ;;
    *)
      case "$MODE" in
        annot)
          if [[ -n "$ANNOT" ]]; then
            echo "Errore: fornisci un solo file dopo --annotata."; exit 1
          fi
          ANNOT="$arg" ;;
        vergine) VERGINE+=("$arg") ;;
        *) echo "Errore: specifica --annotata o --vergine prima dei file."; exit 1 ;;
      esac ;;
  esac
done

if [[ -z "$ANNOT" ]]; then
  echo "Errore: manca --annotata (obbligatorio nel modello M2)."; exit 1
fi
if [[ ${#VERGINE[@]} -eq 0 ]]; then
  echo "Errore: fornisci almeno un deck con --vergine (M2 lo richiede)."; exit 1
fi
if [[ ! -f "$ANNOT" ]]; then
  echo "Errore: file annotata non trovato: $ANNOT"; exit 1
fi

DIR="align/${OUT_NAME}"
rm -rf "$DIR/annot" "$DIR/vergine"
mkdir -p "$DIR/annot" "$DIR/vergine"

# Estrae il testo pagina-per-pagina di un PDF. Usa il numero di pagine da pdfinfo
# per garantire che anche le pagine VUOTE (tipico delle pagine inserite a mano)
# producano un file, mantenendo la numerazione allineata al PDF. Stampa (solo) il
# numero di pagine sull'ultima riga, per la cattura via $(...).
dump_pages () {
  local pdf="$1" outdir="$2" prefix="$3"
  local n
  n="$(pdfinfo "$pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')"
  if [[ -z "$n" ]]; then
    echo "Errore: impossibile leggere il numero di pagine di $pdf" >&2
    return 1
  fi
  local i
  for (( i=1; i<=n; i++ )); do
    pdftotext -f "$i" -l "$i" "$pdf" - 2>/dev/null \
      > "$(printf '%s/%s%03d.txt' "$outdir" "$prefix" "$i")"
  done
  echo "$n"
}

echo "Estrazione testo (pdftotext) dalla copia annotata: $ANNOT"
N_ANNOT="$(dump_pages "$ANNOT" "$DIR/annot" "")"

d=0
VERGINE_LIST=""
VERGINE_JSON=""
for f in "${VERGINE[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Errore: file vergine non trovato: $f"; exit 1
  fi
  echo "Estrazione testo dal deck vergine #$d: $f"
  nd="$(dump_pages "$f" "$DIR/vergine" "${d}_")"
  VERGINE_LIST+="  deck ${d} = ${f} (${nd} pagine)"$'\n'
  if [[ -n "$VERGINE_JSON" ]]; then VERGINE_JSON+=", "; fi
  VERGINE_JSON+="\"${f}\""
  d=$((d+1))
done

# --- Costruzione del prompt per Claude ---
# I dump sono già su disco: Claude li legge da sé (Read/Glob), così il prompt
# resta piccolo (niente ARG_MAX) e i dump restano ispezionabili.
PROMPT_FILE="$(mktemp)"
{
  echo "Sei un allineatore di slide. Usa SOLO i tool Read/Glob/Write."
  echo ""
  echo "CONTESTO: una lezione universitaria (modello M2) è stata svolta su slide-scheletro"
  echo "annotate a penna dal professore. Devi allineare ogni pagina della COPIA ANNOTATA"
  echo "alla pagina delle SLIDE VERGINI pulite che le corrisponde, per ricostruire quali"
  echo "argomenti sono stati trattati e quali pagine il prof ha aggiunto a mano."
  echo ""
  echo "MATERIALE (dump di testo già estratti con pdftotext, una pagina per file):"
  echo "- Annotata: ${ANNOT} — ${N_ANNOT} pagine, in ${DIR}/annot/001.txt, 002.txt, ..."
  echo "  (la numerazione del file = numero di pagina del PDF annotato)."
  echo "- Vergini (cartella unica ${DIR}/vergine/, nome file <deck>_<pagina>.txt,"
  echo "  es. 0_034.txt = deck 0, pagina 34):"
  printf '%s' "$VERGINE_LIST"
  echo ""
  echo "Leggi i dump che ti servono con Read/Glob (non serve caricarli tutti se non serve)."
  echo ""
  echo "REGOLE DI MATCHING:"
  echo "- La penna del prof è INCHIOSTRO, non testo: il testo di una pagina annotata"
  echo "  coincide col testo stampato della slide vergine corrispondente. Testo quasi"
  echo "  identico a una vergine => match (conf: alta)."
  echo "- Pagina con testo assente o quasi vuoto, oppure senza alcuna vergine somigliante"
  echo "  => PAGINA INSERITA dal prof (es. calcolo a mano): match: null (conf: alta)."
  echo "- ORDINE MONOTONO: le pagine annotate avanzano nella lezione; la sequenza dei match"
  echo "  deve procedere IN AVANTI nelle vergini. Usa la progressione per disambiguare"
  echo "  vergini quasi identiche (slide 'a costruzione'/overlay, dove pagine consecutive"
  echo "  sono l'una prefisso dell'altra): scegli quella coerente con l'avanzamento."
  echo "- Ambiguità reale: emetti comunque la miglior ipotesi ma con conf: bassa. NON"
  echo "  scartare MAI una pagina in silenzio: ogni pagina annotata deve avere una voce."
  echo ""
  echo "OUTPUT — scrivi DUE file con Write, e nient'altro:"
  echo ""
  echo "1) ${DIR}/coverage.json — ESATTAMENTE questo schema (JSON valido, niente commenti):"
  cat <<JSON
{
  "annotata": "${ANNOT}",
  "vergini": [${VERGINE_JSON}],
  "pagine": [
    {"annot": 1, "match": {"deck": 0, "pagina": 34}, "conf": "alta"},
    {"annot": 3, "match": null, "nota": "pagina inserita (calcolo)", "conf": "alta"},
    {"annot": 8, "match": {"deck": 1, "pagina": 2}, "conf": "bassa"}
  ],
  "span": [{"deck": 0, "da": 34, "a": 51}, {"deck": 1, "da": 1, "a": 12}]
}
JSON
  echo ""
  echo "   - Una voce in \"pagine\" per OGNI pagina annotata, da 1 a ${N_ANNOT}, in ordine."
  echo "   - \"match\": {deck, pagina} se agganciata a una vergine, oppure null se inserita."
  echo "   - \"conf\": \"alta\" o \"bassa\" (bassa = da verificare a mano)."
  echo "   - \"nota\": breve, solo dove utile (es. perché è inserita, o perché sei incerto)."
  echo "   - \"span\": per ogni deck toccato, prima (\"da\") e ultima (\"a\") pagina vergine agganciata."
  echo ""
  echo "2) ${DIR}/coverage.txt — riassunto leggibile: intestazione con lo span, poi una riga"
  echo "   per pagina annotata (es. \"annot 5 -> deck 0 pag 38\" oppure \"annot 6 -> INSERITA\"),"
  echo "   e in coda l'elenco delle pagine INSERITE e di quelle a conf BASSA da verificare."
  echo ""
  echo "Non stampare la mappa a schermo: scrivila SOLO nei due file."
} > "$PROMPT_FILE"

echo ""
echo "Costruisco la mappa di coverage con Claude (${MODEL})..."
claude -p "$(cat "$PROMPT_FILE")" \
  --model "$MODEL" \
  --allowedTools "Read,Write,Glob" \
  --permission-mode acceptEdits \
  --output-format text

rm -f "$PROMPT_FILE"

echo ""
if [[ -f "$DIR/coverage.json" ]]; then
  echo "Mappa creata: $DIR/coverage.json"
  if [[ -f "$DIR/coverage.txt" ]]; then
    echo ""
    echo "----- Riassunto ($DIR/coverage.txt) -----"
    cat "$DIR/coverage.txt"
    echo "-----------------------------------------"
  fi
  echo ""
  echo "RIVEDI la mappa PRIMA di trascrivere: controlla le pagine 'inserite' e quelle a"
  echo "conf bassa, e correggi $DIR/coverage.json a mano se serve."
else
  echo "Attenzione: $DIR/coverage.json non è stato creato. Controlla l'output qui sopra."
  exit 1
fi
