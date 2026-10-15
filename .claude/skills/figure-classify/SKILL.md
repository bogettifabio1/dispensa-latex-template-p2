---
name: figure-classify
description: Classifica la fattibilità in TikZ delle figure ancorate con \figura{chiave}{descrizione} in una lezione già trascritta, applicando i 5 test di .claude/docs/gestione-figure.md al materiale del professore. PRIMA di scrivere qualsiasi file .status presenta una tabella di anteprima per conferma esplicita. Usare quando viene invocata con /figure-classify.
---

# Classificazione fattibilità figure → file `.status`

Il tuo compito è, per una lezione **già trascritta**, prendere ogni ancoraggio
`\figura{<chiave>}{<descrizione>}` presente nel `.tex`, guardare il disegno
originale nel materiale del professore, decidere in quale delle tre categorie di
fattibilità TikZ cade, e — **solo dopo conferma esplicita dell'utente** —
scrivere il file `.status` corrispondente.

Non generi il corpo `.tex` della figura: questa skill si ferma alla
classificazione e alla creazione del `.status`. Il disegno vero viene fatto in
un passo successivo.

## Prima di iniziare

1. **Leggi `.claude/docs/gestione-figure.md`**: contiene i 5 test di
   fattibilità (da applicare **in ordine**, il primo "sì" decide), lo schema
   completo del file `.status`, e la struttura `figure/fig/<categoria>/`. È la
   fonte di verità di questa skill — non reinventare i criteri.
2. **Leggi `CLAUDE.md` (se presente)** per eventuali indicazioni specifiche del
   corso sulle categorie o sulle figure.
3. Individua **quale lezione** stai classificando: il prompt indicherà il file
   `lezioni/<nome>.tex` e le immagini del professore corrispondenti (di norma in
   `raw/_images/<nome>/`, prefisso `prof...`). Se non è indicato, chiedi.

## Passi

1. **Estrai gli ancoraggi.** Cerca tutte le occorrenze di
   `\figura{<chiave>}{<descrizione>}` nel `.tex` della lezione. Per ciascuna
   annota chiave e descrizione, nell'ordine in cui compaiono.

2. **Salta quelle già tracciate.** Se esiste già un file
   `figure/fig/<categoria>/<chiave>.status` per quella chiave, la figura è già
   stata classificata: non riclassificarla e segnalala come "già presente"
   nella tabella, senza toccarla (a meno che il prompt non chieda esplicitamente
   di riclassificare).

3. **Guarda il disegno originale.** Per ogni chiave rimasta, individua nel
   materiale **del professore** il disegno a cui l'ancoraggio si riferisce
   (usando la descrizione e la posizione nella lezione). La classificazione si
   basa su **cosa mostra il disegno del prof**, non sulla sola descrizione
   testuale: se non riesci a individuare con certezza il disegno di partenza,
   NON tirare a indovinare la fattibilità — segnalalo (vedi punto 5).

4. **Applica i 5 test in ordine** (da `gestione-figure.md`) e assegna una delle
   tre etichette: `non-conveniente`, `fattibile-da-verificare`, `facile`.
   Registra **quale test ha deciso** e una motivazione di una riga.

5. **Casi incerti.** Se non riesci a individuare il disegno originale, o la
   descrizione è ambigua, oppure non è chiaro se un disegno del prof esista
   davvero (potrebbe essere un ancoraggio inserito per prudenza), NON assegnare
   una fattibilità a caso: marca la riga come `?` e spiega il dubbio nella
   motivazione. Sarà l'utente a chiarire.

6. **Proponi la categoria strutturale.** Per ogni figura suggerisci anche la
   `<categoria>` (il tipo strutturale) sotto cui andrebbe il file, scegliendo
   tra quelle già definite in `\figuracategorie` in `preamble.tex`. Se nessuna
   calza, proponine una nuova segnalando che andrà aggiunta sia come cartella
   sia in `\figuracategorie`.

## Anteprima obbligatoria — conferma PRIMA di scrivere

**Non scrivere alcun file `.status` prima di aver mostrato la tabella di
anteprima e aver ricevuto conferma esplicita dell'utente.** Presenta una tabella
con una riga per figura:

| chiave | categoria proposta | fattibilità proposta | test | motivazione breve |
|--------|--------------------|----------------------|------|-------------------|
| composizione-funzioni | diagrammi-insiemistici | facile | 5 | tre insiemi e frecce, primitive esatte |
| ... | ... | fattibile-da-verificare | 4 | dipende da regioni campite |
| ... | ? | ? | — | disegno originale non individuato |

Sotto la tabella elenca esplicitamente:
- le figure marcate `?` con il dubbio da sciogliere;
- eventuali categorie nuove che andrebbero create;
- le figure saltate perché già dotate di `.status`.

Poi **fermati e chiedi conferma**. L'utente può correggere singole
classificazioni, chiedere di escludere una figura, o cambiare categoria. Applica
le correzioni e, se le modifiche sono sostanziali, ripresenta la tabella.

## Scrittura dei `.status` (solo dopo conferma)

Per ogni figura confermata (mai quelle rimaste `?` o escluse), scrivi
`figure/fig/<categoria>/<chiave>.status` con lo schema completo di
`gestione-figure.md`:

```
stato: mancante
fattibilita: <facile | fattibile-da-verificare | non-conveniente>
data: <YYYY-MM-DD odierna>
lezione-origine: <NN della lezione del prof>
riferimento-prof: <dove si trova il disegno, es. "pagina 4, in alto a destra">
note: <opzionale: la motivazione, o il test che ha deciso>
```

Nota:
- `stato:` è **sempre `mancante`** qui: questa skill classifica la fattibilità,
  non disegna nulla. Il `.tex` non esiste ancora, quindi nel PDF resta il
  bollino blu — coerente con `mancante`.
- NON creare il file `.tex` della figura né modificare il file della lezione.
- Se una categoria nuova è stata confermata, crea la cartella
  `figure/fig/<categoria>/` e ricorda all'utente di aggiungere la riga
  corrispondente in `\figuracategorie` in `preamble.tex` (senza quella riga
  `\figura` non cercherà mai in quella categoria).

Al termine, riepiloga quanti `.status` sono stati scritti e con quali
fattibilità, e ricorda che il prossimo passo (disegno + passaggio a
`generata`/`verificata`) è separato.
