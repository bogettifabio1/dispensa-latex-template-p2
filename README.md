# dispensa-latex-template

Template per trascrivere appunti universitari in LaTeX con l'aiuto di Claude
Code, a partire dal materiale del professore (PDF di slide/dispense) e dalle
note personali. Ogni lezione diventa un frammento `.tex` già strutturato, con
le parti incerte e i disegni mancanti marcati per la revisione invece che
riletti da capo.

Si copia questo scheletro per ogni corso. Due skill di bootstrap fanno il setup
al posto tuo: `/course-setup` deduce con una breve intervista **com'è
organizzato** il materiale del corso (slide complete? slide-scheletro annotate
a lezione? lavagna? solo tuoi appunti?) e istruisce di conseguenza gli script;
`/professor-profile` analizza un campione di 2–4 lezioni e deduce la
**notazione** del professore. Insieme compilano `CLAUDE.md` (il resto del file
contiene già le regole di sistema pronte). Poi si aggiungono le lezioni una
alla volta.

Questo repo è un **template repository** pubblico di GitHub: non contiene
materiale di nessun corso, solo lo scheletro. Per usarlo premi **Use this
template ▸ Create a new repository** (vedi «Scarica il progetto»): ottieni un
repo **tuo e indipendente**, senza la storia dei commit e senza legame con
l'originale (non è un fork, non ha un upstream). Crealo **privato**: è lì che
metterai la dispensa di una materia.

> **Progetto amatoriale e sperimentale.** Nato per trascrivere le dispense di un
> corso, è offerto così com'è, senza garanzie: può avere spigoli e ti chiediamo
> di dircelo (vedi «Feedback» in fondo).
>
> - **Testato su Windows.** Gli script per Mac (`.sh`) esistono ma **non sono
>   mai stati provati su un Mac**, e la guida d'installazione Mac non è
>   verificata: se li usi, il tuo riscontro è prezioso. Gli stessi `.sh`
>   valgono per Linux, ma non c'è una guida d'installazione dedicata.
> - **Cosa viene inviato ad Anthropic.** Per trascrivere, Claude Code legge le
>   immagini delle pagine dei tuoi PDF (slide del professore, tuoi appunti) e le
>   elabora sui server di Anthropic. Non usarlo su materiale che non puoi
>   condividere con un servizio esterno.
> - **Materiale e copyright.** I PDF in `raw/` restano solo sul tuo computer (git
>   li ignora). La dispensa che ottieni è una trascrizione di contenuti del
>   professore: se pubblichi il tuo repo, tienilo **privato** o assicurati di
>   poter condividere quel contenuto.

> ⚠️ **Non rendere mai pubblico il repo di una materia** (questo template, che è
> vuoto, sì; la tua copia con le lezioni no). Contiene (o conterrà)
> lezioni trascritte dal materiale del professore e il `CLAUDE.md` con il suo
> profilo: sono contenuti coperti da copyright, e una richiesta di rimozione
> arriverebbe a te. Non togliere `raw/` dal `.gitignore` e non usare
> `git add -f` sui PDF. In più, i commit riportano la tua email: per non
> esporla, su GitHub attiva «Keep my email addresses private» e usa l'indirizzo
> `…@users.noreply.github.com` come `git config --global user.email`.
> Per controllare lo stato in qualsiasi momento: `.\scripts\check_setup.ps1`
> (Windows) o `./scripts/check_setup.sh` (Mac): avvisa se `raw/` non è ignorato
> o se contiene file versionati.

---

# Installazione (Windows, da zero)

Presume che tu non abbia mai usato un terminale. Segui i passi in ordine.

> Guida per Windows 10/11. **Sei su Mac?** Salta alla sezione «Installazione
> (Mac, da zero)» qui sotto: stessi strumenti, comandi `.sh` al posto dei `.ps1`.

**Prima di cominciare serve:**
- Windows 10 (1809+) o Windows 11.
- Un **abbonamento a Claude a pagamento** (Pro, Max, Team o Enterprise). Il piano
  gratuito non basta: senza abbonamento a pagamento Claude Code non parte.
- Circa mezz'ora e un paio di GB liberi.

Installerai, in ordine: **VS Code** (l'editor), **Git** (per scaricare il
progetto), **Claude Code** (l'assistente), **MiKTeX** (compila il PDF e include
`pdftoppm`, che serve a convertire i PDF del professore in immagini — nessun
altro strumento da installare a parte).

## 1. VS Code

Scarica da <https://code.visualstudio.com> (pulsante blu), apri l'installer e
clicca Avanti fino alla fine lasciando le opzioni proposte. Poi apri **Visual
Studio Code** dal menu Start.

## 2. Git

Scarica da <https://git-scm.com/downloads/win>, apri l'installer e clicca Next
a ogni schermata lasciando le opzioni predefinite. Installa anche "Git Bash",
usato internamente da Claude Code.

## 3. Claude Code

1. Apri **PowerShell** (Start → scrivi `PowerShell`).
2. Incolla ed esegui:
   ```powershell
   irm https://claude.ai/install.ps1 | iex
   ```
3. Chiudi e riapri PowerShell, poi verifica:
   ```powershell
   claude --version
   ```
   Deve stampare un numero di versione. Se dice "comando non riconosciuto",
   chiudi e riapri di nuovo il terminale.
4. Primo avvio: scrivi `claude`, fai login nel browser con l'account **con
   l'abbonamento a pagamento**. Per uscire: `/exit`.

## 4. MiKTeX

1. Scarica il MiKTeX Installer da <https://miktex.org/download>.
2. Durante l'installazione scegli **"Install MiKTeX only for me"** e, alla
   domanda "Install missing packages on the fly", scegli **"Yes"** (MiKTeX
   scaricherà da solo i pacchetti mancanti alla prima compilazione).
3. Apri **MiKTeX Console** e, se proposto, fai **Check for updates → Update now**.
4. Chiudi e riapri PowerShell, poi verifica:
   ```powershell
   latexmk --version
   pdftoppm -v
   ```
   Se non vengono riconosciuti, riavvia il PC (serve a caricare il PATH) e riprova.

## 5. Scarica il progetto

Consigliato: crea **la tua copia** del template, così hai un posto tuo dove
salvare la dispensa.

1. Con un account GitHub, apri
   <https://github.com/bogettifabio1/dispensa-latex-template-p2> e premi
   **Use this template ▸ Create a new repository**. Scegli **Private**: la tua
   dispensa contiene contenuti del professore.
2. Clona **la tua** copia (sostituisci `TUO-UTENTE/NOME-REPO`):

```powershell
cd $HOME\Desktop
git clone https://github.com/TUO-UTENTE/NOME-REPO.git
```

In alternativa puoi clonare direttamente il repo originale
(`git clone https://github.com/bogettifabio1/dispensa-latex-template-p2.git`) o,
senza account GitHub e senza Git, usare **Code ▸ Download ZIP** sulla pagina del
template. Funziona uguale, ma non avrai un salvataggio online della tua dispensa
e, per ricevere i miglioramenti futuri, dovrai chiedere a Claude Code di
riportarli a mano (vedi «Consigli»).

## 6. Apri il progetto e sblocca gli script

1. In VS Code: **File ▸ Apri cartella…** e scegli la cartella scaricata.
2. Apri un terminale **PowerShell** dentro VS Code (**Terminale ▸ Nuovo terminale**).
3. Una volta sola, sblocca l'esecuzione degli script del progetto (Windows li
   blocca di default):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
   Conferma con `S`/`Y`. Questo abilita gli script scaricati da te, senza
   abbassare la sicurezza per quelli presi da internet.

---

# Installazione (Mac, da zero)

Presume che tu non abbia mai usato il Terminale. Segui i passi in ordine.

> Guida per macOS (Big Sur 11 o più recente), sia Intel sia Apple Silicon.

**Prima di cominciare serve:**
- Un **abbonamento a Claude a pagamento** (Pro, Max, Team o Enterprise). Il piano
  gratuito non basta: senza abbonamento a pagamento Claude Code non parte.
- Circa mezz'ora e qualche GB libero.

Su Mac gli strumenti si installano quasi tutti con **Homebrew**, il gestore di
pacchetti da riga di comando. Installerai, in ordine: **Homebrew**, **VS Code**
(l'editor), **Git**, **Claude Code** (l'assistente), **MacTeX** (compila il PDF)
e **Poppler** (fornisce `pdftoppm`, che converte i PDF del professore in
immagini — su Mac non è incluso in MacTeX, va installato a parte).

## 1. Terminale e Homebrew

1. Apri il **Terminale** (⌘+Spazio, scrivi `Terminale`, Invio).
2. Installa Homebrew incollando:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   A fine installazione può chiederti di eseguire due righe `echo … >> ~/.zprofile`
   per aggiungere `brew` al PATH: eseguile come indicato. Verifica con:
   ```bash
   brew --version
   ```

## 2. VS Code e Git

```bash
brew install --cask visual-studio-code
brew install git
```

## 3. Claude Code

1. Installa:
   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```
2. Chiudi e riapri il Terminale, poi verifica:
   ```bash
   claude --version
   ```
   Se dice "command not found", chiudi e riapri di nuovo il Terminale.
3. Primo avvio: scrivi `claude`, fai login nel browser con l'account **con
   l'abbonamento a pagamento**. Per uscire: `/exit`.

## 4. MacTeX e Poppler

```bash
brew install --cask mactex-no-gui
brew install poppler
```

`mactex-no-gui` è grande (qualche GB): la prima installazione richiede pazienza.
Chiudi e riapri il Terminale, poi verifica:
```bash
latexmk --version
pdftoppm -v
```
Se non vengono riconosciuti, chiudi e riapri il Terminale (ricarica il PATH) e
riprova.

## 5. Scarica il progetto

Consigliato: crea **la tua copia** del template, così hai un posto tuo dove
salvare la dispensa.

1. Con un account GitHub, apri
   <https://github.com/bogettifabio1/dispensa-latex-template-p2> e premi
   **Use this template ▸ Create a new repository**. Scegli **Private**: la tua
   dispensa contiene contenuti del professore.
2. Clona **la tua** copia (sostituisci `TUO-UTENTE/NOME-REPO`):

```bash
cd ~/Desktop
git clone https://github.com/TUO-UTENTE/NOME-REPO.git
```

In alternativa puoi clonare direttamente il repo originale
(`git clone https://github.com/bogettifabio1/dispensa-latex-template-p2.git`) o,
senza account GitHub e senza Git, usare **Code ▸ Download ZIP** sulla pagina del
template. Funziona uguale, ma non avrai un salvataggio online della tua dispensa
e, per ricevere i miglioramenti futuri, dovrai chiedere a Claude Code di
riportarli a mano (vedi «Consigli»).

## 6. Apri il progetto e rendi eseguibili gli script

1. In VS Code: **File ▸ Apri…** e scegli la cartella scaricata.
2. Apri un terminale dentro VS Code (**Terminale ▸ Nuovo terminale**).
3. Una volta sola, rendi eseguibili gli script del progetto:
   ```bash
   chmod +x scripts/*.sh
   ```

---

# Verifica dell'installazione

Prima di cominciare, controlla in un colpo solo che tutto sia a posto. Lo script
non modifica nulla: per ogni strumento dice **OK** oppure **cosa manca e come
installarlo**.

```powershell
.\scripts\check_setup.ps1
```

Su Mac:

```bash
./scripts/check_setup.sh
```

Se elenca qualcosa come mancante, segui il suggerimento accanto, chiudi e riapri
il terminale, e rilancia lo script finché non è tutto **OK**. Così eviti di
scoprire un pezzo mancante a metà della prima lezione.

---

# Flusso di lavoro

> 💡 Non devi memorizzare né copiare a mano i comandi qui sotto: puoi anche
> aprire `claude` e descrivere cosa vuoi in linguaggio naturale, es. "inizia
> l'analisi della sintassi del professore eseguendo il comando giusto" o
> "trascrivi la lezione 1 dal PDF in raw/prof/lezione1.pdf". Claude Code legge
> questo README e gli script in `scripts/`, capisce da solo quale comando
> lanciare e con quali argomenti, e lo esegue lui nel terminale integrato.

> 🪟 / 🍎 **Windows o Mac?** I comandi sotto sono mostrati per Windows
> (`.\scripts\…​.ps1`). Su Mac usa l'equivalente `.sh` (`./scripts/…​.sh`) con le
> opzioni in stile Unix (`--prof`, `--mine`, `--annotata`, `--vergine`,
> `--senza-note`, `--solo-raster`) e i file separati da **spazi** invece che da
> virgole. Dove cambia qualcosa trovi sotto entrambe
> le forme. (Oppure, come sopra, lascia scegliere a Claude Code.)

## 1. PDF al loro posto

Copia i PDF del professore in `raw/prof/`, le tue note scannerizzate (se ci
sono) in `raw/mine/`. Git li ignora: restano solo sul tuo computer.

## 2. Modello del materiale (una volta per corso)

Prima di trascrivere qualunque lezione, fai capire a Claude Code **com'è
fatto** il materiale di questo corso. Apri `claude` e lancia:

```
/course-setup
```

È un'intervista breve e adattiva (salta da sola le domande non pertinenti al
tuo caso) e scrive il risultato — solo dopo tua conferma — nella sezione
"Modello del materiale" di `CLAUDE.md`. Le risposte ricadono di norma in uno
di questi 4 modelli, che decidono anche **quali flag** usare al passo 4:

| Modello | Materiale del prof | Flag da usare |
|---|---|---|
| **M1** — slide complete | PDF autosufficienti, poco/nessun annotato | `--prof` + `--mine` (senza note: `--senza-note`) |
| **M2** — slide-scheletro annotate | Slide lunghe completate a lezione, una lezione può attraversare più set | `--annotata` + `--vergine` (+ `--mine`) |
| **M3** — lavagna / manoscritto | Niente slide, tutto scritto a mano e fotografato/scansionato | `--prof` (immagini lette a vista) + `--mine` |
| **M4** — soli appunti | Il prof non distribuisce nulla | solo `--mine`, che diventa la fonte di verità |

Si rifà solo se cambia corso o professore, non a ogni lezione. Se lo salti, la
pipeline ricade sul default M1 (`--prof`/`--mine`).

## 3. Profilo del professore (una volta per corso)

Trasforma 2–4 lezioni campione in immagini, sotto un unico nome:

```powershell
.\scripts\new_lecture.ps1 campione-profilo -SoloRaster `
    -Prof "raw/prof/lezione1.pdf","raw/prof/lezione2.pdf","raw/prof/lezione3.pdf"
```

Su Mac:

```bash
./scripts/new_lecture.sh campione-profilo --solo-raster \
    --prof "raw/prof/lezione1.pdf" "raw/prof/lezione2.pdf" "raw/prof/lezione3.pdf"
```

Poi apri `claude` e incolla questo prompt (adattando il nome del corso):

```
/professor-profile

Campione da analizzare: tutte le immagini in raw/_images/campione-profilo/
(prefisso prof1_, prof2_, ...). Corso: <nome del corso>.
```

Claude analizza le immagini, mostra una tabella di ciò che ha capito e
**aspetta conferma** prima di scrivere in `CLAUDE.md`. Da qui in poi trascrive
con le convenzioni del tuo professore.

> Nel modello **M2** campiona le slide **vergini** (usa `-Vergine`/`--vergine`
> al posto di `-Prof`/`--prof` nel comando sopra), non la copia annotata: è lì
> che la notazione tipografica è netta. Nel modello **M4** (soli appunti) non
> c'è materiale del prof da profilare: la skill se ne accorge da sola, te lo
> spiega e si ferma — salta pure a questo punto.

## 4. Trascrivere una lezione

Il comando dipende dal modello individuato al passo 2.

**M1 / M3** (slide complete o lavagna — il prof è la fonte di verità), con le
tue note che coprono la stessa lezione:

```powershell
.\scripts\new_lecture.ps1 lezione01 -Prof "raw/prof/lezione1.pdf" -Mine "raw/mine/mie-note-lez1.pdf"
```

Su Mac:

```bash
./scripts/new_lecture.sh lezione01 --prof "raw/prof/lezione1.pdf" --mine "raw/mine/mie-note-lez1.pdf"
```

**Senza note personali** (vale per M1, M2 e M3). Se non passi nessun
`-Mine`/`--mine`, lo script si ferma e ti avvisa che mancano le tue note (di
norma arricchiscono la trascrizione con quello che il prof dice a voce). Se vuoi
trascrivere lo stesso solo dal materiale del professore, rilancia lo stesso
comando aggiungendo `-SenzaNote` (Windows) o `--senza-note` (Mac):

```powershell
.\scripts\new_lecture.ps1 lezione01 -Prof "raw/prof/lezione1.pdf" -SenzaNote
```

```bash
./scripts/new_lecture.sh lezione01 --prof "raw/prof/lezione1.pdf" --senza-note
```

Se lo lanci tramite Claude Code, ti riporta lui l'avviso.

**M2** (slide-scheletro annotate — richiede `-Annotata`/`--annotata` **e**
`-Vergine`/`--vergine` insieme, con i deck vergini nell'ordine in cui la
lezione li attraversa):

```powershell
.\scripts\new_lecture.ps1 lezione05 `
    -Annotata "raw/prof/lez05_annotata.pdf" `
    -Vergine "raw/prof/deckA.pdf","raw/prof/deckB.pdf" `
    -Mine "raw/mine/mie-note-lez5.pdf"
```

```bash
./scripts/new_lecture.sh lezione05 \
    --annotata "raw/prof/lez05_annotata.pdf" \
    --vergine "raw/prof/deckA.pdf" "raw/prof/deckB.pdf" \
    --mine "raw/mine/mie-note-lez5.pdf"
```

Prima di trascrivere, lo script costruisce da sé la mappa di coverage
annotata↔vergine (`align/lezione05/coverage.json`, vedi
`scripts/align_slides.sh`): **rivedila** — in particolare le pagine "inserite"
a mano e quelle a confidenza bassa — prima di fidarti del risultato.

**M4** (soli appunti — nessun materiale del prof, solo `-Mine`/`--mine`):

```powershell
.\scripts\new_lecture.ps1 lezione01 -Mine "raw/mine/mie-note-lez1.pdf"
```

```bash
./scripts/new_lecture.sh lezione01 --mine "raw/mine/mie-note-lez1.pdf"
```

Qui le tue note sono l'unica fonte e vengono trattate come tali: nessun
confronto con un materiale del prof che non esiste.

In tutti i casi lo script rasterizza (e, solo per M2, allinea), chiama Claude
per la trascrizione e (se la lezione è già inclusa in `master.tex`) compila il
PDF.

## 5. Inserire la lezione e compilare

Questo passo è **automatico**: `new_lecture` aggancia da sé la lezione appena
trascritta a `master.tex` (aggiunge `\input{lezioni/lezione01}` in coda alle
lezioni già presenti) e poi compila, generando `master.pdf` — apribile in VS Code.

Due sole eccezioni da tenere a mente:

- **La primissima lezione del corso**: non essendoci ancora nessuna lezione, lo
  script la inserisce ma ti avvisa di controllare che finisca **sotto il
  `\chapter{}` giusto** (l'organizzazione in capitoli la decidi tu in
  `master.tex`, vedi i commenti lì).
- **Ricompilare a mano**, quando serve (es. dopo aver corretto un bollino):

  ```powershell
  latexmk master.tex
  ```

## 6. Leggere i bollini e correggere

- 🔴 **rosso** (`\revisione`): Claude non era sicuro di una formula o un
  passaggio. Controlla il materiale originale e correggi il `.tex`.
- 🔵 **blu** (`\figura`): un disegno del professore da inserire a mano — vedi
  `.claude/docs/gestione-figure.md`.

I bollini rossi non sono errori da nascondere: sono avvisi onesti. Meglio un
bollino in più che una formula sbagliata mimetizzata nel testo.

---

# Consigli

- Materiale leggibile in ingresso = meno bollini rossi in uscita.
- Fai prima `/course-setup`, poi il profilo, poi le lezioni: saltarli fa
  trascrivere con i flag sbagliati o con notazione "a caso", e si perde più
  tempo dopo a correggere.
- Una lezione alla volta: controlla e correggi i bollini prima di passare alla
  successiva.
- Non sistemare l'impaginazione durante la scrittura: solo a dispensa completa
  (vedi `CLAUDE.md`).
- Il template può ricevere migliorie: ogni tanto guarda la pagina GitHub del
  progetto. Poiché la tua copia nasce da «Use this template», non è collegata
  all'originale: aggiornarla **non è automatico** (hai modificato
  `CLAUDE.md`, `master.tex`, `lezioni/`): se c'è una novità che ti serve,
  chiedi a Claude Code di riportarla nella tua copia senza toccare il tuo
  materiale.

---

# Problemi comuni

| Sintomo | Cosa fare |
|---|---|
| `claude` "non riconosciuto" | Chiudi e riapri il terminale; se persiste, riavvia il PC. |
| `perl` "non riconosciuto per eseguire latexmk" | installa perl da `https://www.perl.org/get.html` |
| `latexmk`/`pdftoppm` "non riconosciuto" (Windows) | Riavvia il PC (carica il PATH di MiKTeX) e riprova. |
| `pdftoppm: command not found` (Mac) | Manca Poppler: `brew install poppler`, poi riapri il Terminale. |
| Lo script `.ps1` viene bloccato (Windows) | Manca il passo 6.3 (`Set-ExecutionPolicy … RemoteSigned`). |
| `./scripts/…​.sh: Permission denied` (Mac) | Manca il passo 6.3: `chmod +x scripts/*.sh`. |
| Claude Code chiede login e non parte | Serve un abbonamento a pagamento; il piano gratuito non basta. |
| La prima compilazione si blocca o chiede pacchetti | MiKTeX sta scaricando i pacchetti mancanti: accetta e aspetta. |
| Il bollino blu resta anche dopo aver creato la figura | Ricompila con `latexmk -g -pdf master.tex` (una volta per figura nuova). |

Per sapere in un colpo solo cosa manca fra gli strumenti del template:
`.\scripts\check_setup.ps1` (Windows) o `./scripts/check_setup.sh` (Mac). Per un
controllo dedicato a Claude Code: `claude doctor`.

---

# Struttura del progetto

- `master.tex` — file principale: titolo, indici, elenco delle lezioni.
- `preamble.tex` — pacchetti, notazioni, ambienti (di norma non si tocca).
- `CLAUDE.md` — convenzioni del corso, lette in automatico da Claude Code.
- `lezioni/` — un file `.tex` per lezione.
- `figure/fig/` — i disegni, divisi per categoria.
- `raw/prof/`, `raw/mine/` — i tuoi PDF sorgenti (restano solo sul tuo computer, non versionati).
- `align/` — solo modello M2: mappe di coverage annotata↔vergine generate da
  `align_slides.{sh,ps1}` (ignorata da git, si rigenera a ogni lezione M2).
- `scripts/` — `.ps1` per Windows, `.sh` per Mac/Linux.
- `.claude/skills/`, `.claude/docs/` — le skill (`/course-setup`,
  `/professor-profile`, `/lecture-transcribe`, `/figure-classify`) e la
  documentazione interna.

---

# Feedback

Il progetto è giovane e ogni riscontro serve, anche piccolo. Raccontalo
direttamente a chi ti ha passato il progetto, in chat o a voce: non serve
scrivere niente di formale.

Cosa ci interessa di più:

- Sei riuscito a installare tutto seguendo solo il README? Dove ti sei fermato?
- Quanto tempo ti è servito dal download alla prima lezione trascritta?
- Quanti bollini rossi (`\revisione`) hai trovato in una lezione, e quanti
  erano davvero errori?
- Che tipo di materiale ha il tuo corso (slide, lavagna, solo appunti)? Il
  modello M1–M4 che `/course-setup` ha scelto ti è sembrato giusto?
- Cosa ti ha confuso, cosa toglieresti, cosa ti aspettavi e non c'era?
