#Requires -Version 5.1
#
# align_slides.ps1 - costruisce la MAPPA DI COVERAGE annotata<->vergine per una
# lezione del modello M2 (slide-scheletro annotate dal professore, confini di
# lezione non rigidi). Versione PowerShell di scripts/align_slides.sh.
#
# Perche' serve: nel modello M2 una lezione attraversa piu' set di slide (puo'
# iniziare/finire a meta' di un set) e il prof inserisce pagine di calcolo che
# nelle vergini non esistono. Per trascrivere bisogna sapere, pagina per pagina
# della copia annotata, a quale slide vergine corrisponde (contenuto pulito) e
# quali pagine sono invece inserite dal prof (contenuto tutto suo).
#
# Come funziona: la penna del professore e' inchiostro, NON testo. Quindi il testo
# estratto con pdftotext da una pagina annotata coincide col testo stampato della
# slide vergine corrispondente. Lo script estrae il testo pagina-per-pagina
# (dump ispezionabili in align/<lez>/annot|vergine/) e chiede a Claude (Haiku,
# compito banale: match di testo quasi identico + ordine monotono) di emettere la
# mappa in align/<lez>/coverage.json e un riassunto in align/<lez>/coverage.txt.
#
# La mappa e' ISPEZIONABILE e CORREGGIBILE a mano: rivedila prima di trascrivere.
#
# USO:
#   .\scripts\align_slides.ps1 <nome_lez> `
#       --annotata copia_annotata.pdf `
#       --vergine deckA.pdf [deckB.pdf ...]
#
# Modello: default claude-haiku-4-5, override con la variabile d'ambiente
#   ALIGN_MODEL  (es. $env:ALIGN_MODEL = 'claude-sonnet-5').
#
param(
  [string]$OutName,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

$Model = if ($env:ALIGN_MODEL) { $env:ALIGN_MODEL } else { 'claude-haiku-4-5' }

if (-not $OutName) {
  Write-Host 'Uso: .\scripts\align_slides.ps1 <nome_lez> --annotata file.pdf --vergine deckA.pdf [deckB.pdf ...]'
  exit 1
}

# --- Parsing degli argomenti (--annotata uno solo, --vergine uno o piu') ---
$Annot = $null
$Vergine = @()
$mode = $null
foreach ($a in $Rest) {
  switch -CaseSensitive ($a) {
    '--annotata' { $mode = 'annot'; continue }
    '--vergine'  { $mode = 'vergine'; continue }
    default {
      if ($mode -eq 'annot') {
        if ($Annot) { Write-Host 'Errore: fornisci un solo file dopo --annotata.'; exit 1 }
        $Annot = $a
      } elseif ($mode -eq 'vergine') {
        $Vergine += $a
      } else {
        Write-Host 'Errore: specifica --annotata o --vergine prima dei file.'; exit 1
      }
    }
  }
}

if (-not $Annot) {
  Write-Host 'Errore: manca --annotata (obbligatorio nel modello M2).'; exit 1
}
if ($Vergine.Count -eq 0) {
  Write-Host 'Errore: fornisci almeno un deck con --vergine (M2 lo richiede).'; exit 1
}
if (-not (Test-Path -LiteralPath $Annot)) {
  Write-Host "Errore: file annotata non trovato: $Annot"; exit 1
}

$Dir = Join-Path 'align' $OutName
$AnnotDir = Join-Path $Dir 'annot'
$VergDir  = Join-Path $Dir 'vergine'
if (Test-Path -LiteralPath $AnnotDir) { Remove-Item -Recurse -Force -LiteralPath $AnnotDir }
if (Test-Path -LiteralPath $VergDir)  { Remove-Item -Recurse -Force -LiteralPath $VergDir }
New-Item -ItemType Directory -Force -Path $AnnotDir | Out-Null
New-Item -ItemType Directory -Force -Path $VergDir  | Out-Null

# Estrae il testo pagina-per-pagina di un PDF. Usa il numero di pagine da pdfinfo
# cosi' anche le pagine VUOTE (tipiche delle pagine inserite a mano) producono un
# file, mantenendo la numerazione allineata al PDF.
function Dump-Pages {
  param([string]$Pdf, [string]$OutDir, [string]$Prefix)
  $info = & pdfinfo $Pdf
  $pagesLine = $info | Where-Object { $_ -match '^Pages:\s+(\d+)' } | Select-Object -First 1
  if (-not $pagesLine) {
    Write-Host "Errore: impossibile leggere il numero di pagine di $Pdf"; exit 1
  }
  [void]($pagesLine -match '^Pages:\s+(\d+)')
  $n = [int]$Matches[1]
  for ($i = 1; $i -le $n; $i++) {
    $out = Join-Path $OutDir ('{0}{1:D3}.txt' -f $Prefix, $i)
    (& pdftotext -f $i -l $i $Pdf -) | Out-File -FilePath $out -Encoding utf8
  }
  return $n
}

Write-Host "Estrazione testo (pdftotext) dalla copia annotata: $Annot"
$NAnnot = Dump-Pages -Pdf $Annot -OutDir $AnnotDir -Prefix ''

$d = 0
$VergineList = ''
$VergineJson = ''
foreach ($f in $Vergine) {
  if (-not (Test-Path -LiteralPath $f)) {
    Write-Host "Errore: file vergine non trovato: $f"; exit 1
  }
  Write-Host "Estrazione testo dal deck vergine #${d}: $f"
  $nd = Dump-Pages -Pdf $f -OutDir $VergDir -Prefix ("{0}_" -f $d)
  $VergineList += "  deck $d = $f ($nd pagine)`n"
  if ($VergineJson -ne '') { $VergineJson += ', ' }
  $VergineJson += '"' + $f + '"'
  $d++
}

# Percorsi con slash in avanti nel prompt (validi anche su Windows per i tool).
$DirF = $Dir -replace '\\', '/'

# --- Prompt per Claude (piccolo: i dump li legge da se' con Read/Glob) ---
$prompt = @"
Sei un allineatore di slide. Usa SOLO i tool Read/Glob/Write.

CONTESTO: una lezione universitaria (modello M2) e' stata svolta su slide-scheletro
annotate a penna dal professore. Devi allineare ogni pagina della COPIA ANNOTATA
alla pagina delle SLIDE VERGINI pulite che le corrisponde, per ricostruire quali
argomenti sono stati trattati e quali pagine il prof ha aggiunto a mano.

MATERIALE (dump di testo gia' estratti con pdftotext, una pagina per file):
- Annotata: $Annot - $NAnnot pagine, in $DirF/annot/001.txt, 002.txt, ...
  (la numerazione del file = numero di pagina del PDF annotato).
- Vergini (cartella unica $DirF/vergine/, nome file <deck>_<pagina>.txt,
  es. 0_034.txt = deck 0, pagina 34):
$VergineList
Leggi i dump che ti servono con Read/Glob (non serve caricarli tutti se non serve).

REGOLE DI MATCHING:
- La penna del prof e' INCHIOSTRO, non testo: il testo di una pagina annotata
  coincide col testo stampato della slide vergine corrispondente. Testo quasi
  identico a una vergine => match (conf: alta).
- Pagina con testo assente o quasi vuoto, oppure senza alcuna vergine somigliante
  => PAGINA INSERITA dal prof (es. calcolo a mano): match: null (conf: alta).
- ORDINE MONOTONO: le pagine annotate avanzano nella lezione; la sequenza dei match
  deve procedere IN AVANTI nelle vergini. Usa la progressione per disambiguare
  vergini quasi identiche (slide 'a costruzione'/overlay, dove pagine consecutive
  sono l'una prefisso dell'altra): scegli quella coerente con l'avanzamento.
- Ambiguita' reale: emetti comunque la miglior ipotesi ma con conf: bassa. NON
  scartare MAI una pagina in silenzio: ogni pagina annotata deve avere una voce.

OUTPUT - scrivi DUE file con Write, e nient'altro:

1) $DirF/coverage.json - ESATTAMENTE questo schema (JSON valido, niente commenti):
{
  "annotata": "$Annot",
  "vergini": [$VergineJson],
  "pagine": [
    {"annot": 1, "match": {"deck": 0, "pagina": 34}, "conf": "alta"},
    {"annot": 3, "match": null, "nota": "pagina inserita (calcolo)", "conf": "alta"},
    {"annot": 8, "match": {"deck": 1, "pagina": 2}, "conf": "bassa"}
  ],
  "span": [{"deck": 0, "da": 34, "a": 51}, {"deck": 1, "da": 1, "a": 12}]
}

   - Una voce in "pagine" per OGNI pagina annotata, da 1 a $NAnnot, in ordine.
   - "match": {deck, pagina} se agganciata a una vergine, oppure null se inserita.
   - "conf": "alta" o "bassa" (bassa = da verificare a mano).
   - "nota": breve, solo dove utile (es. perche' e' inserita, o perche' sei incerto).
   - "span": per ogni deck toccato, prima ("da") e ultima ("a") pagina vergine agganciata.

2) $DirF/coverage.txt - riassunto leggibile: intestazione con lo span, poi una riga
   per pagina annotata (es. "annot 5 -> deck 0 pag 38" oppure "annot 6 -> INSERITA"),
   e in coda l'elenco delle pagine INSERITE e di quelle a conf BASSA da verificare.

Non stampare la mappa a schermo: scrivila SOLO nei due file.
"@

Write-Host ''
Write-Host "Costruisco la mappa di coverage con Claude ($Model)..."
& claude -p $prompt --model $Model --allowedTools "Read,Write,Glob" --permission-mode acceptEdits --output-format text

$Cov = Join-Path $Dir 'coverage.json'
$CovTxt = Join-Path $Dir 'coverage.txt'
Write-Host ''
if (Test-Path -LiteralPath $Cov) {
  Write-Host "Mappa creata: $Cov"
  if (Test-Path -LiteralPath $CovTxt) {
    Write-Host ''
    Write-Host "----- Riassunto ($CovTxt) -----"
    Get-Content -LiteralPath $CovTxt | ForEach-Object { Write-Host $_ }
    Write-Host '-----------------------------------------'
  }
  Write-Host ''
  Write-Host "RIVEDI la mappa PRIMA di trascrivere: controlla le pagine 'inserite' e quelle a"
  Write-Host "conf bassa, e correggi $Cov a mano se serve."
} else {
  Write-Host "Attenzione: $Cov non e' stato creato. Controlla l'output qui sopra."
  exit 1
}
