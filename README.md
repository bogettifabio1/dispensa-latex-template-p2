# dispensa-latex-template

**Turn university lectures into clean LaTeX notes, with the help of Claude Code.**

A template for transcribing a course into LaTeX, starting from your professor's
material (slide / lecture-note PDFs) and your own notes. Each lecture becomes a
ready-made `.tex` fragment. Anything uncertain, and every missing drawing, is
**flagged for review** instead of silently guessed, so you never have to
re-read the whole lecture from scratch.

## Contents

- [How it works](#how-it-works)
- [Before you start](#before-you-start)
- [Important notes: privacy, copyright, status](#important-notes-privacy-copyright-status)
- [Installation](#installation) — Windows or macOS
- [Verify your setup](#verify-your-setup)
- [Workflow](#workflow)
- [Tips](#tips)
- [Troubleshooting](#troubleshooting)
- [Project structure](#project-structure)
- [Feedback](#feedback)

---

## How it works

You copy this skeleton once per course. Two bootstrap skills do the setup for
you, then you add lectures one at a time:

```
 1. /course-setup         2. /professor-profile        3. transcribe a lecture        4. review
 ───────────────────      ────────────────────────     ──────────────────────────     ─────────────────
 Short interview:         Analyzes 2–4 sample          new_lecture script →           Fix the red and
 how is the course        lectures to learn the        Claude writes the .tex →       blue markers, then
 material organized?      professor's NOTATION.        PDF is compiled.               repeat for the next
 (once per course)        (once per course)            (once per lecture)             lecture.
```

- `/course-setup` finds out **how your material is organized** (complete
  slides? skeleton slides annotated in class? blackboard? only your own
  notes?) and configures the pipeline accordingly.
- `/professor-profile` finds out **which notation** the professor uses.
- Together they fill in `CLAUDE.md`, the file Claude Code reads automatically
  (the rest of that file already contains the ready-made system rules).

This repository is a public GitHub **template repository**. It contains no
course material, only the skeleton. Press **Use this template ▸ Create a new
repository** (see [Download the project](#5-download-the-project)) to get your
own independent copy, with no commit history and no link to the original (it is
not a fork and has no upstream). Make it **private**: that is where the notes
for one subject will live.

## Before you start

You need:

- A **paid Claude subscription** (Pro, Max, Team or Enterprise). The free plan is
  not enough: Claude Code will not start without a paid subscription.
- About 30 minutes and a few GB of free disk space.
- Windows 10 (1809+) / Windows 11, **or** macOS Big Sur 11 or newer.

| System | Status |
|---|---|
| 🪟 **Windows** | Tested. Uses the `.ps1` scripts. |
| 🍎 **macOS** | The `.sh` scripts exist but have **never been tested on a Mac**, and the Mac install guide is unverified. Your feedback is very valuable. |
| 🐧 **Linux** | The same `.sh` scripts should work, but there is no dedicated install guide. |

> **You do not need to have used a terminal before.** Follow the steps in order.

## Important notes: privacy, copyright, status

> **Amateur, experimental project.** Built to transcribe the notes of a single
> course and offered as-is, with no warranty. It may have rough edges; please
> tell us about them (see [Feedback](#feedback)).

- **What is sent to Anthropic.** To transcribe, Claude Code reads the page images
  of your PDFs (the professor's slides, your notes) and processes them on
  Anthropic's servers. Do not use it on material you cannot share with an
  external service.
- **Material and copyright.** The PDFs in `raw/` stay on your computer only (git
  ignores them). The notes you produce are a transcription of the professor's
  content. The template is MIT-licensed and contains no course material:
  whoever uses it is solely responsible for the material they put into it and
  for how they distribute it.

> ⚠️ **Never make the repository of a subject public.** This empty template can
> be public; your copy with the lectures in it must not. It contains (or will
> contain) lectures transcribed from the professor's material, plus `CLAUDE.md`
> with their profile. That content is copyrighted, and any takedown request
> would be addressed to you.
>
> - Do not remove `raw/` from `.gitignore` and do not use `git add -f` on PDFs.
> - Commits contain your email address. To avoid exposing it, enable **"Keep my
>   email addresses private"** on GitHub and use your
>   `…@users.noreply.github.com` address as `git config --global user.email`.
> - To check the status at any time, run `.\scripts\check_setup.ps1` (Windows) or
>   `./scripts/check_setup.sh` (Mac). It warns you if `raw/` is not ignored or
>   contains tracked files.

---

## Installation

You will install, in this order:

| Tool | What it is for |
|---|---|
| **VS Code** | The editor where you will work. |
| **Git** | Downloads the project. |
| **Claude Code** | The AI assistant that does the transcription. |
| **A LaTeX distribution** | Compiles the PDF. **MiKTeX** on Windows, **MacTeX** on Mac. |
| **`pdftoppm`** | Converts the professor's PDFs into images. It comes with MiKTeX on Windows; on Mac you install it separately (**Poppler**). |

Open the section for your system and follow the steps in order.

<details>
<summary><b>🪟 Windows (10 / 11)</b> — click to expand</summary>

### 1. VS Code

Download it from <https://code.visualstudio.com> (blue button), open the
installer and click Next until the end, leaving the suggested options. Then open
**Visual Studio Code** from the Start menu.

### 2. Git

Download it from <https://git-scm.com/downloads/win>, open the installer and
click Next on every screen, leaving the defaults. This also installs "Git Bash",
which Claude Code uses internally.

### 3. Claude Code

1. Open **PowerShell** (Start → type `PowerShell`).
2. Paste and run:
   ```powershell
   irm https://claude.ai/install.ps1 | iex
   ```
3. Close and reopen PowerShell, then check:
   ```powershell
   claude --version
   ```
   It must print a version number. If it says "command not recognized", close
   and reopen the terminal again.
4. First launch: type `claude` and log in through the browser with the account
   **that has the paid subscription**. To quit: `/exit`.

### 4. MiKTeX

1. Download the MiKTeX Installer from <https://miktex.org/download>.
2. During installation choose **"Install MiKTeX only for me"** and, when asked
   "Install missing packages on the fly", choose **"Yes"** (MiKTeX will download
   missing packages by itself on the first compilation).
3. Open **MiKTeX Console** and, if offered, run **Check for updates → Update now**.
4. Close and reopen PowerShell, then check:
   ```powershell
   latexmk --version
   pdftoppm -v
   ```
   If they are not recognized, restart the PC (this loads the PATH) and try again.

### 5. Download the project

Recommended: create **your own copy** of the template, so you have a place of
your own to store your notes.

1. With a GitHub account, open
   <https://github.com/bogettifabio1/dispensa-latex-template-p2> and press
   **Use this template ▸ Create a new repository**. Choose **Private**: your
   notes contain the professor's content.
2. Clone **your** copy (replace `YOUR-USER/YOUR-REPO`):

```powershell
cd $HOME\Desktop
git clone https://github.com/YOUR-USER/YOUR-REPO.git
```

*Alternatives:* you can clone the original repository directly
(`git clone https://github.com/bogettifabio1/dispensa-latex-template-p2.git`) or,
with no GitHub account and no Git, use **Code ▸ Download ZIP** on the template
page. Both work the same, but you will have no online backup of your notes and,
to receive future improvements, you will have to ask Claude Code to port them by
hand (see [Tips](#tips)).

### 6. Open the project and unlock the scripts

1. In VS Code: **File ▸ Open Folder…** and choose the downloaded folder.
2. Open a **PowerShell** terminal inside VS Code (**Terminal ▸ New Terminal**).
3. Once only, unlock script execution for the project (Windows blocks scripts by
   default):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
   Confirm with `Y`. This allows scripts you downloaded yourself, without
   lowering security for those fetched from the internet.

</details>

<details>
<summary><b>🍎 macOS (Big Sur 11+, Intel and Apple Silicon)</b> — click to expand</summary>

> This guide is **not verified on a real Mac**. If something does not work, please
> tell us (see [Feedback](#feedback)).

On Mac, almost everything is installed with **Homebrew**, the command-line
package manager.

### 1. Terminal and Homebrew

1. Open **Terminal** (⌘+Space, type `Terminal`, Enter).
2. Install Homebrew by pasting:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   At the end it may ask you to run two `echo … >> ~/.zprofile` lines to add
   `brew` to your PATH: run them as instructed. Then check:
   ```bash
   brew --version
   ```

### 2. VS Code and Git

```bash
brew install --cask visual-studio-code
brew install git
```

### 3. Claude Code

1. Install:
   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```
2. Close and reopen Terminal, then check:
   ```bash
   claude --version
   ```
   If it says "command not found", close and reopen Terminal again.
3. First launch: type `claude` and log in through the browser with the account
   **that has the paid subscription**. To quit: `/exit`.

### 4. MacTeX and Poppler

```bash
brew install --cask mactex-no-gui
brew install poppler
```

`mactex-no-gui` is large (a few GB): the first install takes patience. Poppler
provides `pdftoppm`, which is **not** included in MacTeX. Close and reopen
Terminal, then check:

```bash
latexmk --version
pdftoppm -v
```

If they are not recognized, close and reopen Terminal (this reloads the PATH)
and try again.

### 5. Download the project

Recommended: create **your own copy** of the template, so you have a place of
your own to store your notes.

1. With a GitHub account, open
   <https://github.com/bogettifabio1/dispensa-latex-template-p2> and press
   **Use this template ▸ Create a new repository**. Choose **Private**: your
   notes contain the professor's content.
2. Clone **your** copy (replace `YOUR-USER/YOUR-REPO`):

```bash
cd ~/Desktop
git clone https://github.com/YOUR-USER/YOUR-REPO.git
```

*Alternatives:* you can clone the original repository directly
(`git clone https://github.com/bogettifabio1/dispensa-latex-template-p2.git`) or,
with no GitHub account and no Git, use **Code ▸ Download ZIP** on the template
page. Both work the same, but you will have no online backup of your notes and,
to receive future improvements, you will have to ask Claude Code to port them by
hand (see [Tips](#tips)).

### 6. Open the project and make the scripts executable

1. In VS Code: **File ▸ Open…** and choose the downloaded folder.
2. Open a terminal inside VS Code (**Terminal ▸ New Terminal**).
3. Once only, make the project scripts executable:
   ```bash
   chmod +x scripts/*.sh
   ```

</details>

---

## Verify your setup

Before you begin, check everything in one go. The script changes nothing: for
each tool it says **OK**, or **what is missing and how to install it**.

<details>
<summary>🪟 Windows</summary>

```powershell
.\scripts\check_setup.ps1
```

</details>

<details>
<summary>🍎 macOS / 🐧 Linux</summary>

```bash
./scripts/check_setup.sh
```

</details>

If anything is listed as missing, follow the hint next to it, close and reopen
the terminal, and run the script again until everything is **OK**. This way you
avoid discovering a missing piece halfway through your first lecture.

---

## Workflow

> 💡 **You don't have to memorize or type the commands below.** You can open
> `claude` and describe what you want in plain language, for example *"start
> analyzing the professor's notation by running the right command"* or
> *"transcribe lecture 1 from raw/prof/lecture1.pdf"*. Claude Code reads this
> README and the scripts in `scripts/`, works out which command to run and with
> which arguments, and runs it for you in the integrated terminal.

**Windows or Mac?** Every command below is shown in both forms; open the one for
your system. Both do the same thing, only the option syntax differs:

| | 🪟 Windows (`.ps1`) | 🍎 Mac / Linux (`.sh`) |
|---|---|---|
| Script | `.\scripts\new_lecture.ps1` | `./scripts/new_lecture.sh` |
| Option style | `-Prof`, `-Mine`, … | `--prof`, `--mine`, … |
| Several files | separated by **commas**, each in quotes | separated by **spaces** |
| Line continuation | backtick `` ` `` | backslash `\` |

**The options** (the names are Italian because they are the actual flags of the
scripts; the English meaning is in the last column):

| Windows | Mac / Linux | Meaning |
|---|---|---|
| `-Prof` | `--prof` | The professor's PDF(s) (the source of truth). |
| `-Mine` | `--mine` | Your own notes (PDF). |
| `-Annotata` | `--annotata` | The professor's *annotated* slides (model M2 only). |
| `-Vergine` | `--vergine` | The professor's *blank / clean* slides (model M2 only). |
| `-SenzaNote` | `--senza-note` | Proceed without personal notes (*"no notes"*). |
| `-SoloRaster` | `--solo-raster` | Only convert PDFs to images, do not transcribe (*"raster only"*). |

### Step 1. Put the PDFs in place

Copy the professor's PDFs into `raw/prof/` (*prof* = professor) and your scanned
notes (if any) into `raw/mine/` (*mine* = your own). Git ignores them: they stay
on your computer only.

### Step 2. Course material model (once per course)

Before transcribing any lecture, let Claude Code understand **how the material of
this course is organized**. Open `claude` and run:

```
/course-setup
```

It is a short, adaptive interview (it skips questions that don't apply to your
case) and writes the result — only after your confirmation — into the "Modello
del materiale" section (*"material model"*) of `CLAUDE.md`. The answers normally fall into one of
these 4 models, which also decide **which flags** to use in Step 4:

| Model | Professor's material | Flags to use |
|---|---|---|
| **M1** — complete slides | Self-contained PDFs, little or no annotation | `--prof` + `--mine` (without notes: `--senza-note`) |
| **M2** — annotated skeleton slides | Long slides completed in class; one lecture may span several sets | `--annotata` + `--vergine` (+ `--mine`) |
| **M3** — blackboard / handwritten | No slides, everything handwritten and photographed/scanned | `--prof` (images read visually) + `--mine` |
| **M4** — own notes only | The professor distributes nothing | only `--mine`, which becomes the source of truth |

(Flags are shown in Mac/Linux style; on Windows use the equivalents from the
table above.) You only redo this if the course or the professor changes, not for
every lecture. If you skip it, the pipeline falls back to the M1 default
(`--prof` / `--mine`).

### Step 3. Professor profile (once per course)

Turn 2–4 sample lectures into images, under a single name:

<details>
<summary>🪟 Windows</summary>

```powershell
.\scripts\new_lecture.ps1 profile-sample -SoloRaster `
    -Prof "raw/prof/lecture1.pdf","raw/prof/lecture2.pdf","raw/prof/lecture3.pdf"
```

</details>

<details>
<summary>🍎 macOS / 🐧 Linux</summary>

```bash
./scripts/new_lecture.sh profile-sample --solo-raster \
    --prof "raw/prof/lecture1.pdf" "raw/prof/lecture2.pdf" "raw/prof/lecture3.pdf"
```

</details>

Then open `claude` and paste this prompt (adapting the course name):

```
/professor-profile

Sample to analyze: all the images in raw/_images/profile-sample/
(prefixes prof1_, prof2_, ...). Course: <course name>.
```

Claude analyzes the images, shows a table of what it understood and **waits for
your confirmation** before writing to `CLAUDE.md`. From then on it transcribes
using your professor's conventions.

> **Model M2:** sample the **blank** slides (use `-Vergine` / `--vergine` instead
> of `-Prof` / `--prof` in the command above), not the annotated copy: that is
> where the typographic notation is clearest.
>
> **Model M4** (own notes only): there is no professor material to profile. The
> skill notices this by itself, explains it and stops. Just skip this step.

### Step 4. Transcribe a lecture

The command depends on the model identified in Step 2. The first argument
(`lecture01` below) is just a name of your choice for the lecture.

#### M1 / M3 — complete slides or blackboard (the professor is the source of truth)

With your own notes covering the same lecture:

<details>
<summary>🪟 Windows</summary>

```powershell
.\scripts\new_lecture.ps1 lecture01 -Prof "raw/prof/lecture1.pdf" -Mine "raw/mine/my-notes-lec1.pdf"
```

</details>

<details>
<summary>🍎 macOS / 🐧 Linux</summary>

```bash
./scripts/new_lecture.sh lecture01 --prof "raw/prof/lecture1.pdf" --mine "raw/mine/my-notes-lec1.pdf"
```

</details>

**Without personal notes** (valid for M1, M2 and M3). If you pass no
`-Mine` / `--mine`, the script stops and warns you that your notes are missing
(they normally enrich the transcription with what the professor says out loud).
If you still want to transcribe from the professor's material alone, run the same
command again adding `-SenzaNote` (Windows) or `--senza-note` (Mac):

<details>
<summary>🪟 Windows</summary>

```powershell
.\scripts\new_lecture.ps1 lecture01 -Prof "raw/prof/lecture1.pdf" -SenzaNote
```

</details>

<details>
<summary>🍎 macOS / 🐧 Linux</summary>

```bash
./scripts/new_lecture.sh lecture01 --prof "raw/prof/lecture1.pdf" --senza-note
```

</details>

If you launch it through Claude Code, it will relay the warning to you.

#### M2 — annotated skeleton slides

Requires `-Annotata` / `--annotata` **and** `-Vergine` / `--vergine` together,
with the blank decks listed in the order the lecture goes through them:

<details>
<summary>🪟 Windows</summary>

```powershell
.\scripts\new_lecture.ps1 lecture05 `
    -Annotata "raw/prof/lec05_annotated.pdf" `
    -Vergine "raw/prof/deckA.pdf","raw/prof/deckB.pdf" `
    -Mine "raw/mine/my-notes-lec5.pdf"
```

</details>

<details>
<summary>🍎 macOS / 🐧 Linux</summary>

```bash
./scripts/new_lecture.sh lecture05 \
    --annotata "raw/prof/lec05_annotated.pdf" \
    --vergine "raw/prof/deckA.pdf" "raw/prof/deckB.pdf" \
    --mine "raw/mine/my-notes-lec5.pdf"
```

</details>

Before transcribing, the script builds an annotated↔blank **coverage map**
(`align/lecture05/coverage.json`, see `scripts/align_slides.sh`). **Review it** —
especially the pages that were "inserted" by hand and the low-confidence ones —
before trusting the result.

#### M4 — own notes only

No professor material, only `-Mine` / `--mine`:

<details>
<summary>🪟 Windows</summary>

```powershell
.\scripts\new_lecture.ps1 lecture01 -Mine "raw/mine/my-notes-lec1.pdf"
```

</details>

<details>
<summary>🍎 macOS / 🐧 Linux</summary>

```bash
./scripts/new_lecture.sh lecture01 --mine "raw/mine/my-notes-lec1.pdf"
```

</details>

Here your notes are the only source and are treated as such: there is no
comparison against professor material that does not exist.

#### What the script does

In every case the script converts the PDFs to images (and, for M2 only, aligns
them), calls Claude to transcribe, and — if the lecture is already included in
`master.tex` — compiles the PDF.

### Step 5. Add the lecture and compile

This step is **automatic**: `new_lecture` hooks the newly transcribed lecture
into `master.tex` by itself (it appends `\input{lezioni/lecture01}` after the
lectures already there; `lezioni/` is the folder holding one `.tex` file per
lecture) and then compiles, producing `master.pdf`, which you can
open in VS Code.

Only two things to keep in mind:

- **The very first lecture of the course.** Since there are no lectures yet, the
  script inserts it but warns you to check that it ends up **under the right
  `\chapter{}`** (you decide the chapter organization in `master.tex`; see the
  comments there).
- **Recompiling by hand**, when needed (e.g. after fixing a marker):

  ```
  latexmk master.tex
  ```

### Step 6. Read the markers and fix them

- 🔴 **Red** (`\revisione`, *"review"*): Claude was not sure about a formula or a
  step. Check the original material and correct the `.tex`.
- 🔵 **Blue** (`\figura`, *"figure"*): a drawing by the professor to insert by
  hand — see `.claude/docs/gestione-figure.md` (*"figure management"*).

Red markers are not errors to hide: they are honest warnings. Better one marker
too many than a wrong formula disguised as text.

---

## Tips

- Readable input material = fewer red markers in the output.
- Do `/course-setup` first, then the professor profile, then the lectures. Skipping
  them makes Claude transcribe with the wrong flags or with "random" notation, and
  you lose more time correcting it later.
- One lecture at a time: check and fix the markers before moving to the next.
- Don't fix page layout while writing: only when the notes are complete (see
  `CLAUDE.md`).
- The template may receive improvements: check the project's GitHub page from time
  to time. Because your copy comes from "Use this template", it is not linked to the
  original, so updating it is **not automatic** (you have modified `CLAUDE.md`,
  `master.tex`, `lezioni/`). If there is a new feature you need, ask Claude Code
  to port it into your copy without touching your material.

---

## Troubleshooting

| Symptom | What to do |
|---|---|
| `claude` "not recognized" | Close and reopen the terminal; if it persists, restart the PC. |
| `perl` "not recognized" when running `latexmk` | Install perl from <https://www.perl.org/get.html>. |
| `latexmk` / `pdftoppm` "not recognized" (Windows) | Restart the PC (loads the MiKTeX PATH) and try again. |
| `pdftoppm: command not found` (Mac) | Poppler is missing: `brew install poppler`, then reopen Terminal. |
| The `.ps1` script is blocked (Windows) | Installation step 6.3 is missing (`Set-ExecutionPolicy … RemoteSigned`). |
| `./scripts/….sh: Permission denied` (Mac) | Installation step 6.3 is missing: `chmod +x scripts/*.sh`. |
| Claude Code asks for login and won't start | A paid subscription is required; the free plan is not enough. |
| The first compilation hangs or asks for packages | MiKTeX is downloading missing packages: accept and wait. |
| The blue marker stays even after creating the figure | Recompile with `latexmk -g -pdf master.tex` (once per new figure). |

To see at a glance what is missing among the template's tools, run
`.\scripts\check_setup.ps1` (Windows) or `./scripts/check_setup.sh` (Mac). For a
check dedicated to Claude Code: `claude doctor`.

---

## Project structure

> Some folder, file and macro names are in Italian because the scripts and
> `CLAUDE.md` rely on them. **Do not rename them**, or the scripts will stop
> working. Translations are given below.

| Italian name | English meaning |
|---|---|
| `lezioni/` | lectures |
| `figure/fig/` | figures (drawings) |
| `raw/prof/`, `raw/mine/` | professor's material, your own notes |
| `\revisione`, `\figura` | "review" marker, "figure" marker |
| `gestione-figure.md` | figure management guide |
| "Modello del materiale" | material model (section of `CLAUDE.md`) |
| "Profilo del professore" | professor profile (section of `CLAUDE.md`) |

- `master.tex` — main file: title, indexes, list of lectures.
- `preamble.tex` — packages, notation, environments (normally left untouched).
- `CLAUDE.md` — course conventions, read automatically by Claude Code.
- `lezioni/` — one `.tex` file per lecture.
- `figure/fig/` — the drawings, divided by category.
- `raw/prof/`, `raw/mine/` — your source PDFs (they stay on your computer only,
  not versioned).
- `align/` — model M2 only: annotated↔blank coverage maps generated by
  `align_slides.{sh,ps1}` (ignored by git, regenerated for every M2 lecture).
- `scripts/` — `.ps1` for Windows, `.sh` for Mac/Linux.
- `.claude/skills/`, `.claude/docs/` — the skills (`/course-setup`,
  `/professor-profile`, `/lecture-transcribe`, `/figure-classify`) and the
  internal documentation.

---

## Feedback

The project is young and every bit of feedback helps, however small. Please open
an **Issue** on the project's GitHub page — nothing formal is needed, a couple of
lines are enough.

What we care about most:

- Did you manage to install everything following the README alone? Where did you
  get stuck?
- How long did it take from download to your first transcribed lecture?
- How many red markers (`\revisione`) did you find in a lecture, and how many were
  real errors?
- What kind of material does your course have (slides, blackboard, notes only)?
  Did the M1–M4 model chosen by `/course-setup` feel right?
- What confused you, what would you remove, what did you expect that wasn't
  there?
