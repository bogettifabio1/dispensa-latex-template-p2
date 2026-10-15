# Convenzioni del corso

Questo file viene letto automaticamente da Claude Code a ogni task del progetto.
È la fonte di verità delle convenzioni: se una regola vale anche per le lezioni
future, va scritta qui e non solo detta in chat.

Contiene tre tipi di regole, su assi diversi:

- il **"Modello del materiale"** qui sotto — *com'è organizzato il materiale del
  corso*: quali sorgenti esistono (slide, lavagna, tuoi appunti…), come sono fatte
  e come si relazionano — è **generato automaticamente** da `/course-setup` con una
  breve intervista, ed è il **primo passo dopo aver clonato il template**. Decide la
  *forma della pipeline*: quali categorie di sorgente esistono e come vanno trattate.
  Si rifà solo se cambia il corso o il professore, non a ogni lezione.
- la **sezione "Profilo del professore"** — *notazione e stile* specifici del
  corso — è **generata automaticamente** da `/professor-profile` a partire da un
  campione di lezioni, e va rigenerata (o corretta a mano) quando emergono
  convenzioni nuove. Decide la *fedeltà della trascrizione*.
- tutto il resto sono **regole di sistema invarianti** (ambienti, marker, figure,
  indici, impaginazione, struttura): valgono per ogni corso e di norma non si
  toccano.

I due blocchi generati rispondono a domande ortogonali: il modello del materiale
dice *quali file esistono e come sono fatti*; il profilo dice *con che notazione
trascriverli*. Ognuno vive tra i propri marker `<!-- BEGIN … -->` /
`<!-- END … -->`: le skill scrivono **solo** lì dentro, il resto del file resta
intatto.

## Modello del materiale

<!-- BEGIN MODELLO-MATERIALE -->
> _Modello non ancora generato._ Esegui `/course-setup` **subito dopo aver clonato
> il template**: una breve intervista adattiva deduce com'è organizzato il materiale
> del corso e popola questo blocco. Finché è vuoto, la pipeline ricade sul modello
> di default `prof` + `mine` (PDF del professore come fonte di verità, tuoi appunti
> come arricchimento) — vedi `lecture-transcribe`.
>
> Dimensioni che verranno popolate:
> - Materiale del professore (slide complete / slide-scheletro poi annotate /
>   lavagna / manoscritto / nessuno)
> - Forma dei file (PDF digitale con text layer / scansione o foto)
> - Annotazioni (presenti? di chi? a penna o native digitali? il colore ha
>   un significato?)
> - Materiale vergine separato dall'annotato (sì / no)
> - Confini di lezione (coincidono coi file / una lezione attraversa più set →
>   serve l'allineamento)
> - Tuoi appunti (presenti? in che forma?)
> - Riferimenti esterni (libro/dispensa) e lingua del corso
> - Categorie di sorgente attive e flag corrispondenti per `new_lecture.sh`
<!-- END MODELLO-MATERIALE -->

## Profilo del professore

<!-- BEGIN PROFILO-PROFESSORE -->
> _Profilo non ancora generato._ Esegui `/professor-profile` su un campione di
> 2–4 lezioni del professore (immagini in `raw/_images/<nome>/`) per popolarlo.
> Finché è vuoto, `lecture-transcribe` ricade sui default generali di `preamble.tex`.
>
> Dimensioni che verranno popolate:
> - Notazione insiemistica
> - Funzioni e corrispondenze
> - Relazioni di equivalenza e ordine
> - Insiemi numerici e simboli ricorrenti
> - Notazioni specifiche dell'argomento
> - Ambienti ed enunciati (e come il prof segnala gli esercizi lasciati allo studente)
> - Livello di dettaglio delle dimostrazioni
> - Lingua e stile
<!-- END PROFILO-PROFESSORE -->

## Ambienti (sintassi tcbtheorem, NON amsthm classico)

Disponibili in `preamble.tex`: `theorem`, `property`, `definition`, `lemma`.
Sintassi:
```latex
\begin{theorem}{Titolo breve (o vuoto)}{chiave-label}
  Enunciato...
\end{theorem}
```
La chiave diventa il label con prefisso automatico dell'ambiente:
`theorem`→`th:`, `property`→`pr:`, `definition`→`def:`, `lemma`→`lem:`. NON
aggiungere tu il prefisso nella chiave. Riferimenti con `\ref{th:chiave}` (niente
`\cref`, non caricato). Formato chiave: `nome-breve-in-inglese` (es.
`bolzano-weierstrass` → label `th:bolzano-weierstrass`).

Dimostrazioni: `\begin{proof}...\end{proof}` (amsthm standard), **fuori** dal box.

## Esempi ed esercizi — NIENTE box tcbtheorem

Esempi ed esercizi non vanno mai in un ambiente `tcbtheorem` (niente box
colorato). Solo testo con etichetta in grassetto:

```latex
\textbf{Esercizio.} Enunciato...

\textbf{Svolgimento.} Soluzione...
```
`\textbf{Esempio.} ...` per gli esempi. Se un esercizio è una dimostrazione
lasciata allo studente (non svolta), NON dimostrarla e chiudi con
`\textit{Dimostrazione lasciata da svolgere.}`.

## Marker di revisione e figure

Fonte di verità: non usare `\todo` grezzo. Definiti in `preamble.tex`:

- `\revisione{...}` — marker **rosso**, per contenuto di cui non si è sicuri della
  trascrizione (formula, passaggio, leggibilità). Meglio troppi marker che un
  errore matematico nascosto.
- `\figura{chiave}{descrizione}` — ancoraggio di un disegno **del professore** nel
  punto esatto in cui comparirebbe. Se `figure/fig/<categoria>/chiave.tex` esiste
  la figura viene inclusa, altrimenti compare il marker **blu** di figura mancante.
  I file in `lezioni/` contengono **solo** l'ancoraggio, mai il corpo della figura.
  Dettagli completi (stati `.status`, categorie, fattibilità TikZ, `latexmk -g`)
  in `.claude/docs/gestione-figure.md`.

## Struttura in capitoli e sezioni + doppio indice

- `\chapter` = **macroargomento** del corso (stanno in `master.tex`); `\section` =
  **lezione**. I frammenti in `lezioni/` iniziano con `\section`, mai `\chapter`.
- Se una lezione copre due macroargomenti, va **spezzata** in due file sotto i due
  `\chapter` giusti, ma con il marker `\lezione{...}` una volta sola.
- Oltre al `\tableofcontents` c'è un secondo indice "Indice delle lezioni":
  ogni lezione si apre con `\lezione{numero}{titolo}` **subito prima** del
  `\section` (numero = quello del professore; titolo facoltativo). L'indice si
  popola da solo alla compilazione (file `.loz`).

## Controllo finale di impaginazione (solo a dispensa completa)

Durante la scrittura l'impaginazione si **ignora**: niente `\Needspace*`,
`\newpage`, `\clearpage`. Ogni lezione aggiunta o figura inserita sposta le
interruzioni di pagina, quindi correggere prima è lavoro buttato. Solo a
capitolo/dispensa completa si fa la passata correttiva sui titoli isolati a fine
pagina, mettendo `\Needspace*{4\baselineskip}` subito prima del titolo, una
occorrenza alla volta ricompilando da quel punto in avanti.

## Struttura del progetto

- `master.tex` — `\documentclass`, `\input{preamble}`, titolo, i due indici, e la
  lista di `\input{lezioni/...}` organizzata in `\chapter`, con i capitoli futuri
  commentati come scaletta.
- `preamble.tex` — pacchetti, macro, ambienti, i marker e il meccanismo `\figura`.
- `lezioni/lezioneNN.tex` — un frammento per lezione, senza preambolo, che inizia
  con `\section`. Solo ancoraggi `\figura`, mai il corpo di una figura.
- `figure/fig/<categoria>/` — corpo delle figure (`.tex`) e stato (`.status`).
- `raw/prof/`, `raw/mine/` — PDF sorgenti (archivio, non modificare).
  `raw/_images/` contiene le pagine rasterizzate, rigenerate da `new_lecture.sh`.

## Compilazione

Si compila `master.tex` (non i singoli file di `lezioni/`):
```
latexmk -pdf master.tex
```
Dopo aver creato un file figura **nuovo** serve `latexmk -g` almeno una volta
(vedi `.claude/docs/gestione-figure.md`).
