#!/usr/bin/env bash
#
# check_setup.sh — verifica che gli strumenti richiesti dal template siano
# installati e raggiungibili dal terminale (sul PATH), e per ognuno che manca
# dice cosa fare. Non modifica nulla: solo diagnostica.
#
# USO:
#   ./scripts/check_setup.sh
#
# Esce con codice 0 se c'è tutto, 1 se manca almeno uno strumento essenziale.
#
# Nota: su macOS pdftoppm NON è incluso in MacTeX, va installato con Poppler
# (brew install poppler); perl è già preinstallato.
set -uo pipefail

# Comando | a cosa serve | suggerimento se manca (campi separati da "|").
strumenti=(
  "claude|Claude Code (assistente che trascrive le lezioni)|installa con:  curl -fsSL https://claude.ai/install.sh | bash   poi chiudi e riapri il Terminale"
  "latexmk|compila master.tex in PDF|installa MacTeX:  brew install --cask mactex-no-gui , poi riapri il Terminale"
  "pdftoppm|converte i PDF del professore in immagini (rasterizzazione)|manca Poppler:  brew install poppler , poi riapri il Terminale"
  "perl|richiesto internamente da latexmk|di norma preinstallato su macOS/Linux; altrimenti vedi https://www.perl.org/get.html"
)

echo ""
echo "Verifica degli strumenti richiesti dal template:"
echo ""

mancanti=0
for voce in "${strumenti[@]}"; do
  cmd="${voce%%|*}"
  resto="${voce#*|}"
  serve="${resto%%|*}"
  aiuto="${resto#*|}"

  if percorso="$(command -v "$cmd" 2>/dev/null)"; then
    printf '%-10s OK   (%s)\n' "$cmd" "$percorso"
  else
    printf '%-10s MANCA - %s\n' "$cmd" "$serve"
    printf '           -> %s\n' "$aiuto"
    mancanti=$(( mancanti + 1 ))
  fi
done

# --- Privacy: il materiale in raw/ non deve finire su un repo pubblico ---------
# Solo avvisi: non cambiano il codice di uscita (una materia privata puo' voler
# versionare i PDF di proposito), ma segnalano il rischio.
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo ""
  echo "Controllo privacy del materiale in raw/:"
  avvisi=0
  if ! git check-ignore -q raw/prof/prova.pdf 2>/dev/null; then
    echo "ATTENZIONE: git NON ignora i PDF in raw/prof/ (e/o raw/mine/): un 'git add .' li includerebbe."
    avvisi=$(( avvisi + 1 ))
  fi
  versionati="$(git ls-files raw 2>/dev/null | grep -v '/\.gitkeep$' || true)"
  if [[ -n "$versionati" ]]; then
    echo "ATTENZIONE: questi file di raw/ sono versionati (coperti da copyright / personali):"
    printf '%s\n' "$versionati" | sed 's/^/  /'
    avvisi=$(( avvisi + 1 ))
  fi
  if [[ $avvisi -eq 0 ]]; then
    echo "OK   raw/ e' ignorato da git e nessun file del materiale e' versionato."
  else
    echo "Non rendere MAI pubblico questo repo finche' ci sono PDF del professore o lezioni trascritte: vedi README."
  fi
fi

echo ""
if [[ $mancanti -eq 0 ]]; then
  echo "Tutto a posto: puoi procedere con il flusso di lavoro (vedi README)."
  exit 0
else
  echo "$mancanti strumento/i da sistemare prima di procedere (vedi i suggerimenti sopra)."
  echo "Dopo aver installato qualcosa, chiudi e riapri il Terminale e rilancia questo script."
  exit 1
fi
