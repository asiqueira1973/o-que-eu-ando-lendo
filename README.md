# O que eu ando lendo — Estante

App iOS para registrar leituras de forma rápida e colorida: livros com status, estrelas, comentários, metas por período, indicadores, exportação CSV e um cartão compartilhável "livro X do ano". **100% local, sem rede, sem login.**

- **Plataforma:** iOS 17+ (iPhone; roda no iPad sem layout dedicado).
- **Stack:** Swift · SwiftUI · SwiftData (local puro) · StoreKit 2 · `ImageRenderer`.
- **Fonte de verdade do produto:** [`spec_1.md`](spec_1.md). Arquitetura implementada: [`DOCUMENTACAO-TECNICA.md`](DOCUMENTACAO-TECNICA.md).

## Requisitos
- Xcode 16+ (validado no Xcode 26) e um Simulador iOS 17+.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.

## Setup e execução
O `.xcodeproj` é derivado do `project.yml` e **não** é versionado. Gere-o antes de abrir:

```bash
cd "O que eu ando lendo"
xcodegen generate
open Estante.xcodeproj
```

Rode pelo scheme **Estante** (▶). O scheme já aponta para `Estante.storekit`, então o Paywall e a compra funcionam em sandbox local, sem prompt de conta Apple.

Pela linha de comando:
```bash
xcodebuild -project Estante.xcodeproj -scheme Estante \
  -destination 'generic/platform=iOS Simulator' build
xcodebuild -project Estante.xcodeproj -scheme Estante \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
```

## Dados de exemplo (teste manual)
Para testar feed/Top 3/metas com volume, em builds **Debug**:

- **Pela UI:** aba **Configurações → "Popular dados de exemplo"** (e "Limpar tudo").
- **Ao abrir o app**, via variável de ambiente:
  ```bash
  SIMCTL_CHILD_ESTANTE_SEED=1 xcrun simctl launch booted com.dablab.estante
  ```
  `ESTANTE_SKIP_STOREKIT=1` (mesmo prefixo) pula o StoreKit ao rodar direto pelo `simctl` sem conta de sandbox. Ambas as flags são ignoradas em Release.

## Estrutura de pastas (`Sources/`)
`App` (entrada + navegação) · `ModeloDeDados` (SwiftData) · `Home` · `Livros` (cadastro/edição/detalhe) · `QueroLer` · `Metas` · `Exportar` · `Compra` (StoreKit) · `Configuracoes` · `Compartilhado` (componentes de UI, cálculos de período, foto, CSV, cartão).

`book-tracker-design-system/` guarda a referência visual (Claude Design) e **não** faz parte do target do app.

## Testes
Lógica pura (períodos, meta batida, trial, CSV, Top 3/posição) em `EstanteTests/` — 27 testes. Rode com o comando `xcodebuild test` acima ou `⌘U` no Xcode.
