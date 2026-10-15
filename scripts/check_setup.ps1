<#
  check_setup.ps1 - verifica che gli strumenti richiesti dal template siano
  installati e raggiungibili dal terminale (sul PATH), e per ognuno che manca
  dice cosa fare. Non modifica nulla: solo diagnostica.

  Versione PowerShell (Windows) di scripts/check_setup.sh: stessa logica e stesso
  output. Testato su Windows PowerShell 5.1.

  USO:
    .\scripts\check_setup.ps1

  Esce con codice 0 se c'e' tutto, 1 se manca almeno uno strumento essenziale.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

# Ogni voce: comando da cercare, a cosa serve, ed eventuale suggerimento se manca.
$strumenti = @(
    @{ Cmd = 'claude';   Serve = 'Claude Code (assistente che trascrive le lezioni)';
       Aiuto = 'installa con:  irm https://claude.ai/install.ps1 | iex   poi chiudi e riapri il terminale' }
    @{ Cmd = 'latexmk';  Serve = 'compila master.tex in PDF';
       Aiuto = 'installa MiKTeX da https://miktex.org/download , poi riavvia il PC per caricare il PATH' }
    @{ Cmd = 'pdftoppm'; Serve = 'converte i PDF del professore in immagini (rasterizzazione)';
       Aiuto = 'incluso in MiKTeX: se manca, riavvia il PC per caricare il PATH' }
    @{ Cmd = 'perl';     Serve = 'richiesto internamente da latexmk';
       Aiuto = 'di solito lo installa Git (Git Bash); altrimenti da https://www.perl.org/get.html' }
)

Write-Host ""
Write-Host "Verifica degli strumenti richiesti dal template:"
Write-Host ""

$mancanti = 0
foreach ($s in $strumenti) {
    $cmd = Get-Command $s.Cmd -ErrorAction SilentlyContinue
    if ($cmd) {
        $percorso = $cmd.Source
        if (-not $percorso) { $percorso = $cmd.Name }
        "{0,-10} OK   ({1})" -f $s.Cmd, $percorso
    }
    else {
        "{0,-10} MANCA - {1}" -f $s.Cmd, $s.Serve
        "           -> {0}" -f $s.Aiuto
        $mancanti++
    }
}

# --- Privacy: il materiale in raw/ non deve finire su un repo pubblico ---------
# Solo avvisi: non cambiano il codice di uscita (una materia privata puo' voler
# versionare i PDF di proposito), ma segnalano il rischio.
if (Get-Command git -ErrorAction SilentlyContinue) {
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Controllo privacy del materiale in raw/:"
        $avvisi = 0
        git check-ignore -q raw/prof/prova.pdf 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ATTENZIONE: git NON ignora i PDF in raw/prof/ (e/o raw/mine/): un 'git add .' li includerebbe."
            $avvisi++
        }
        $versionati = @(git ls-files raw 2>$null | Where-Object { $_ -notmatch '/\.gitkeep$' })
        if ($versionati.Count -gt 0) {
            Write-Host "ATTENZIONE: questi file di raw/ sono versionati (coperti da copyright / personali):"
            $versionati | ForEach-Object { Write-Host "  $_" }
            $avvisi++
        }
        if ($avvisi -eq 0) {
            Write-Host "OK   raw/ e' ignorato da git e nessun file del materiale e' versionato."
        }
        else {
            Write-Host "Non rendere MAI pubblico questo repo finche' ci sono PDF del professore o lezioni trascritte: vedi README."
        }
    }
}

Write-Host ""
if ($mancanti -eq 0) {
    Write-Host "Tutto a posto: puoi procedere con il flusso di lavoro (vedi README)."
    exit 0
}
else {
    Write-Host "$mancanti strumento/i da sistemare prima di procedere (vedi i suggerimenti sopra)."
    Write-Host "Dopo aver installato qualcosa, chiudi e riapri il terminale e rilancia questo script."
    exit 1
}
