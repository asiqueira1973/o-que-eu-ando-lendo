# O que eu ando lendo

App iOS para registrar leituras: livros com status, estrelas e comentários, metas por período, exportação em CSV e um cartão para compartilhar "livro X do ano". Codinome técnico do projeto: **Estante**.

[Baixar na App Store](https://apps.apple.com/br/app/o-que-eu-ando-lendo/id6797134959)

<p>
  <img src="prints%20pra%20loja/appstore/01-estante.png" width="180" alt="Estante">
  <img src="prints%20pra%20loja/appstore/02-compartilhar.png" width="180" alt="Compartilhar">
  <img src="prints%20pra%20loja/appstore/03-metas.png" width="180" alt="Metas">
  <img src="prints%20pra%20loja/appstore/04-meta-batida.png" width="180" alt="Meta batida">
  <img src="prints%20pra%20loja/appstore/05-registrar.png" width="180" alt="Registrar livro">
</p>

## Principais funcionalidades

- Cadastro de livro com título, autor, editora, foto da capa (opcional), status (quero ler / lendo / lido), estrelas, comentário e quem indicou.
- Home com livros lidos no mês e no ano, "lendo agora", Top 3 do ano e feed de lidos.
- Biblioteca com filtro por status, incluindo a lista de "quero ler" com quem indicou.
- Metas de leitura por mês, trimestre, semestre ou ano, com celebração quando a meta é batida.
- Cartões em formato stories (9:16) gerados no aparelho: "livro X do ano", meta batida e recomendação para um amigo.
- Exportação em CSV por período e importação de um CSV exportado como backup.
- 100% local: sem rede, sem login, sem nuvem.
- Grátis até 5 livros; compra única desbloqueia registros ilimitados.

## Stack técnica

- Swift + SwiftUI, iOS 17+ (iPhone; roda no iPad sem layout dedicado)
- SwiftData (armazenamento local)
- StoreKit 2 (compra única não-consumível)
- `ImageRenderer` (cartões de compartilhar), `PhotosPicker` (foto)
- XcodeGen (`project.yml` gera o projeto Xcode)
- XCTest (testes unitários)

## Como foi construído

Desenvolvido com Claude (Anthropic) a partir de uma especificação SDD: [spec.md](spec.md). A spec define princípios, modelo de dados, regras de negócio, critérios de aceite e um protocolo de mudanças incrementais; o sistema como implementado está descrito em [DOCUMENTACAO-TECNICA.md](DOCUMENTACAO-TECNICA.md).

- Testes unitários em [`EstanteTests/`](EstanteTests/) cobrem a lógica pura: cálculo de períodos, meta batida, limite do período grátis, Top 3/posição, exportação e importação de CSV e restauração de backup.
- A referência visual partiu de um protótipo no Claude Design ([`book-tracker-design-system/`](book-tracker-design-system/)), que não faz parte do target do app.
- Modelo de dados em [`modelo-estante.dbml`](modelo-estante.dbml).

## Status

Publicado na App Store (iOS).

## Licença

O código está disponível apenas para leitura e estudo. Veja [LICENSE](LICENSE).

## Contribuições

Issues são bem-vindas; pull requests não são aceitos. Veja [CONTRIBUTING.md](CONTRIBUTING.md).

## Como rodar

Requisitos: Xcode 16+ (validado no Xcode 26), Simulador iOS 17+ e [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

O `.xcodeproj` é derivado do `project.yml` e não é versionado. Gere-o antes de abrir:

```bash
xcodegen generate
open Estante.xcodeproj
```

Rode pelo scheme **Estante**. O scheme aponta para `Estante.storekit`, então o Paywall e a compra funcionam em sandbox local.

Pela linha de comando:

```bash
xcodebuild -project Estante.xcodeproj -scheme Estante \
  -destination 'generic/platform=iOS Simulator' build
xcodebuild -project Estante.xcodeproj -scheme Estante \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
```

### Dados de exemplo (só em Debug)

- Pela UI: **Configurações → "Popular dados de exemplo"** (e "Limpar tudo").
- Ao abrir o app, via variável de ambiente:
  ```bash
  SIMCTL_CHILD_ESTANTE_SEED=1 xcrun simctl launch booted com.dablab.estante
  ```
  `ESTANTE_SKIP_STOREKIT=1` (mesmo prefixo) pula o StoreKit ao rodar pelo `simctl` sem conta de sandbox. As flags são ignoradas em Release.

### Estrutura de pastas (`Sources/`)

`App` (entrada e navegação) · `ModeloDeDados` (SwiftData) · `Home` · `Livros` (cadastro, edição, detalhe) · `Biblioteca` · `Metas` · `Exportar` (CSV e backup) · `Compra` (StoreKit) · `Configuracoes` · `Compartilhado` (componentes de UI, cálculos de período, foto, CSV, cartões).

---

Feito pela [Dab Lab](https://www.dablab.com.br/) — product studio de software e IA que constrói apps para pequenas empresas, startups e áreas dentro de grandes empresas, partindo de uma especificação (Spec-Driven Development) e com as disciplinas de engenharia de software robusta.
