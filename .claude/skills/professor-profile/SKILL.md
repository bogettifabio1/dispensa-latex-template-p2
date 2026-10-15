---
name: professor-profile
description: Analizza un campione di lezioni del professore (immagini rasterizzate del suo materiale) per dedurne la notazione e lo stile, e scrive il risultato nella sezione "Profilo del professore" di CLAUDE.md, così che lecture-transcribe trascriva con le convenzioni giuste. PRIMA di scrivere qualsiasi cosa presenta una tabella di anteprima del profilo per conferma esplicita. Usare quando viene invocata con /professor-profile.
---

# Profilo del professore → sezione di `CLAUDE.md`

Il tuo compito è, a partire da un **piccolo campione** di lezioni del professore
(le immagini rasterizzate del suo materiale), dedurre **come scrive**: quali
simboli e convenzioni di notazione usa, come struttura enunciati e dimostrazioni,
che livello di dettaglio tiene. Il risultato va scritto nella sezione
**"Profilo del professore"** di `CLAUDE.md` — ma **solo dopo conferma esplicita
dell'utente**.

Questo profilo è ciò che `lecture-transcribe` legge («Leggi sempre `CLAUDE.md` se
presente») per trascrivere le lezioni successive con la notazione del corso già
uniformata. È il passo di **bootstrap** della pipeline: senza, ogni trascrizione
tira a indovinare la notazione da capo.

## A quale domanda risponde il profilo — è un'impronta d'autore, NON un filtro di argomenti

Il profilo è un'**impronta d'autore**: registra le scelte di notazione che rendono
una pagina riconoscibilmente di *questo* docente. La domanda guida è: «quali scelte
notazionali fanno dire che questa pagina è stata scritta da questo docente e non da
un altro?» — per esempio $A^c$ vs $\complement A$ vs barra sopra, $\mathcal{P}(X)$
vs $2^X$, `card` per esteso vs $|\cdot|$, come segnala gli esercizi lasciati allo
studente, se numera i teoremi o li titola solo col nome.

**Non è un filtro sugli argomenti.** Cattura la notazione che il docente **usa
davvero**, qualunque sia l'argomento trattato. Se sfiora un tema tipico di un altro
settore (es. una docente di Probabilità che parla di insiemi aperti), la sua
notazione per quel tema va **comunque** registrata quando è una scelta
caratteristica sua — non si esclude nulla per argomento. L'unico limite è quello
del punto successivo: non **inventare** convenzioni non osservate copiandole dalla
notazione tipica di un altro dominio o di un altro docente.

## Confine di responsabilità — genera SOLO ciò che varia da professore a professore

`CLAUDE.md` contiene tre tipi di regole, su assi diversi:

- **(a) regole di sistema, invarianti** — ambienti `tcbtheorem`, marker
  `\revisione`/`\figura`, gestione figure, doppio indice, capitoli/sezioni,
  passata di impaginazione, struttura del progetto. Sono **fisse** nello scheletro
  del template e **non le devi toccare**.
- **(b) modello del materiale** — *com'è organizzato* il materiale del corso (quali
  sorgenti esistono, che forma hanno, come si relazionano). Lo genera
  `/course-setup`. È un asse **ortogonale** al tuo: risponde a «quali file esistono»,
  non a «con che notazione trascriverli». Questa skill lo **legge** per instradarsi
  (vedi "Prima di iniziare"), ma **non lo scrive mai**.
- **(c) profilo del professore** — *notazione*, stile degli enunciati, livello di
  dettaglio. È **l'unica cosa che questa skill genera**.

Scrivi esclusivamente **tra i marker** `<!-- BEGIN PROFILO-PROFESSORE -->` e
`<!-- END PROFILO-PROFESSORE -->`. Tutto il resto di `CLAUDE.md` resta intatto —
incluso il blocco `MODELLO-MATERIALE`, che **consulti ma non modifichi**. Non
ri-derivare le regole invarianti: sono già scritte e stabili, riscriverle
significa solo rischiare di sbagliarle.

## Prima di iniziare

1. **Leggi `CLAUDE.md`** nella root del progetto e individua i marker
   `<!-- BEGIN PROFILO-PROFESSORE -->` / `<!-- END PROFILO-PROFESSORE -->`: è lì
   che scriverai. Se `CLAUDE.md` non esiste, il progetto non è stato copiato dal
   template: fermati e segnalalo all'utente invece di crearne uno da zero.
2. **Consulta il "Modello del materiale"** (tra i marker
   `<!-- BEGIN MODELLO-MATERIALE -->` / `<!-- END MODELLO-MATERIALE -->`, generato da
   `/course-setup`) per **instradarti** — lo leggi soltanto, non lo tocchi:
   - **Se non c'è materiale del professore** (archetipo M4, soli appunti dello
     studente): **non c'è notazione del prof da profilare**. Fermati e spiegalo
     all'utente — la notazione ricadrà sui default di `preamble.tex` e questa skill
     non ha una fonte del prof da campionare. Non profilare le note personali dello
     studente: non è il compito di questa skill.
   - **Altrimenti scegli la sorgente da campionare** in base al modello: se ci sono
     slide pulite del prof (M1) o **vergini** separate (M2), campiona **quelle** — la
     notazione tipografica è netta — non la copia con la penna sopra; se il materiale
     del prof è a lavagna o manoscritto (M3), campiona le immagini del prof così come
     sono, mettendo in conto che la notazione è meno nitida.
   - **Se il blocco è vuoto** (modello non ancora generato): assumi il default `prof`
     e prosegui, senza bloccarti.
3. **Leggi `preamble.tex`** per sapere quali comandi e ambienti **esistono già**
   (es. `\R \N \Z \Q \C`, gli ambienti `theorem/property/definition/lemma`, le
   categorie in `\figuracategorie`). Le decisioni di notazione devono
   **appoggiarsi a ciò che c'è già**, non reinventarlo.
4. **Individua il campione da analizzare.** Il prompt indicherà quali lezioni
   usare; le immagini stanno in `raw/_images/<nome>/` con prefisso `prof1_`,
   `prof2_`, … (le note personali, prefisso `mine`, si **ignorano**: sono appunti
   disordinati, non la notazione ufficiale del professore). Se non è indicato
   nulla, chiedi quali lezioni usare. Un campione di **2–4 lezioni** è di norma
   sufficiente e rappresentativo; una sola lezione rischia di non far comparire
   simboli comuni.

## Cosa dedurre — le dimensioni del profilo

Per ognuna delle dimensioni sotto, guarda **cosa fa davvero il professore** nelle
immagini e traducilo in una **decisione LaTeX concreta** (cosa scrivere), non in
una descrizione vaga. Analizza **solo il materiale del professore**.

- **Notazione insiemistica** — inclusione (`\subseteq` vs `\subset`, e se
  distingue quella stretta), differenza (`\setminus` vs segno meno), complementare
  ($A^c$, $\complement A$, $C_X(A)$…), insieme vuoto, insieme delle parti
  ($\mathcal{P}(X)$ vs $2^X$), prodotto cartesiano e prodotti indicizzati.
- **Funzioni e corrispondenze** — notazione di immagine/controimmagine, se scrive
  iniettiva/suriettiva/biiettiva per esteso o abbreviate, notazione per l'insieme
  delle funzioni ($Y^X$…), eventuali abusi di notazione che il prof adotta e vuole
  mantenere (es. `f^{-1}` sia per inversa sia per controimmagine).
- **Relazioni di equivalenza e ordine** — simbolo di equivalenza ($\sim$ vs
  $\equiv$ vs $\approx$), classe di equivalenza, insieme quoziente, simbolo
  d'ordine ($\le$ generico vs un dedicato come `\preceq`).
- **Insiemi numerici e simboli ricorrenti** — verifica che i simboli del prof
  corrispondano ai comandi già in `preamble.tex` (`\R`, `\N`, …); se il prof usa
  una notazione ricorrente **non** coperta da un comando esistente, **proponi** un
  nuovo comando ma **non aggiungerlo tu** al preambolo: segnalalo (vedi sotto).
- **Notazioni specifiche dell'argomento** — notazioni tematiche che ricorrono
  (es. un intorno scritto $I_r(x)=(x-r,x+r)$ invece di $B(x,r)$). Registrale, ma
  segnala che potrebbero valere **solo per quell'argomento** e andranno confermate
  quando il corso cambia tema.
- **Ambienti ed enunciati** — come il professore struttura teoremi, definizioni,
  proprietà, lemmi; se li numera; **come segnala gli esercizi lasciati allo
  studente** (riquadri "EX", dicitura "per esercizio", ecc.), perché
  `lecture-transcribe` deve riconoscerli e non dimostrarli.
- **Livello di dettaglio delle dimostrazioni** — il prof scrive dimostrazioni
  complete passo-passo o sintetiche con "segue facilmente"? Questa scelta decide
  se `lecture-transcribe` deve espandere o restare fedele alla sintesi.
- **Lingua e stile** — lingua del corso (italiano/inglese), uso di osservazioni
  informali (etichetta "Nota:"), eventuali convenzioni tipografiche costanti.

## Regole di metodo — la barra di qualità

- **Solo su evidenza.** Ogni convenzione dedotta deve poggiare su un punto preciso
  del materiale: annota **dove** l'hai vista (lezione, pagina, posizione). Non
  inventare convenzioni che non hai osservato.
- **Distingui la confidenza** in tre livelli, sempre:
  - `osservato` — il prof usa esplicitamente quel simbolo/quella convenzione;
  - `dedotto` — inferito da segnali indiretti (coerente ma non visto in chiaro);
  - `non-osservato` — nel campione non compare: proponi un **default generico
    ragionevole** e marcalo come tale, **non tirare a indovinare** spacciandolo
    per osservato. In particolare **non copiare** la convenzione da un altro
    dominio o da un altro docente: meglio una voce marcata "da confermare" (o
    assente) che la notazione di qualcun altro spacciata per quella di questo prof.
- **Appòggiati al preambolo.** Preferisci sempre i comandi già definiti; un nuovo
  comando si **propone**, non si aggiunge in silenzio (l'utente deciderà se
  metterlo in `preamble.tex`).
- **Niente regole di sistema.** Non scrivere nel profilo nulla che riguardi
  figure, indici, impaginazione, struttura del progetto: sono già fisse altrove.

## Anteprima obbligatoria — conferma PRIMA di scrivere

**Non modificare `CLAUDE.md` prima di aver mostrato l'anteprima e ricevuto
conferma esplicita.** Presenta una tabella con una riga per convenzione:

| ambito | convenzione dedotta (decisione LaTeX) | evidenza | confidenza |
|--------|----------------------------------------|----------|------------|
| inclusione | `\subseteq` debole, `\subsetneq` stretta | Lez 1 p.3, Lez 2 p.1 | osservato |
| complementare | $A^c$ | Lez 2 p.4 | osservato |
| equivalenza | $\sim$ | — (mai comparsa nel campione) | non-osservato → default $\sim$ |
| ... | ... | ... | ... |

Sotto la tabella elenca esplicitamente:
- le voci `non-osservato` con il default proposto (così l'utente sa cosa non era
  nel campione e può correggerle o chiedere più lezioni);
- eventuali **nuovi comandi** che consiglieresti di aggiungere a `preamble.tex`,
  con la definizione proposta;
- le notazioni segnalate come potenzialmente **solo tematiche**.

Poi **fermati e chiedi conferma**. L'utente può correggere singole voci, chiedere
di analizzare altre lezioni, o rifiutare un default. Applica le correzioni e, se
le modifiche sono sostanziali, ripresenta la tabella.

## Scrittura (solo dopo conferma)

Sostituisci il contenuto **tra** `<!-- BEGIN PROFILO-PROFESSORE -->` e
`<!-- END PROFILO-PROFESSORE -->` in `CLAUDE.md` con il profilo confermato,
organizzato per le stesse dimensioni della tabella e scritto come **istruzioni
operative** per chi trascrive (es. «Inclusione: usa `\subseteq` per l'inclusione
debole, `\subsetneq` per quella stretta»). Regole:

- Tocca **solo** il testo fra i due marker; lascia intatto tutto il resto del file.
- Se la sezione contiene già un profilo (ri-esecuzione), **sostituiscilo per
  intero** con quello nuovo, non accodare.
- Riporta accanto alle voci `non-osservato` un breve inciso che sono default da
  confermare, così restano riconoscibili in futuro.
- I nuovi comandi proposti **non** vanno scritti in `preamble.tex` da questa
  skill: al massimo elencali in coda al profilo come «Comandi suggeriti (da
  aggiungere a mano a `preamble.tex` se si vogliono)».

Al termine, riepiloga quali ambiti hai popolato, quanti erano `non-osservato`, e
ricorda che d'ora in poi `lecture-transcribe` userà questo profilo — e che
conviene rilanciare `/professor-profile` se in seguito emergono convenzioni nuove.
