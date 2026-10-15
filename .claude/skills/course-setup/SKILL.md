---
name: course-setup
description: Intervista adattiva che deduce COM'È ORGANIZZATO il materiale del corso (quali sorgenti esistono — slide, lavagna, tuoi appunti — come sono fatte e come si relazionano) e scrive il risultato nella sezione "Modello del materiale" di CLAUDE.md, così che il resto della pipeline sappia quali categorie di sorgente esistono e come trattarle. È il PRIMO passo dopo aver clonato il template. PRIMA di scrivere qualsiasi cosa presenta un'anteprima del modello per conferma esplicita. Usare quando viene invocata con /course-setup.
---

# Modello del materiale → sezione di `CLAUDE.md`

Il tuo compito è capire, con una **breve intervista** allo studente, **com'è
organizzato il materiale di questo corso**: quali sorgenti esistono (slide del
professore, lavagna, tuoi appunti…), in che forma sono (PDF digitale? scansione?),
come si relazionano tra loro e dove cadono i confini di lezione. Il risultato va
scritto nella sezione **"Modello del materiale"** di `CLAUDE.md` — ma **solo dopo
conferma esplicita dello studente**.

Questo è il **passo zero** della pipeline, da eseguire **subito dopo aver clonato
il template** e **prima** di trascrivere qualsiasi lezione. Decide la *forma della
pipeline*: quali categorie di sorgente esistono (`prof`/`mine`, oppure
`vergine`/`annotata`/`mine`, oppure solo `mine`…), quali flag servono a
`new_lecture.sh`, e se serve il passo di **allineamento** annotata↔vergine. Si
rifà solo se cambia il corso o il professore, non a ogni lezione.

## A quale domanda risponde — logistica, NON notazione

Il modello del materiale risponde a: **«quali file esistono, come sono fatti e come
si relazionano?»** — è *logistica* del materiale. È **ortogonale** al **profilo del
professore** (`/professor-profile`), che risponde invece a **«con che notazione
trascriverli?»** — è *stile*. Non sconfinare nell'altro asse:

- **Non dedurre notazione** qui (simboli insiemistici, come segna gli esercizi,
  livello di dettaglio delle dimostrazioni): è compito di `/professor-profile`.
- **Non riscrivere regole di sistema** (ambienti `tcbtheorem`, marker
  `\revisione`/`\figura`, indici, impaginazione, struttura): sono fisse altrove nel
  template e non si toccano.

## Confine di responsabilità — scrivi SOLO tra i marker

Scrivi esclusivamente **tra** `<!-- BEGIN MODELLO-MATERIALE -->` e
`<!-- END MODELLO-MATERIALE -->` in `CLAUDE.md`. Tutto il resto del file resta
intatto. Se la sezione contiene già un modello (ri-esecuzione), **sostituiscilo per
intero** con quello nuovo, non accodare.

## Prima di iniziare

1. **Leggi `CLAUDE.md`** nella root e individua i marker
   `<!-- BEGIN MODELLO-MATERIALE -->` / `<!-- END MODELLO-MATERIALE -->`: è lì che
   scriverai. Se `CLAUDE.md` non esiste o i marker mancano, il progetto non è stato
   clonato dal template: **fermati e segnalalo** invece di crearne uno da zero.
2. **Leggi `scripts/new_lecture.sh`** (o `.ps1`) per sapere quali **categorie di
   sorgente e flag** la pipeline supporta **oggi** (`--prof`, `--mine`,
   `--annotata`, `--vergine`). Il modello che scrivi deve appoggiarsi a ciò che
   esiste; se il corso richiede una categoria che lo script non supporta,
   **dichiarala comunque** nel modello ma **segnala esplicitamente** allo studente
   che quel trattamento non è attivo nella pipeline (vedi "Categorie di sorgente
   e flag").
3. Se esiste già un modello tra i marker (ri-esecuzione), leggilo: parti da quello e
   chiedi solo cosa è cambiato, non ricominciare da zero.

## L'intervista — adattiva, breve, a rami

Conduci un'**intervista conversazionale**, non un modulo da compilare tutto in una
volta. Regole di conduzione:

- **Un tema alla volta**, in linguaggio semplice. Raggruppa le domande per blocchi
  logici; non sparare tutte le dimensioni insieme.
- **I rami si saltano**: se lo studente dice che il corso non usa slide, **non
  fare** nessuna delle domande sulle slide (forma dei file, annotazioni, vergine
  vs annotato, confini). Chiedi solo ciò che è pertinente al caso emerso.
- **Non chiedere fatti per-lezione**: il modello cattura ciò che è **stabile** per
  il corso (che tipo di materiale, che forma, che rapporti). *Quanto* di un set di
  slide venga trattato in una certa lezione, o quali pagine, si decide lezione per
  lezione altrove — non qui.
- **Proponi default ragionevoli** quando lo studente è incerto, e marcali come "da
  confermare" nel modello, così restano riconoscibili.
- Se una risposta è ambigua, **chiedi un chiarimento** invece di indovinare.

## Le dimensioni da coprire (con la logica dei rami)

Parti dal materiale del professore, poi dai tuoi appunti, poi dal contorno.

1. **Materiale del professore.** Che cosa produce/distribuisce il professore?
   - *slide complete* (autosufficienti) — *slide-scheletro* poi completate a lezione
     — *lavagna* (scritta a lezione, tu fotografi/scansioni) — *manoscritto*
     (dispense sue a mano) — *nessun materiale* (solo i tuoi appunti).
   - Se **nessun materiale del prof** → salta al blocco "Tuoi appunti". Il modello
     sarà del tipo "soli appunti dello studente".

2. **Forma dei file** (solo se il prof produce materiale). PDF **digitale** (con
   text layer estraibile) oppure **scansione/foto** (solo immagini)? Questo decide
   se il contenuto stampato si può estrarre come testo o va letto a vista.

3. **Annotazioni** (solo se ci sono slide/manoscritto su cui annotare). Ci sono
   annotazioni sopra il materiale stampato? **Di chi** (del professore / tue)?
   In che forma (**a penna** su copia scansionata / **native digitali** su PDF —
   es. tablet)? Il **colore** ha un significato ricorrente (es. rosso = correzione,
   blu = esempio)? — se sì, registralo, servirà a `professor-profile` e alla
   trascrizione.

4. **Vergine vs annotato** (solo se ci sono annotazioni sul materiale del prof).
   Esiste il materiale **vergine** (slide pulite) **separato** dalla copia
   **annotata**, o hai solo l'annotato? Se l'annotato è un **PDF digitale**, il suo
   text layer *è già* il contenuto vergine per le pagine che copre: la vergine
   separata serve da completamento/controprova ma può non essere obbligatoria.

5. **Confini di lezione** (solo se ci sono slide del prof). Un file di slide =
   una lezione (confini **coincidenti**), oppure una lezione **attraversa più set**
   e può iniziare/finire a metà di un set (confini **non rigidi**)? Il caso non
   rigido — tipicamente slide-scheletro annotate — è quello che richiederà il passo
   di **allineamento** annotata↔vergine per ricostruire lo *span* trattato.

6. **Tuoi appunti.** Prendi appunti a lezione? In che forma (foto/scansione a mano,
   digitali)? Poi distingui **due assi diversi**, che è facilissimo confondere — non
   fondere la domanda in una sola:
   - **quante lezioni d'aula stanno in un tuo file:** un file = una lezione d'aula,
     oppure accorpi più lezioni in un unico file?
   - **come quel file si rapporta ai file di slide del prof:** se i confini di
     lezione sono **non rigidi** (punto 5), anche un file che copre *una sola*
     lezione d'aula può corrispondere a uno **span che attraversa più set** del prof.
     Questo serve all'allineamento e **non** è la stessa cosa dell'accorpare più
     lezioni d'aula. Chiedilo separatamente.

7. **Riferimenti e lingua.** C'è un **libro/dispensa** di riferimento del corso?
   Qual è la **lingua** del corso (italiano/inglese)?

## Archetipi — per orientarti (non gabbie)

Le risposte di solito ricadono in uno di questi modelli. Usali per dare un **nome**
al modello e scegliere le categorie di sorgente; se un corso è a metà strada,
descrivi ciò che è vero, non forzarlo in un archetipo.

- **M1 — Slide complete digitali.** Il prof distribuisce slide autosufficienti (PDF
  con testo), poche o nessuna annotazione. Categorie: `prof` (verità) + `mine`
  (arricchimento). È il modello di default della pipeline.
- **M2 — Slide-scheletro annotate, confini non rigidi.** Slide lunghe completate a
  lezione, annotazioni (spesso del prof) sopra, una lezione attraversa più set.
  Categorie: `vergine` (contenuto) + `annotata` (coverage + annotazioni) + `mine`.
  **Richiede l'allineamento** annotata↔vergine.
- **M3 — Lavagna / manoscritto.** Nessuna slide; il contenuto del prof è scritto a
  lezione o a mano e fotografato/scansionato. Categorie: `prof` (immagini, lette a
  vista) + `mine`. `\revisione` diventa più frequente (tutto manoscritto).
- **M4 — Soli appunti dello studente.** Il prof non distribuisce nulla. Categoria:
  solo `mine`, che qui **è** la fonte primaria (non solo arricchimento — nota bene:
  ribalta la gerarchia di default di `lecture-transcribe`).

## Categorie di sorgente e flag — appòggiati a ciò che esiste

Dal modello discende **quali categorie di sorgente** sono attive e **con quali flag**
si passano a `new_lecture.sh`. Regole:

- Mappa ogni categoria del modello sul **flag realmente esistente** nello script
  (che hai letto in "Prima di iniziare"). Oggi lo script supporta `--prof`,
  `--mine` e, per l'archetipo M2, `--annotata` + `--vergine` (che vanno forniti
  insieme: lo script esegue da sé il passo di allineamento annotata↔vergine
  prima di trascrivere). Per tutti i modelli, se non passi nessun `--mine` lo
  script si ferma e avvisa: serve `--senza-note` per procedere con il solo
  materiale del professore (non vale per `--solo-raster`).
- Se il modello introduce categorie **non supportate** dallo script, **dichiarale
  nel modello** ma aggiungi una riga esplicita del tipo: «*Nota: questa categoria
  non è supportata dalla pipeline; finché non lo è, trattala come sorgente
  `--prof`.*» Così lo studente sa cosa è dichiarato e cosa è già operativo,
  senza sorprese.
- Non inventare flag: se non sei sicuro di come lo script li chiami, riporta il
  nome concettuale della categoria e segnala che il flag va confermato.

## Anteprima obbligatoria — conferma PRIMA di scrivere

**Non modificare `CLAUDE.md` prima di aver mostrato l'anteprima e ricevuto conferma
esplicita.** Presenta:

1. Una **tabella** con una riga per dimensione:

   | dimensione | valore dedotto | confidenza |
   |------------|----------------|------------|
   | materiale del prof | slide-scheletro annotate | confermato |
   | forma dei file | PDF digitale | confermato |
   | annotazioni | del prof, native digitali, colore non significativo | confermato |
   | vergine separato | sì | confermato |
   | confini lezione | non rigidi (attraversano più set) | confermato |
   | tuoi appunti | foto a mano, accorpano più blocchi | confermato |
   | riferimenti / lingua | nessun libro / italiano | da confermare |

2. Il **nome dell'archetipo** individuato (o "modello misto" con descrizione).
3. Le **categorie di sorgente attive** con i flag corrispondenti, evidenziando
   quelle **non ancora supportate** dalla pipeline (vedi sopra).
4. Le voci **"da confermare"** in chiaro, così lo studente può correggerle.

Poi **fermati e chiedi conferma**. Lo studente può correggere singole voci o
rifiutare un default. Applica le correzioni e, se le modifiche sono sostanziali,
ripresenta la tabella.

## Scrittura (solo dopo conferma)

Sostituisci il contenuto **tra** `<!-- BEGIN MODELLO-MATERIALE -->` e
`<!-- END MODELLO-MATERIALE -->` con il modello confermato, scritto come
**istruzioni operative** per chi trascrive e per chi lancia `new_lecture.sh`
(es. «Categorie attive: `vergine` + `annotata` + `mine`. La copia annotata è un PDF
digitale: estrai il contenuto stampato dal text layer, leggi a vista solo la penna
del prof.»). Regole:

- Tocca **solo** il testo fra i due marker; lascia intatto tutto il resto del file.
- Organizza per le stesse dimensioni della tabella, più una riga finale
  **"Categorie di sorgente e flag"**.
- Riporta accanto alle voci **"da confermare"** un breve inciso, così restano
  riconoscibili in futuro.
- Se una categoria dichiarata **non è supportata** dalla pipeline, scrivi la
  nota di fallback esplicita anche nel blocco (non solo a voce).

Al termine, riepiloga il modello scritto e indica il **prossimo passo**: se il corso
ha materiale del professore con una notazione da uniformare, esegui
`/professor-profile` su un campione; altrimenti si può passare direttamente a
trascrivere le lezioni con `new_lecture.sh`. Ricorda che conviene rilanciare
`/course-setup` solo se cambia l'organizzazione del materiale (nuovo corso o nuovo
professore).
