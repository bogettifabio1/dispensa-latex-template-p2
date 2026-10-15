#!/usr/bin/env bash
#
# new_lecture.sh — genera una bozza LaTeX a partire da uno o più PDF del
# professore e/o delle tue note, usando Claude Code in modalità headless.
#
# Utile perché il numero di file del professore (spesso a blocchi fissi,
# es. 1.5h a lezione) non corrisponde necessariamente al numero di file
# delle tue note (magari accorpi più lezioni in un unico file). Ogni
# esecuzione dello script produce UN file di output, a partire da
# QUALSIASI combinazione di file sorgente tu indichi.
#
# Dopo la trascrizione, lo script aggancia da solo la lezione a master.tex
# (\input{lezioni/<nome>}), in coda alle lezioni già presenti, così la dispensa
# si completa passo passo senza modificare master.tex a mano.
#
# USO:
#   ./scripts/new_lecture.sh <nome_output> [--solo-raster] \
#       --prof file1.pdf [file2.pdf ...] \
#       --mine file1.pdf [file2.pdf ...] \
#       --annotata copia_annotata.pdf --vergine deckA.pdf [deckB.pdf ...] \
#       [--senza-note]
#
# Almeno uno tra --prof, --mine e --annotata va fornito.
# I percorsi possono essere assoluti o relativi alla root del progetto;
# non serve che i file siano già dentro raw/, ma è consigliato mettercili.
#
# --annotata/--vergine (modello M2 — slide-scheletro annotate, confini non
#   rigidi): --annotata vuole ESATTAMENTE un file (la copia annotata di questa
#   lezione), --vergine uno o più deck di slide pulite che la lezione
#   attraversa. Se forniti entrambi (fuori da --solo-raster), lo script chiama
#   da sé scripts/align_slides.sh per costruire la mappa di coverage PRIMA di
#   trascrivere: vanno quindi forniti insieme, tranne che in --solo-raster
#   (dove si vuole solo rasterizzare le vergini per il campione di
#   /professor-profile).
#
# --senza-note: se non fornisci nessun file con --mine, lo script si ferma e ti
#   avvisa che mancano le tue note personali (di norma servono ad arricchire la
#   trascrizione con quello che il prof dice a voce). Se vuoi comunque
#   trascrivere solo dal materiale del professore, rilancia lo stesso comando
#   aggiungendo --senza-note. Non si applica a --solo-raster.
#
# --solo-raster: rasterizza soltanto (nessuna trascrizione, nessuna
#   compilazione) e si ferma. Serve a preparare le immagini di un campione di
#   lezioni per la skill /professor-profile, che deduce la notazione e lo stile
#   del professore PRIMA di trascrivere. Il campione va in un unico
#   <nome_output> (es. "campione-profilo") con più file --prof.
#
# ESEMPI:
#   # Un file del prof, nessuna tua nota per questo blocco
#   ./scripts/new_lecture.sh lezione01 \
#       --prof "raw/prof/01_NomeArgomento.pdf"
#
#   # Due file del prof (due blocchi da 1.5h) + un tuo file che li copre entrambi
#   ./scripts/new_lecture.sh lezione02-03 \
#       --prof "raw/prof/02_NomeArgomento.pdf" \
#              "raw/prof/03_NomeArgomento.pdf" \
#       --mine "raw/mine/Lez 2-3 NomeCorso.pdf"
#
#   # Solo rasterizzazione di 3 lezioni campione, per /professor-profile
#   ./scripts/new_lecture.sh campione-profilo --solo-raster \
#       --prof "raw/prof/01_NomeArgomento.pdf" \
#              "raw/prof/02_NomeArgomento.pdf" \
#              "raw/prof/03_NomeArgomento.pdf"
#
#   # Lezione M2: copia annotata + i due deck di slide vergini che attraversa
#   ./scripts/new_lecture.sh lezione05 \
#       --annotata "raw/prof/lez05_annotata.pdf" \
#       --vergine "raw/prof/deckA.pdf" "raw/prof/deckB.pdf" \
#       --mine "raw/mine/mie-note-lez5.pdf"
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT_NAME="${1:-}"
if [[ -z "$OUT_NAME" ]]; then
  echo "Uso: $0 <nome_output> --prof file1.pdf [...] --mine file1.pdf [...]"
  exit 1
fi
shift

PROF_FILES=()
MINE_FILES=()
ANNOTATA_FILE=""
VERGINE_FILES=()
MODE=""
ONLY_RASTER=0
SENZA_NOTE=0
for arg in "$@"; do
  case "$arg" in
    --solo-raster) ONLY_RASTER=1 ;;
    --senza-note) SENZA_NOTE=1 ;;
    --prof) MODE="prof" ;;
    --mine) MODE="mine" ;;
    --annotata) MODE="annotata" ;;
    --vergine) MODE="vergine" ;;
    *)
      case "$MODE" in
        prof) PROF_FILES+=("$arg") ;;
        mine) MINE_FILES+=("$arg") ;;
        annotata)
          if [[ -n "$ANNOTATA_FILE" ]]; then
            echo "Errore: fornisci un solo file dopo --annotata."
            exit 1
          fi
          ANNOTATA_FILE="$arg" ;;
        vergine) VERGINE_FILES+=("$arg") ;;
        *)
          echo "Errore: specifica --prof, --mine, --annotata o --vergine prima dei file."
          exit 1 ;;
      esac
      ;;
  esac
done

if [[ ${#PROF_FILES[@]} -eq 0 && ${#MINE_FILES[@]} -eq 0 && -z "$ANNOTATA_FILE" ]]; then
  echo "Errore: fornisci almeno un file con --prof, --mine o --annotata."
  exit 1
fi

# Nessuna nota personale: ci si ferma una volta per avvisare. Non si chiede
# conferma da tastiera perche' lo script puo' girare senza terminale (es.
# lanciato da Claude Code): basta rilanciarlo con --senza-note per procedere.
if [[ "$ONLY_RASTER" -eq 0 && ${#MINE_FILES[@]} -eq 0 && "$SENZA_NOTE" -eq 0 ]]; then
  echo "ATTENZIONE: non hai fornito nessuna nota personale (--mine)."
  echo "Le note arricchiscono la trascrizione con cio' che il professore dice a voce."
  echo "Carica le pagine delle tue note in raw/mine/ e rilancia con --mine <file>."
  echo "Se vuoi trascrivere comunque solo dal materiale del professore, rilancia"
  echo "lo stesso comando aggiungendo --senza-note."
  exit 1
fi

# M2: --annotata e --vergine vanno forniti insieme, perché lo script chiama
# align_slides.sh prima di trascrivere. Eccezione: --solo-raster, dove si vuole
# solo rasterizzare (es. le vergini per il campione di /professor-profile) e
# nessun allineamento viene eseguito.
if [[ "$ONLY_RASTER" -eq 0 ]]; then
  if [[ -n "$ANNOTATA_FILE" && ${#VERGINE_FILES[@]} -eq 0 ]]; then
    echo "Errore: --annotata richiede almeno un --vergine (modello M2)."
    exit 1
  fi
  if [[ -z "$ANNOTATA_FILE" && ${#VERGINE_FILES[@]} -gt 0 ]]; then
    echo "Errore: --vergine richiede --annotata (modello M2); per campionare solo le vergini usa --solo-raster."
    exit 1
  fi
fi

if [[ -n "$ANNOTATA_FILE" && ! -f "$ANNOTATA_FILE" ]]; then
  echo "Errore: file annotata non trovato: $ANNOTATA_FILE"
  exit 1
fi
# Nota: come per rasterize_all, si evita di espandere l'array se è vuoto (bash
# 3.2 di macOS darebbe "unbound variable" con set -u).
if [[ ${#VERGINE_FILES[@]} -gt 0 ]]; then
  for f in "${VERGINE_FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
      echo "Errore: file vergine non trovato: $f"
      exit 1
    fi
  done
fi

IMG_DIR="raw/_images/${OUT_NAME}"
OUT_TEX="lezioni/${OUT_NAME}.tex"
mkdir -p "$IMG_DIR" lezioni

# --- 1. Rasterizzazione di tutti i file forniti ---
rasterize_all () {
  local prefix="$1"
  shift
  local files=("$@")
  local i=1
  for f in "${files[@]}"; do
    if [[ ! -f "$f" ]]; then
      echo "Attenzione: file non trovato, salto: $f"
      continue
    fi
    echo "Rasterizzo ($prefix #$i): $f ..."
    # ogni file sorgente in un proprio sotto-prefisso, per non confondere le pagine tra file diversi
    # 150 dpi: una pagina A4 resta sotto i 2000px sul lato lungo, limite oltre il
    # quale le richieste con molte immagini vengono rifiutate dal modello.
    pdftoppm -png -r 150 "$f" "${IMG_DIR}/${prefix}${i}_"
    i=$((i+1))
  done
}

# Nota: su bash 3.2 (macOS di serie) espandere un array VUOTO con set -u dà
# "unbound variable", quindi si chiama rasterize_all solo se la lista non è vuota.
if [[ ${#PROF_FILES[@]} -gt 0 ]]; then rasterize_all "prof" "${PROF_FILES[@]}"; fi
if [[ ${#MINE_FILES[@]} -gt 0 ]]; then rasterize_all "mine" "${MINE_FILES[@]}"; fi

# Copia annotata (M2): un solo file, prefisso "annotata_" (nessun indice, ce n'è
# sempre uno solo). Deck vergini: un prefisso "vergine<D>_" per deck, D a partire
# da 0 — stessa numerazione di deck usata da align_slides.sh, così le immagini
# rasterizzate qui e la mappa di coverage restano coerenti.
if [[ -n "$ANNOTATA_FILE" ]]; then
  echo "Rasterizzo (annotata): $ANNOTATA_FILE ..."
  pdftoppm -png -r 150 "$ANNOTATA_FILE" "${IMG_DIR}/annotata_"
fi
if [[ ${#VERGINE_FILES[@]} -gt 0 ]]; then
  d=0
  for f in "${VERGINE_FILES[@]}"; do
    echo "Rasterizzo (vergine deck $d): $f ..."
    pdftoppm -png -r 150 "$f" "${IMG_DIR}/vergine${d}_"
    d=$((d+1))
  done
fi

# --- 1b. Modalità sola rasterizzazione: ci si ferma qui ---
if [[ "$ONLY_RASTER" -eq 1 ]]; then
  echo ""
  echo "Sola rasterizzazione completata: immagini in ${IMG_DIR}."
  echo "Nessuna trascrizione né compilazione eseguita."
  echo ""
  echo "Prossimo passo: deduci notazione e stile del professore con la skill"
  echo "  /professor-profile"
  echo "indicando di analizzare le lezioni campione in ${IMG_DIR} (prefisso prof... o vergine...)."
  exit 0
fi

# --- 1c. Modello M2: mappa di coverage annotata<->vergine ---
# Costruita PRIMA del prompt di trascrizione, perché lecture-transcribe la legge
# come input. La mappa opera sui PDF originali (pdftotext), non sulle immagini
# appena rasterizzate: l'ordine coi due passi sopra non conta.
COVERAGE_JSON=""
if [[ -n "$ANNOTATA_FILE" ]]; then
  echo ""
  echo "Costruisco la mappa di coverage annotata<->vergine (modello M2)..."
  ./scripts/align_slides.sh "$OUT_NAME" --annotata "$ANNOTATA_FILE" --vergine "${VERGINE_FILES[@]}"
  COVERAGE_JSON="align/${OUT_NAME}/coverage.json"
fi

# --- 2. Costruzione del prompt per Claude Code ---
PROMPT_FILE="$(mktemp)"
{
  echo "/lecture-transcribe"
  echo ""
  echo "Nome output: ${OUT_NAME}"
  echo ""
  echo "File del professore forniti per questo blocco (immagini in ${IMG_DIR}, prefisso prof1_, prof2_, ...):"
  if [[ ${#PROF_FILES[@]} -eq 0 ]]; then
    echo "(nessuno)"
  else
    for f in "${PROF_FILES[@]}"; do echo "- $f"; done
  fi
  echo ""
  echo "File di note personali forniti (immagini in ${IMG_DIR}, prefisso mine1_, mine2_, ...):"
  if [[ ${#MINE_FILES[@]} -eq 0 ]]; then
    echo "(nessuno)"
  else
    for f in "${MINE_FILES[@]}"; do echo "- $f"; done
  fi
  echo ""
  if [[ -n "$ANNOTATA_FILE" ]]; then
    echo "Materiale M2 (slide-scheletro annotate, confini non rigidi):"
    echo "- Copia annotata (immagini in ${IMG_DIR}, prefisso annotata_...): ${ANNOTATA_FILE}"
    echo "- Slide vergini per deck (immagini in ${IMG_DIR}, prefisso vergine<D>_..., D=0,1,...):"
    d=0
    for f in "${VERGINE_FILES[@]}"; do
      echo "  - deck ${d}: $f"
      d=$((d+1))
    done
    echo "- Mappa di coverage: ${COVERAGE_JSON} (leggila con Read PRIMA di trascrivere; segui le istruzioni per il modello M2 nella skill lecture-transcribe)."
    echo ""
  fi
  echo "IMPORTANTE: i file di note personali potrebbero coprire PIÙ blocchi di lezione del professore (es. una tua nota unica per 2-3 file del prof)."
  echo "Estrai dalle note personali SOLO il contenuto pertinente agli argomenti trattati nei file del professore forniti in questa esecuzione."
  echo "Se non è chiaro dove finisce il contenuto pertinente e inizia quello di un altro blocco, inserisci un \\revisione{...} invece di indovinare il confine."
  echo ""
  echo "Segui le convenzioni in CLAUDE.md e preamble.tex."
  echo "Scrivi il risultato in ${OUT_TEX}."
} > "$PROMPT_FILE"

# --- 3. Chiamata a Claude Code in modalità headless ---
echo "Genero la bozza LaTeX con Claude Code..."
claude -p "$(cat "$PROMPT_FILE")" \
  --allowedTools "Read,Write,Edit,Glob" \
  --permission-mode acceptEdits \
  --output-format text

rm -f "$PROMPT_FILE"

# --- 4. Inserimento automatico dell'\input in master.tex ---
# Così la dispensa si completa passo passo: ogni lezione trascritta viene
# agganciata a master.tex senza intervento manuale. Idempotente (se la riga c'è
# già, non fa nulla). La nuova \input va DOPO l'ultima \input{lezioni/...} NON
# commentata (accumulo in ordine di aggiunta); se non ce n'è ancora nessuna, va
# subito prima di \end{document} e lo si segnala, perché potrebbe non trovarsi
# sotto un \chapter.
# Nota: si confrontano stringhe (substr), non regex con backslash. E ogni
# letterale che contiene un backslash (\input..., \end...) passa dall'ambiente e
# si legge con ENVIRON: un backslash scritto dentro il programma awk (in un
# regex, in una stringa o in -v) verrebbe interpretato come escape e perso.
_pre='\input{lezioni/'
_ends='\end{document}'
_ins='\input{lezioni/'"$OUT_NAME"'}'
if [[ -f "master.tex" ]]; then
  # già presente? (riga non commentata con ESATTAMENTE questa lezione)
  if _tgt="$_ins" awk '
      BEGIN { tgt = ENVIRON["_tgt"] }
      { t=$0; sub(/^[ \t]+/,"",t); if (substr(t,1,length(tgt))==tgt) f=1 }
      END { exit(f?0:1) }' master.tex; then
    echo "master.tex include già \\input{lezioni/${OUT_NAME}}: nessuna modifica."
  else
    tmp="$(mktemp)"
    # inserisce e comunica via exit code se c'erano lezioni precedenti (0) o no (1)
    if _pre="$_pre" _ends="$_ends" _ins="$_ins" awk '
        BEGIN { pre=ENVIRON["_pre"]; ends=ENVIRON["_ends"]; ins=ENVIRON["_ins"] }
        { lines[NR]=$0; t=$0; sub(/^[ \t]+/,"",t)
          if (substr(t,1,length(pre))==pre) last=NR
          if (!end && substr(t,1,length(ends))==ends) end=NR }
        END { at=(last>0)?last:((end>0)?end-1:NR)
              for (i=1;i<=NR;i++) { print lines[i]; if (i==at) print ins }
              exit(last>0?0:1) }' master.tex > "$tmp"; then
      had_prior=1
    else
      had_prior=0
    fi
    mv "$tmp" master.tex
    if [[ "$had_prior" -eq 1 ]]; then
      echo "Aggiunta \\input{lezioni/${OUT_NAME}} in master.tex (dopo l'ultima lezione)."
    else
      echo "Aggiunta \\input{lezioni/${OUT_NAME}} in master.tex."
      echo "ATTENZIONE: era la prima lezione inclusa — controlla che stia sotto il \\chapter{} giusto."
    fi
  fi
fi

# --- 5. Compilazione immediata (opzionale) ---
if command -v latexmk >/dev/null 2>&1 && [[ -f "master.tex" ]]; then
  echo "Compilo master.tex ..."
  latexmk -pdf -interaction=nonstopmode master.tex >/dev/null
  echo "Fatto. Apri master.pdf e guarda i bollini: rossi = da verificare (\\revisione), blu = disegno da inserire (\\figuramancante)."
else
  echo "Fatto. Frammento generato in ${OUT_TEX}."
fi
