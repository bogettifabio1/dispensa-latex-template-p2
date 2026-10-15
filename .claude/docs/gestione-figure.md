# Gestione delle figure

Infrastruttura generica per gestire i disegni/schemi del professore in una
dispensa LaTeX: come si ancorano nel testo, dove vive il loro corpo, come si
tiene traccia del loro stato e come si decide se conviene riprodurli in TikZ.

**Principio: i file in `lezioni/` contengono solo l'ancoraggio, mai il corpo
della figura.** Aggiungere un disegno significa creare un file in
`figure/fig/`, senza toccare la lezione; cancellare quel file riporta da solo
al bollino blu. Così ri-trascrivere una lezione non distrugge le figure, e
produrre figure non può corrompere il testo.

L'ancoraggio nel testo è `\figura{<chiave>}{<descrizione>}` (definito in
`preamble.tex`): se `figure/fig/<categoria>/<chiave>.tex` esiste la figura
viene inclusa e centrata, altrimenti compare il marker **blu** di figura
mancante con la descrizione.

## Struttura

```
figure/fig/<categoria>/<chiave>.tex      il corpo della figura
figure/fig/<categoria>/<chiave>.status   il suo stato + tracciabilità
```

Le categorie sono per **tipo strutturale** della figura, **mai** per lezione di
provenienza (la lezione d'origine sta nel `.status`). L'elenco delle categorie
disponibili è definito in `\figuracategorie` in `preamble.tex`: se serve una
categoria nuova si aggiunge la cartella **e** una riga `#1{...}` in quella
macro.

Il `.tex` contiene **solo** il `tikzpicture` (o un `\includegraphics`): niente
`\begin{center}`, niente ambiente `figure` — al centraggio pensa `\figura`.

## Chiavi

`<chiave>` è un identificatore stabile assegnato alla creazione. **Non deve mai
derivare dalla descrizione testuale**, che cambia a ogni ri-trascrizione: se
l'ancoraggio dipendesse dal testo, riformulare una descrizione scollegherebbe
la figura in silenzio.

## File `.status`

```
stato: mancante | generata | verificata
fattibilita: facile | fattibile-da-verificare | non-conveniente
data: YYYY-MM-DD
lezione-origine: NN
riferimento-prof: (es. "pagina 4, in alto a destra")
note: (opzionale)
```

- `mancante` — l'ancoraggio esiste ma il `.tex` no: nel PDF c'è il bollino blu.
- `generata` — il `.tex` esiste ma **non è ancora stato controllato a vista**.
- `verificata` — rendering controllato e confermato corretto.

`lezione-origine` e `riferimento-prof` servono solo alla tracciabilità verso il
materiale del professore: non influenzano dove il file sta né come viene
trovato. `\figura` **non legge il `.status`**: decide solo in base
all'esistenza del `.tex`.

Perché la distinzione `generata`/`verificata` conta: un TikZ che compila non è
un TikZ corretto. Una figura sbagliata è peggio di un bollino blu, perché il
bollino è onesto sul fatto che manca qualcosa. Nessuna figura passa a
`verificata` senza che il rendering sia stato guardato.

## Interrogare lo stato

```
./scripts/figure_status.sh                       # tutto ciò che non è verificato
./scripts/figure_status.sh --stato mancante      # da disegnare
./scripts/figure_status.sh --stato generata      # da controllare a vista
./scripts/figure_status.sh --lezione 02          # per lezione d'origine
./scripts/figure_status.sh --fattibilita facile  # il lotto più conveniente
./scripts/figure_status.sh --all                 # tutto, con riepilogo
```

> Su **Windows** usa lo script PowerShell equivalente, con le stesse opzioni ma
> in stile nativo: `.\scripts\figure_status.ps1 -Stato mancante -Fattibilita facile`,
> `.\scripts\figure_status.ps1 -All`, ecc.

I filtri si combinano: `--stato mancante --fattibilita facile` dà esattamente
le figure che conviene affrontare nel prossimo lotto.

Lo script segnala anche le incoerenze: `.status` che dichiara `generata` ma
senza `.tex`, e ancoraggi `\figura` presenti nelle lezioni senza `.status`.

## Classificare la fattibilità in TikZ

Prima di scrivere codice, ogni figura mancante va classificata in una di tre
categorie. Servono a decidere **dove conviene spendere tempo**, non a stabilire
se la figura sarà corretta: quello è un problema separato, e vale per tutte e
tre (vedi `generata` vs `verificata` sopra).

Si applicano i test **in ordine**; il primo che risponde "sì" decide.

1. **Il disegno è pittorico o metaforico?** Rappresenta oggetti del mondo reale
   (una figura deformata, un oggetto fisico, uno schizzo realistico) invece di
   enti matematici esatti? → **non conveniente**.
2. **Esiste già un raster utilizzabile** dal materiale del professore, e la
   figura non è banale? → **non conveniente**: si ritaglia l'immagine e la si
   aggancia con un wrapper `\includegraphics`.
3. **È un dettaglio marginale** (schizzo a margine, ripetizione di una figura
   già presente, disegno che non aggiunge nulla al testo)? → **non conveniente**:
   meglio nessuna figura che una figura inutile che spezza la pagina.
4. **Il significato dipende da regioni campite, ritagli, o da più di ~6 elementi
   etichettati?** → **fattibile ma da verificare**. Si può fare, ma è dove si
   sbaglia: una campitura giusta e una sbagliata compilano entrambe.
5. Altrimenti → **facile**: primitive geometriche esatte (cerchi, rette, archi,
   assi, curve con equazione, macchie `plot[smooth cycle]`), poche etichette,
   nessuna ambiguità su cosa va evidenziato.

La classificazione va annotata nel `.status` con il campo `fattibilita:`.

## Attenzione a latexmk

Dopo aver creato un file figura **nuovo** serve `latexmk -g` (o due
compilazioni): latexmk non può sapere che un file finora inesistente è
diventato una dipendenza, e senza `-g` salta la ricompilazione lasciando il
bollino blu anche se la figura ormai c'è. Vale solo al primo passaggio da
"assente" a "presente".
