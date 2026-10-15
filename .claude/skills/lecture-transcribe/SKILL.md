---
name: lecture-transcribe
description: Trascrive una lezione universitaria in LaTeX a partire dalle immagini rasterizzate del PDF del professore e/o delle note personali dello studente. Usare quando viene invocata esplicitamente con /lecture-transcribe.
---

# Trascrizione lezione → LaTeX

Il tuo compito è produrre un file `.tex` pulito e ben strutturato a partire da:
1. Immagini delle slide/dispensa del professore (fonte primaria per enunciati, dimostrazioni, definizioni — sono la versione "ufficiale" e corretta del contenuto)
2. Immagini delle note personali dello studente (fonte per commenti a voce, esempi aggiuntivi fatti a lezione, domande, collegamenti — NON fidarti ciecamente della precisione simbolica di note scritte a mano velocemente)

Questo è il comportamento di **default (archetipo M1)**. Prima di applicarlo
verifica sempre quale archetipo vale per questo corso — vedi "Instradamento per
modello del materiale" qui sotto: M2, M3 e M4 lo modificano.

## Instradamento per modello del materiale

**Prima di trascrivere**, leggi in `CLAUDE.md` la sezione **"Modello del
materiale"** (tra i marker `<!-- BEGIN MODELLO-MATERIALE -->` /
`<!-- END MODELLO-MATERIALE -->`, generata da `/course-setup`): dice quale
archetipo vale per questo corso e quali categorie di sorgente sono attive. Non la
modifichi mai, la **consulti solo** per instradarti.

- **Blocco vuoto o assente** (modello non ancora generato) → ricadi sul default
  **M1** descritto sopra (`prof` + `mine`, prof fonte di verità), invariato.
- **M1 — slide complete.** Comportamento di default: nessuna modifica, prosegui
  con le regole 1–9 sotto.
- **M2 — slide-scheletro annotate, confini non rigidi.** Sorgenti attive
  `vergine` + `annotata` + `mine`. Vedi "Archetipo M2 — coverage annotata↔vergine"
  più sotto: cambia **come** leggi il contenuto stampato, non la gerarchia
  prof-fonte-di-verità (resta valida la regola 5).
- **M3 — lavagna / manoscritto.** Sorgenti `prof` (immagini, lette a vista) +
  `mine`. Nessuna modifica di gerarchia: il "prof" qui sono le immagini di lavagna
  o manoscritto invece di slide, tutto il resto (regole 1–9) resta invariato. Aspetta
  semplicemente più `\revisione` del solito: tutto il contenuto è manoscritto.
- **M4 — soli appunti dello studente.** Nessun materiale del prof esiste. Vedi
  "Archetipo M4 — appunti come fonte primaria" più sotto: **ribalta** le regole 4 e
  5.

Se il modello dichiara una categoria (es. `vergine`/`annotata`) ma il prompt di
questa esecuzione ti fornisce solo immagini `prof`/`mine` "semplici" (perché
l'orchestrazione automatica di quella categoria non è ancora attiva nello script
chiamante), tratta ciò che ricevi con le regole del default M1 e segnalalo in una
riga di nota a fondo file, invece di inventare una struttura M2 che i file forniti
non supportano.

## Regole obbligatorie

1. **Leggi sempre `CLAUDE.md` (se presente) e `preamble.tex` nella root del progetto prima di iniziare**, per rispettare le convenzioni di notazione e i macro già definiti. Non inventare nuovi comandi se esiste già un equivalente. `CLAUDE.md` è specifico del corso e contiene la notazione e le convenzioni decise dal professore/studente: se manca, attieniti a `preamble.tex` e alle convenzioni generali qui sotto.

2. **Ambienti: usa la sintassi `tcbtheorem` definita in `preamble.tex`, NON `amsthm` classico.** Gli ambienti disponibili sono `theorem`, `property`, `definition`, `lemma`, ciascuno con la firma:
   ```latex
   \begin{theorem}{<Titolo breve o vuoto>}{<chiave-label-in-inglese>}
     Enunciato...
   \end{theorem}
   ```
   Il terzo argomento (chiave) diventa automaticamente il label con prefisso
   dell'ambiente (es. `theorem` con chiave `<chiave>` produce il label
   `th:<chiave>`; `property`→`pr:`, `definition`→`def:`, `lemma`→`lem:`). NON
   aggiungere tu il prefisso nella chiave, lo aggiunge l'ambiente
   automaticamente.
   Per riferirti a un risultato altrove usa `\ref{th:<chiave>}`
   (niente `\cref`, non è caricato). Le dimostrazioni restano invece in
   `\begin{proof}...\end{proof}` (ambiente standard di `amsthm`, incluso nel
   preambolo), fuori dal box del teorema.
   Ogni lezione è un frammento incluso nel file master: NON usare `\chapter`,
   apri il contenuto con `\section{<argomento della lezione>}` (o
   `\subsection` se prosegue un argomento già iniziato in una lezione
   precedente — controlla i file già presenti in `lezioni/` per capire se è
   il caso).
   Subito **prima** del `\section` metti il marker per l'indice delle lezioni:
   `\lezione{<numero>}{<titolo>}` (dove `<numero>` è quello della lezione del
   professore, es. dal file `raw/prof/NN_...`). Serve a popolare il secondo
   indice "Indice delle lezioni" con collegamento al punto d'inizio; il titolo
   è facoltativo (`\lezione{2}{}` → solo "Lezione 2").

3. **Marker di incertezza — REGOLA PIÙ IMPORTANTE**: se non sei sicuro al 100% di aver letto correttamente una formula, un passaggio di dimostrazione, o un'ipotesi, NON indovinare e non "aggiustare" silenziosamente per farlo tornare. Inserisci invece:
   ```latex
   \revisione{<breve descrizione del dubbio, es. "verificare se l'esponente è n o n-1, immagine poco leggibile">}
   ```
   (comando definito in `preamble.tex`, produce un marker inline **rosso**.)
   Meglio troppi marker che un errore matematico silenzioso. Lo studente li correggerà a mano guardando i bollini nel PDF compilato.

4. **Disegni del professore — NON ricostruirli, segnalali**: se in un'immagine sorgente **del professore** compare un disegno, uno schema o un diagramma fatto a mano (quindi non testo, non una formula in simboli, e non qualcosa di banalmente riproducibile con TikZ in poche righe), NON tentare di ridisegnarlo e NON sostituirlo con una descrizione a parole nel corpo del testo. Inserisci invece, nel punto esatto in cui il disegno comparirebbe:
   ```latex
   \figura{<chiave-stabile>}{<breve descrizione del disegno>}
   ```
   Usa **sempre `\figura`**, mai `\figuramancante` diretto: la chiave è l'ancoraggio permanente della figura, e senza di essa il disegno non è tracciabile né agganciabile in seguito. La chiave è un identificatore breve e stabile (`composizione-funzioni`, `diagramma-esempio`), **mai** derivato dalla descrizione — la descrizione può cambiare in una ri-trascrizione, la chiave no.

   Finché nessuno ha disegnato la figura, `\figura` stampa da sé un marker inline **blu**, visivamente distinto dal rosso di `\revisione`, così lo studente riconosce a colpo d'occhio dove serve un disegno e dove serve solo una verifica testuale. Quando il file `figure/fig/<categoria>/<chiave>.tex` verrà creato, la figura si aggancerà da sola: tu non devi crearlo né modificare la lezione. Vedi `.claude/docs/gestione-figure.md`.
   I disegni presenti **solo** nelle note personali dello studente vanno **ignorati** ai fini di questo marker: quelle note sono appunti sommari e i loro disegni sono promemoria personali, non materiale da segnalare per l'inserimento nel documento finale. **Eccezione — archetipo M4**: se non esiste materiale del professore (vedi "Instradamento"), questa esclusione non si applica: le note sono l'unica fonte, quindi un disegno del professore fatto a lezione e ricopiato nelle note (o descritto a voce e disegnato dallo studente) va segnalato con `\figura` come per qualunque altra fonte primaria.

5. **Gerarchia delle fonti (default M1/M2/M3) — il professore è la verità, le note solo arricchiscono**: questa regola vale per M1, M2 e M3. **L'archetipo M4 la ribalta interamente** — vedi "Archetipo M4" sotto, applicala PRIMA di leggere questa regola se il corso non ha materiale del prof. Il materiale del professore è ordinato ed è la **fonte di verità principale** del contenuto; le note dello studente sono appunti presi al volo, spesso disordinati e poco leggibili, e non vanno mai trattate come fonte primaria. Applica questa priorità:
   - il **contenuto** (definizioni, teoremi, enunciati, dimostrazioni) si trascrive **sempre** dal PDF del prof, mai dalle note;
   - le **note servono solo ad arricchire** con osservazioni informali o dettagli aggiunti a lezione ("Nota: ..."), **mai** come fonte primaria di un contenuto che il prof non ha scritto;
   - **note illeggibili quando il prof è chiaro → NON è un `\revisione`**: se una nota è dubbia o illeggibile ma il contenuto equivalente è chiaro nel materiale del prof, **ignora la nota** e procedi con la fonte del prof, senza marcare nulla come incerto;
   - **`\revisione` è per l'incertezza del PROF**, non delle note: usalo quando è il materiale del professore a essere ambiguo o poco leggibile;
   - **unica eccezione**: se le note aggiungono un'osservazione che il prof non ha scritto e proprio quella parte è poco leggibile, allora `\revisione` ha senso lì, perché le note sono l'unica fonte di quel contenuto specifico.

   **Attenzione ai confini quando un file di note copre più blocchi**: i file del professore sono spesso divisi in blocchi orari fissi, ma un singolo file di note dello studente può coprire più blocchi contemporaneamente (es. un'unica nota per una lezione di 3 ore, che corrisponde a 2 file separati del professore). In questi casi il prompt ti indicherà esplicitamente quali file del professore fanno parte dell'esecuzione corrente: usa SOLO la porzione delle note personali che tratta gli stessi argomenti di quei file. Se il confine tra un argomento e il successivo nelle note manoscritte non è netto, non tagliare a caso: inserisci `\revisione{possibile contenuto di un altro blocco di lezione, confine incerto}` vicino al punto dubbio invece di includere o escludere silenziosamente del materiale.

### Archetipo M2 — coverage annotata↔vergine

Vale quando il modello del materiale dichiara le categorie `vergine` + `annotata`
(+ `mine`). La gerarchia della regola 5 **resta valida** (il prof è la fonte di
verità), ma cambia **quale immagine leggi per cosa**:

- Il prompt di questa esecuzione ti indicherà, oltre alle immagini `annotata*`
  (copia con la penna del prof) e `vergine*` (slide pulite), il percorso di una
  mappa di coverage `align/<nome>/coverage.json` (prodotta da
  `scripts/align_slides.sh`), con una voce per ogni pagina annotata:
  `{"annot": N, "match": {"deck": D, "pagina": P}, "conf": "alta"|"bassa"}` oppure
  `"match": null` (pagina **inserita** dal prof, senza corrispondente vergine).
  **Leggila prima di iniziare a trascrivere** (Read), non procedere a occhio sulle
  immagini senza consultarla.
- **Contenuto stampato** (definizioni, teoremi, enunciati che erano già sulla
  slide): trascrivilo dalla pagina **vergine** indicata dal match — è la versione
  tipografica pulita, più affidabile di una foto/scan con inchiostro sopra.
- **Inchiostro del prof** (dimostrazioni scritte a mano, esempi aggiunti,
  correzioni, frecce, sottolineature): leggilo dalla pagina **annotata**
  corrispondente — è lì che vive, la vergine non lo contiene. Se il profilo del
  professore registra un significato per il colore dell'inchiostro, applicalo.
- **Pagine con `match: null` (inserite)**: nessuna vergine di riferimento esiste.
  Trattale come materiale del prof "a vista" (come in M3): leggi solo l'annotata,
  aspettati più `\revisione` per via della grafia a mano.
- **Pagine con `"conf": "bassa"`**: la mappa stessa segnala incertezza sul match.
  Confronta comunque il testo di annotata e vergine prima di fidartene; se dopo il
  confronto il contenuto resta ambiguo, inserisci `\revisione` invece di scegliere
  a caso quale delle due versioni seguire.
- **Coverage.json mancante o non indicato nel prompt** pur essendo dichiarato M2:
  la skill non deve bloccarsi. Applica il fallback già previsto da
  `/course-setup`: tratta l'intera copia annotata come sorgente `prof` diretta
  (lettura a vista, come M3) e aggiungi una riga di nota a fondo file che segnala
  l'assenza della mappa, così lo studente sa che l'allineamento andrebbe rifatto.

### Archetipo M4 — appunti come fonte primaria

Vale quando il modello del materiale dichiara **nessun materiale del professore**
(solo categoria `mine`). **Ribalta la regola 5**, non la applicare:

- Le **note dello studente sono l'unica fonte** e quindi la fonte di verità: il
  contenuto (definizioni, teoremi, dimostrazioni) si trascrive da lì, non esiste un
  PDF del prof con cui confrontarle o da cui preferire una versione alternativa.
- `\revisione` si applica **direttamente** all'incertezza delle note (formula
  poco leggibile, passaggio dubbio, grafia veloce) — non più solo come eccezione
  residua: qui è la regola, non il caso limite.
- I disegni nelle note **non** vanno ignorati (vedi eccezione già segnalata nella
  regola 4): sono l'unica fonte disponibile.
- Non inventare un confronto con "cosa avrebbe scritto il prof": non c'è nulla con
  cui confrontarsi. Se le note sono ambigue su un punto, marca `\revisione` e
  prosegui, non completare a supposizione.

6. **Dimostrazioni sempre complete e dettagliate** (salvo diversa indicazione in `CLAUDE.md`): non riassumere un passaggio logico del professore con "segue facilmente" o simili, anche se la dimostrazione è lunga. Unica eccezione: se il professore lascia esplicitamente un risultato come esercizio (nelle slide compaiono riquadri "EX" o dicitura simile), NON inventare la dimostrazione — trascrivi come `\textit{Esercizio: ...}` (eventualmente con l'enunciato dell'esercizio se presente), rispettando la scelta didattica del professore di lasciarlo aperto allo studente.

7. **Coerenza di notazione tra lezioni**: se il file `CLAUDE.md` specifica una notazione (es. $\mathbb{R}$ vs un comando custom `\R`), usala sempre, anche se nelle immagini il prof scrive diversamente — la notazione dello studente deve restare uniforme in tutto il corso.

8. **Non occuparti dell'impaginazione**: durante la trascrizione non inserire MAI `\Needspace*`, `\newpage`, `\clearpage` o altri comandi per controllare dove cadono le interruzioni di pagina, e non preoccuparti se un titolo finisce isolato a fondo pagina. L'impaginazione dipende da tutto ciò che precede nel documento e cambia a ogni lezione aggiunta, a ogni disegno inserito al posto di un `\figuramancante` e a ogni modifica del preambolo: sistemarla adesso è lavoro che verrà invalidato. La passata correttiva sull'impaginazione va eseguita solo a dispensa completa.

9. Al termine, aggiungi in fondo al file un blocco commentato con il conteggio dei marker inseriti, distinguendo i due tipi, es. `% 4 REVIEW markers da controllare, 2 disegni da inserire`, così lo script chiamante può segnalarlo.

## Output

Scrivi il risultato nel percorso indicato nel prompt (tipicamente
`lezioni/<nome_output>.tex`). Il file NON deve contenere `\documentclass`,
`\input{preamble}`, `\begin{document}` né altro preambolo: è un frammento
che viene incluso da `master.tex` tramite `\input{lezioni/<nome_output>}` dentro
un `\chapter` già aperto dallo studente. Deve iniziare direttamente con
`\section{...}` (o `\subsection{...}`) seguito dal contenuto.
