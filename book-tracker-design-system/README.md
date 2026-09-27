# CODING AGENTS: READ THIS FIRST

> **Revisão de cores — 27/09/2026.** As CORES deste protótipo (fundo creme, textos
> marrons, coral como destaque, blocos e metas coloridos, lombadas vivas) estão
> **desatualizadas**. O app passou a uma paleta neutra padrão iOS: fundo `#F2F2F7`,
> cards brancos, azul `#007AFF` como única cor de destaque e lombadas em pastel.
> A fonte de verdade de cor é `Sources/Compartilhado/DesignTokens.swift` e a nota
> "Revisão de cores" na seção 16 do `spec.md`. Use este protótipo só para layout,
> espaçamento, tipografia e composição — nunca para cor.

This is a **handoff bundle** from Claude Design (claude.ai/design).

A user mocked up designs in HTML/CSS/JS using an AI design tool, then exported this bundle so a coding agent can implement the designs for real.

## What you should do — IMPORTANT

**Read `book-tracker-design-system/project/Estante Screens.dc.html` in full.** The user had this file open when they triggered the handoff, so it's almost certainly the primary design they want built. Read it top to bottom — don't skim. Then **follow its imports**: open every file it pulls in (shared components, CSS, scripts) so you understand how the pieces fit together before you start implementing.

**If anything is ambiguous, ask the user to confirm before you start implementing.** It's much cheaper to clarify scope up front than to build the wrong thing.

## About the design files

The design medium is **HTML/CSS/JS** — these are prototypes, not production code. Your job is to **recreate them pixel-perfectly** in whatever technology makes sense for the target codebase (React, Vue, native, whatever fits). Match the visual output; don't copy the prototype's internal structure unless it happens to fit.

**Don't render these files in a browser or take screenshots unless the user asks you to.** Everything you need — dimensions, colors, layout rules — is spelled out in the source. Read the HTML and CSS directly; a screenshot won't tell you anything they don't.

## Bundle contents

- `book-tracker-design-system/README.md` — this file
- `book-tracker-design-system/project/` — the `Book Tracker Design System` project files (HTML prototypes, assets, components)
