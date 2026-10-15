<#
  new_lecture.ps1 - genera una bozza LaTeX a partire da uno o piu' PDF del
  professore e/o delle tue note, usando Claude Code in modalita' headless.

  Versione PowerShell (Windows) di scripts/new_lecture.sh: stessa logica, ma
  sintassi degli argomenti nativa PowerShell (niente Git Bash necessario).
  Testato su Windows PowerShell 5.1.

  Utile perche' il numero di file del professore (spesso a blocchi fissi,
  es. 1.5h a lezione) non corrisponde necessariamente al numero di file delle
  tue note (magari accorpi piu' lezioni in un unico file). Ogni esecuzione
  produce UN file di output, da QUALSIASI combinazione di file sorgente.

  Dopo la trascrizione, lo script aggancia da solo la lezione a master.tex
  (\input{lezioni/<nome>}), in coda alle lezioni gia' presenti, cosi' la
  dispensa si completa passo passo senza modificare master.tex a mano.

  USO:
    .\scripts\new_lecture.ps1 <NomeOutput> [-SoloRaster] `
        -Prof file1.pdf[,file2.pdf,...] `
        -Mine file1.pdf[,file2.pdf,...] `
        -Annotata copia_annotata.pdf -Vergine deckA.pdf[,deckB.pdf,...] `
        [-SenzaNote]

  Almeno uno tra -Prof, -Mine e -Annotata va fornito. I file di uno stesso
  parametro si separano con la virgola oppure con lo spazio. I percorsi
  possono essere assoluti o relativi alla root del progetto.

  -Annotata/-Vergine (modello M2 - slide-scheletro annotate, confini non
    rigidi): -Annotata vuole ESATTAMENTE un file (la copia annotata di questa
    lezione), -Vergine uno o piu' deck di slide pulite che la lezione
    attraversa. Se forniti entrambi (fuori da -SoloRaster), lo script chiama
    da se' scripts/align_slides.ps1 per costruire la mappa di coverage PRIMA
    di trascrivere: vanno quindi forniti insieme, tranne che in -SoloRaster
    (dove si vuole solo rasterizzare le vergini per il campione di
    /professor-profile).

  -SenzaNote: se non fornisci nessun file con -Mine, lo script si ferma e ti
    avvisa che mancano le tue note personali (di norma servono ad arricchire la
    trascrizione con quello che il prof dice a voce). Se vuoi comunque
    trascrivere solo dal materiale del professore, rilancia lo stesso comando
    aggiungendo -SenzaNote. Non si applica a -SoloRaster.

  -SoloRaster: rasterizza soltanto (nessuna trascrizione, nessuna
    compilazione) e si ferma. Serve a preparare le immagini di un campione di
    lezioni per la skill /professor-profile. Il campione va in un unico
    <NomeOutput> (es. "campione-profilo") con piu' file -Prof.

  ESEMPI:
    # Un file del prof, nessuna tua nota
    .\scripts\new_lecture.ps1 lezione01 -Prof "raw/prof/01_NomeArgomento.pdf"

    # Due file del prof + un tuo file che li copre entrambi
    .\scripts\new_lecture.ps1 lezione02-03 `
        -Prof "raw/prof/02_Arg.pdf","raw/prof/03_Arg.pdf" `
        -Mine "raw/mine/Lez 2-3 NomeCorso.pdf"

    # Solo rasterizzazione di 3 lezioni campione, per /professor-profile
    .\scripts\new_lecture.ps1 campione-profilo -SoloRaster `
        -Prof "raw/prof/01_Arg.pdf","raw/prof/02_Arg.pdf","raw/prof/03_Arg.pdf"

    # Lezione M2: copia annotata + i due deck di slide vergini che attraversa
    .\scripts\new_lecture.ps1 lezione05 `
        -Annotata "raw/prof/lez05_annotata.pdf" `
        -Vergine "raw/prof/deckA.pdf","raw/prof/deckB.pdf" `
        -Mine "raw/mine/mie-note-lez5.pdf"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$OutName,
    [string[]]$Prof,
    [string[]]$Mine,
    [string]$Annotata,
    [string[]]$Vergine,
    [switch]$SoloRaster,
    [switch]$SenzaNote
)

$ErrorActionPreference = 'Stop'

# root = cartella genitore di questo script (scripts/..)
$Root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $Root

if ((-not $Prof) -and (-not $Mine) -and (-not $Annotata)) {
    Write-Error "Fornisci almeno un file con -Prof, -Mine o -Annotata."
    exit 1
}

# Nessuna nota personale: ci si ferma una volta per avvisare. Non si chiede
# conferma da tastiera perche' lo script puo' girare senza terminale (es.
# lanciato da Claude Code): basta rilanciarlo con -SenzaNote per procedere.
if ((-not $SoloRaster) -and (-not $Mine) -and (-not $SenzaNote)) {
    Write-Host "ATTENZIONE: non hai fornito nessuna nota personale (-Mine)."
    Write-Host "Le note arricchiscono la trascrizione con cio' che il professore dice a voce."
    Write-Host "Carica le pagine delle tue note in raw/mine/ e rilancia con -Mine <file>."
    Write-Host "Se vuoi trascrivere comunque solo dal materiale del professore, rilancia"
    Write-Host "lo stesso comando aggiungendo -SenzaNote."
    exit 1
}

# M2: -Annotata e -Vergine vanno forniti insieme, perche' lo script chiama
# align_slides.ps1 prima di trascrivere. Eccezione: -SoloRaster, dove si vuole
# solo rasterizzare e nessun allineamento viene eseguito.
if (-not $SoloRaster) {
    if ($Annotata -and (-not $Vergine)) {
        Write-Error "-Annotata richiede almeno un -Vergine (modello M2)."
        exit 1
    }
    if ((-not $Annotata) -and $Vergine) {
        Write-Error "-Vergine richiede -Annotata (modello M2); per campionare solo le vergini usa -SoloRaster."
        exit 1
    }
}

if ($Annotata -and -not (Test-Path -LiteralPath $Annotata)) {
    Write-Error "File annotata non trovato: $Annotata"
    exit 1
}
foreach ($f in $Vergine) {
    if (-not (Test-Path -LiteralPath $f)) {
        Write-Error "File vergine non trovato: $f"
        exit 1
    }
}

if (-not (Get-Command pdftoppm -ErrorAction SilentlyContinue)) {
    Write-Error "pdftoppm non trovato. Installa MiKTeX (che lo include) e riprova."
    exit 1
}

$ImgDir = "raw/_images/$OutName"
$OutTex = "lezioni/$OutName.tex"
New-Item -ItemType Directory -Force -Path $ImgDir  | Out-Null
New-Item -ItemType Directory -Force -Path "lezioni" | Out-Null

# --- 1. Rasterizzazione ---
# 150 dpi: una pagina A4 resta sotto i ~2000px sul lato lungo, limite oltre il
# quale le richieste con molte immagini vengono rifiutate dal modello.
# Ogni file sorgente in un proprio sotto-prefisso, per non confondere le pagine
# tra file diversi.
function Invoke-Rasterize {
    param([string]$Prefix, [string[]]$Files)
    if (-not $Files) { return }
    $i = 1
    foreach ($f in $Files) {
        if (-not (Test-Path -LiteralPath $f)) {
            Write-Warning "file non trovato, salto: $f"
            continue
        }
        Write-Host "Rasterizzo ($Prefix #$i): $f ..."
        $outPrefix = Join-Path $ImgDir ("{0}{1}_" -f $Prefix, $i)
        & pdftoppm -png -r 150 $f $outPrefix
        if ($LASTEXITCODE -ne 0) { throw "pdftoppm ha fallito su: $f" }
        $i++
    }
}

Invoke-Rasterize -Prefix "prof" -Files $Prof
Invoke-Rasterize -Prefix "mine" -Files $Mine

# Copia annotata (M2): un solo file, prefisso "annotata_" (nessun indice, ce
# n'e' sempre una sola). Deck vergini: un prefisso "vergine<D>_" per deck, D a
# partire da 0 - stessa numerazione di deck usata da align_slides.ps1, cosi'
# le immagini rasterizzate qui e la mappa di coverage restano coerenti.
if ($Annotata) {
    Write-Host "Rasterizzo (annotata): $Annotata ..."
    $outPrefix = Join-Path $ImgDir "annotata_"
    & pdftoppm -png -r 150 $Annotata $outPrefix
    if ($LASTEXITCODE -ne 0) { throw "pdftoppm ha fallito su: $Annotata" }
}
if ($Vergine) {
    $d = 0
    foreach ($f in $Vergine) {
        Write-Host "Rasterizzo (vergine deck $d): $f ..."
        $outPrefix = Join-Path $ImgDir ("vergine{0}_" -f $d)
        & pdftoppm -png -r 150 $f $outPrefix
        if ($LASTEXITCODE -ne 0) { throw "pdftoppm ha fallito su: $f" }
        $d++
    }
}

# --- 1b. Modalita' sola rasterizzazione: ci si ferma qui ---
if ($SoloRaster) {
    Write-Host ""
    Write-Host "Sola rasterizzazione completata: immagini in $ImgDir."
    Write-Host "Nessuna trascrizione ne' compilazione eseguita."
    Write-Host ""
    Write-Host "Prossimo passo: deduci notazione e stile del professore con la skill"
    Write-Host "  /professor-profile"
    Write-Host "indicando di analizzare le lezioni campione in $ImgDir (prefisso prof... o vergine...)."
    exit 0
}

# --- 1c. Modello M2: mappa di coverage annotata<->vergine ---
# Costruita PRIMA del prompt di trascrizione, perche' lecture-transcribe la
# legge come input. La mappa opera sui PDF originali (pdftotext), non sulle
# immagini appena rasterizzate: l'ordine coi due passi sopra non conta.
$CoverageJson = $null
if ($Annotata) {
    Write-Host ""
    Write-Host "Costruisco la mappa di coverage annotata<->vergine (modello M2)..."
    & (Join-Path $PSScriptRoot "align_slides.ps1") $OutName '--annotata' $Annotata '--vergine' @Vergine
    if ($LASTEXITCODE -ne 0) { throw "align_slides.ps1 ha fallito." }
    $CoverageJson = "align/$OutName/coverage.json"
}

# --- 2. Costruzione del prompt per Claude Code ---
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("/lecture-transcribe")
$lines.Add("")
$lines.Add("Nome output: $OutName")
$lines.Add("")
$lines.Add("File del professore forniti per questo blocco (immagini in $ImgDir, prefisso prof1_, prof2_, ...):")
if (-not $Prof) { $lines.Add("(nessuno)") } else { foreach ($f in $Prof) { $lines.Add("- $f") } }
$lines.Add("")
$lines.Add("File di note personali forniti (immagini in $ImgDir, prefisso mine1_, mine2_, ...):")
if (-not $Mine) { $lines.Add("(nessuno)") } else { foreach ($f in $Mine) { $lines.Add("- $f") } }
$lines.Add("")
if ($Annotata) {
    $lines.Add("Materiale M2 (slide-scheletro annotate, confini non rigidi):")
    $lines.Add("- Copia annotata (immagini in $ImgDir, prefisso annotata_...): $Annotata")
    $lines.Add("- Slide vergini per deck (immagini in $ImgDir, prefisso vergine<D>_..., D=0,1,...):")
    $d = 0
    foreach ($f in $Vergine) { $lines.Add("  - deck ${d}: $f"); $d++ }
    $lines.Add("- Mappa di coverage: $CoverageJson (leggila con Read PRIMA di trascrivere; segui le istruzioni per il modello M2 nella skill lecture-transcribe).")
    $lines.Add("")
}
$lines.Add("IMPORTANTE: i file di note personali potrebbero coprire PIU' blocchi di lezione del professore (es. una tua nota unica per 2-3 file del prof).")
$lines.Add("Estrai dalle note personali SOLO il contenuto pertinente agli argomenti trattati nei file del professore forniti in questa esecuzione.")
$lines.Add("Se non e' chiaro dove finisce il contenuto pertinente e inizia quello di un altro blocco, inserisci un \revisione{...} invece di indovinare il confine.")
$lines.Add("")
$lines.Add("Segui le convenzioni in CLAUDE.md e preamble.tex.")
$lines.Add("Scrivi il risultato in $OutTex.")
$Prompt = $lines -join "`n"

# --- 3. Chiamata a Claude Code in modalita' headless ---
Write-Host "Genero la bozza LaTeX con Claude Code..."
& claude -p $Prompt --allowedTools "Read,Write,Edit,Glob" --permission-mode acceptEdits --output-format text

# --- 4. Inserimento automatico dell'\input in master.tex ---
# Cosi' la dispensa si completa passo passo: ogni lezione trascritta viene
# agganciata a master.tex senza intervento manuale. Idempotente (se la riga c'e'
# gia', non fa nulla). La nuova \input va DOPO l'ultima \input{lezioni/...} NON
# commentata (accumulo in ordine di aggiunta); se non ce n'e' ancora nessuna, va
# subito prima di \end{document} e lo si segnala, perche' potrebbe non trovarsi
# sotto un \chapter.
$inputLine = "\input{lezioni/$OutName}"
if (Test-Path "master.tex") {
    $righe = @(Get-Content -LiteralPath "master.tex")
    $rxInput = '^\s*\\input\{lezioni/'
    $rxQuesta = $rxInput + [regex]::Escape($OutName) + '\}'
    $rxEnd    = '^\s*\\end\{document\}'

    if ($righe | Where-Object { $_ -match $rxQuesta }) {
        Write-Host "master.tex include gia' ${inputLine}: nessuna modifica."
    }
    else {
        # indice dell'ultima \input{lezioni/...} non commentata (base 0)
        $lastIdx = -1
        for ($k = 0; $k -lt $righe.Count; $k++) { if ($righe[$k] -match $rxInput) { $lastIdx = $k } }

        if ($lastIdx -ge 0) {
            $at = $lastIdx; $hadPrior = $true
        }
        else {
            $endIdx = -1
            for ($k = 0; $k -lt $righe.Count; $k++) { if ($righe[$k] -match $rxEnd) { $endIdx = $k; break } }
            $at = if ($endIdx -ge 0) { $endIdx - 1 } else { $righe.Count - 1 }
            $hadPrior = $false
        }

        $nuovo = New-Object System.Collections.Generic.List[string]
        for ($k = 0; $k -lt $righe.Count; $k++) {
            $nuovo.Add($righe[$k])
            if ($k -eq $at) { $nuovo.Add($inputLine) }
        }
        # WriteAllLines: UTF-8 senza BOM, a capo nativi (niente BOM in testa a master.tex)
        [System.IO.File]::WriteAllLines([System.IO.Path]::GetFullPath("master.tex"), [string[]]$nuovo)

        if ($hadPrior) {
            Write-Host "Aggiunta $inputLine in master.tex (dopo l'ultima lezione)."
        }
        else {
            Write-Host "Aggiunta $inputLine in master.tex."
            Write-Host "ATTENZIONE: era la prima lezione inclusa - controlla che stia sotto il \chapter{} giusto."
        }
    }
}

# --- 5. Compilazione immediata (opzionale) ---
if ((Get-Command latexmk -ErrorAction SilentlyContinue) -and (Test-Path "master.tex")) {
    Write-Host "Compilo master.tex ..."
    & latexmk -pdf -interaction=nonstopmode master.tex | Out-Null
    Write-Host "Fatto. Apri master.pdf e guarda i bollini: rossi = da verificare (\revisione), blu = disegno da inserire (\figuramancante)."
}
else {
    Write-Host "Fatto. Frammento generato in $OutTex."
}
