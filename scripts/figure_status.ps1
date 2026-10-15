<#
  figure_status.ps1 - interroga i file .status delle figure in figure/fig/.

  Versione PowerShell (Windows) di scripts/figure_status.sh: stessa logica e
  stesso output. Testato su Windows PowerShell 5.1.

  Ogni figura ha un file gemello <chiave>.status con i campi:
    stato: mancante | generata | verificata
    data: YYYY-MM-DD
    fattibilita: facile | fattibile-da-verificare | non-conveniente
    lezione-origine: NN
    riferimento-prof: ...
    note: ...

  Significato degli stati:
    mancante   -> l'ancoraggio \figura{...} esiste nella lezione, ma il .tex
                  non e' ancora stato scritto: nel PDF compare il bollino blu
    generata   -> il .tex esiste ma non e' ancora stato controllato a vista
    verificata -> rendering controllato e confermato corretto

  USO:
    .\scripts\figure_status.ps1                     # figure NON ancora verificate
    .\scripts\figure_status.ps1 -Stato generata     # solo quelle da controllare
    .\scripts\figure_status.ps1 -Stato mancante     # solo quelle da disegnare
    .\scripts\figure_status.ps1 -Lezione 02         # tutte quelle della lezione 02
    .\scripts\figure_status.ps1 -Fattibilita facile # solo le facili
    .\scripts\figure_status.ps1 -All                # tutto, con riepilogo

  I filtri -Stato, -Lezione e -Fattibilita si possono combinare.
#>
[CmdletBinding()]
param(
    [string]$Stato,
    [string]$Lezione,
    [string]$Fattibilita,
    [switch]$All
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $Root

$FigDir = "figure/fig"
if (-not (Test-Path -LiteralPath $FigDir)) {
    Write-Error "Cartella $FigDir non trovata."
    exit 1
}

# Legge il valore di un campo da un file .status (prima occorrenza).
function Get-Campo {
    param([string]$File, [string]$Nome)
    $rx = '^' + [regex]::Escape($Nome) + ':\s*(.*)$'
    foreach ($line in Get-Content -LiteralPath $File) {
        $m = [regex]::Match($line, $rx)
        if ($m.Success) { return $m.Groups[1].Value.Trim() }
    }
    return ""
}

$trovate = 0
$conteggio = @{}

$statusFiles = Get-ChildItem -Path $FigDir -Recurse -Filter *.status -File | Sort-Object FullName

foreach ($sf in $statusFiles) {
    $categoria = Split-Path -Leaf (Split-Path -Parent $sf.FullName)
    $chiave = [System.IO.Path]::GetFileNameWithoutExtension($sf.Name)
    $statoFig = Get-Campo $sf.FullName "stato"
    $lez = Get-Campo $sf.FullName "lezione-origine"
    $fatt = Get-Campo $sf.FullName "fattibilita"

    if ([string]::IsNullOrEmpty($statoFig)) { $statoFig = "(campo stato assente)" }
    if ([string]::IsNullOrEmpty($fatt))  { $fatt = "?" }
    if ($conteggio.ContainsKey($statoFig)) { $conteggio[$statoFig]++ } else { $conteggio[$statoFig] = 1 }

    # --- filtri (NB: nomi di variabile distinti dai parametri: in PowerShell le
    #     variabili sono case-insensitive, $Stato e $stato sarebbero la stessa) ---
    if ($Stato       -and $statoFig -ne $Stato)       { continue }
    if ($Lezione     -and $lez      -ne $Lezione)     { continue }
    if ($Fattibilita -and $fatt     -ne $Fattibilita) { continue }
    # senza filtri espliciti e senza -All: mostra solo cio' che resta da fare
    if ((-not $All) -and (-not $Stato) -and (-not $Lezione) -and (-not $Fattibilita) -and ($statoFig -eq "verificata")) { continue }

    # Coerenza: il .tex esiste davvero?
    $texFile = [System.IO.Path]::ChangeExtension($sf.FullName, ".tex")
    $texEsiste = Test-Path -LiteralPath $texFile
    if ($texEsiste) { $presenza = "tex presente" } else { $presenza = "tex ASSENTE" }

    # Un .status che dice generata/verificata ma senza .tex e' un'incoerenza:
    # nel PDF comparirebbe il bollino blu nonostante lo stato dica il contrario.
    $incoerenza = ""
    if ((-not $texEsiste) -and ($statoFig -ne "mancante")) {
        $incoerenza = "   <-- INCOERENTE: stato '$statoFig' ma il .tex non esiste"
    }
    if ($texEsiste -and ($statoFig -eq "mancante")) {
        $incoerenza = "   <-- INCOERENTE: il .tex esiste ma lo stato dice 'mancante'"
    }

    "{0,-12} {1,-24} {2,-42} lez {3,-4} {4}" -f "[$statoFig]", $fatt, "$categoria/$chiave", $lez, $presenza
    if ($incoerenza) { $incoerenza }

    $trovate++
}

""
if ($trovate -eq 0) {
    "Nessuna figura corrisponde ai criteri."
}
else {
    "$trovate figure elencate."
}

if ($All) {
    ""
    "Riepilogo per stato:"
    foreach ($s in $conteggio.Keys) {
        "  {0,-12} {1}" -f $s, $conteggio[$s]
    }
}

# Ancoraggi \figura{} presenti nelle lezioni ma senza .status: sfuggirebbero a
# qualunque tracciamento, quindi vanno segnalati.
if (Test-Path -LiteralPath "lezioni") {
    $texFiles = Get-ChildItem -Path "lezioni" -Filter *.tex -File -ErrorAction SilentlyContinue
    if ($texFiles) {
        $chiaviAncora = Select-String -Path $texFiles.FullName -Pattern '\\figura\{([^}]*)\}' -AllMatches |
            ForEach-Object { $_.Matches } |
            ForEach-Object { $_.Groups[1].Value } |
            Sort-Object -Unique
        $mancanti = @()
        foreach ($k in $chiaviAncora) {
            $found = Get-ChildItem -Path $FigDir -Recurse -Filter "$k.status" -File -ErrorAction SilentlyContinue
            if (-not $found) { $mancanti += $k }
        }
        if ($mancanti.Count -gt 0) {
            ""
            "ATTENZIONE - ancoraggi \figura senza file .status:"
            foreach ($k in $mancanti) { "  $k" }
        }
    }
}
