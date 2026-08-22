# Documentação técnica — "O que eu ando lendo" (codinome técnico: Estante)

Documento gerado ao fim da implementação, descrevendo o sistema **como foi de fato construído** (spec seção 19). App iOS 17+ em Swift/SwiftUI + SwiftData, 100% local (sem rede, sem login, sem CloudKit), compra única via StoreKit 2.

- **Stack:** SwiftUI, SwiftData (armazenamento local puro), StoreKit 2, `ImageRenderer` (cartão), `PhotosPicker`/`UIImagePickerController` (foto).
- **Projeto:** XcodeGen (`project.yml` é a fonte de verdade; `.xcodeproj` fica no `.gitignore`). Bundle `com.dablab.estante`, team `XGZW6Y6K25`.
- **Convenção de idioma:** a camada de persistência (classes `@Model`, propriedades e enums) é em **português** — nomes de coluna em `snake_case` exatamente como a seção 7 do spec; todo o resto do código (views, view models, helpers, structs) é em **inglês** (spec 18).

---

## 1. Modelo de dados (SwiftData)

Duas entidades independentes em `Sources/ModeloDeDados/`. Toda propriedade tem valor default e nenhuma usa `@Attribute(.unique)` — disciplina que mantém barata uma futura migração para CloudKit (spec 24/28); as unicidades são validadas em código.

### Tabela `livros` — `Livro.swift`
Registro de um livro do usuário (quero ler / lendo / lido).

| Campo (coluna) | Tipo Swift | Significado de negócio |
|---|---|---|
| `id` | `UUID` | Chave primária; também define a cor determinística da lombada. |
| `titulo` | `String` | Título — único campo obrigatório no cadastro. |
| `autor` | `String?` | Autor (opcional). |
| `editora` | `String?` | Editora (opcional). |
| `foto_arquivo` | `String?` | Nome do arquivo da capa em `Application Support/Fotos/`; nulo → lombada colorida. |
| `status` | `status_livro` | Estado de leitura (default `quero_ler`). |
| `avaliacao_estrelas` | `Int?` | 1–5; opcional mesmo com status `lido`. |
| `comentario` | `String?` | Comentário livre. |
| `indicado_por` | `String?` | Quem indicou (relevante em "quero ler"). |
| `data_inicio_leitura` | `Date?` | Início da leitura. |
| `data_conclusao` | `Date?` | Preenchida com hoje ao virar `lido`; limpa ao sair de `lido`. |
| `criado_em` | `Date` | Criação do registro (desempate de posição do cartão). |
| `atualizado_em` | `Date` | Última edição. |

### Tabela `metas` — `Meta.swift`
Meta de leitura por período.

| Campo (coluna) | Tipo Swift | Significado de negócio |
|---|---|---|
| `id` | `UUID` | Chave primária. |
| `tipo_periodo` | `tipo_periodo_meta` | Mensal / trimestral / semestral / anual. |
| `ano` | `Int` | Ano de referência (ex.: 2026). |
| `numero_periodo` | `Int?` | 1–12 (mensal), 1–4 (trimestral), 1–2 (semestral), nulo (anual). |
| `quantidade_alvo` | `Int` | Alvo de livros no período (validado > 0). |
| `meta_atingida_em` | `Date?` | Marcada na 1ª vez que a meta é batida; nunca regride. |
| `criado_em` / `atualizado_em` | `Date` | Auditoria simples. |

### Enums — `Enums.swift`
- `status_livro`: `quero_ler`, `lendo`, `lido`.
- `tipo_periodo_meta`: `mensal`, `trimestral`, `semestral`, `anual`.

Ambas são `String`-backed (o `rawValue` persistido coincide com o nome snake_case).

---

## 2. Relacionamento entre as tabelas

**Não há chave estrangeira** entre `livros` e `metas` — são independentes por design (spec 7.1). O progresso de uma meta é **recalculado em tempo real** contando os livros com `status = lido` e `data_conclusao` dentro do intervalo do período da meta (`GoalEvaluator.progresso` → `PeriodCalculator.countLidos`). Consequência declarada: excluir um livro depois pode fazer a contagem exibida de uma meta cair, mas o selo "meta batida" (`meta_atingida_em`) não é desfeito.

O `ModelContainer` (`ContainerModelo.swift`) usa `ModelConfiguration` **local puro** (sem `cloudKitDatabase`) — nenhuma chamada de rede.

---

## 3. Lógica que roda fora da UI (`Sources/Compartilhado/`)

Toda pura e testável (27 testes em `EstanteTests/`).

| Rotina | Arquivo | O que faz / o que dispara |
|---|---|---|
| Cálculo de períodos | `PeriodCalculator.swift` | Intervalos `[início, fim)` de mês/trimestre/semestre/ano no `Calendar.current`; trimestre (Q1–Q4), semestre (S1–S2); `countLidos` conta lidos no período, com clamp "até hoje" para os indicadores. |
| Top 3 e posição no cartão | `ReadingStats.swift` | Top 3 do ano (estrelas desc, empate por data desc, ignora sem nota); posição X do livro no período (data asc, empate `criado_em` asc). |
| Meta batida | `GoalEvaluator.swift` | Ao salvar um livro `lido`, decide quais metas foram batidas pela 1ª vez (só `meta_atingida_em == nil`, período contém a data, contagem ≥ alvo). Disparado em `BookFormViewModel.salvar`. |
| Trial | `TrialGate.swift` | Decide se criar um livro novo precisa passar pelo Paywall (≥ 5 e sem compra). Chamado em `BookFormViewModel.salvar` (só para livro novo). |
| Foto | `PhotoStorage.swift` | Redimensiona (≤1200px) + comprime (JPEG ~0.7) e grava em `Application Support/Fotos/`; devolve o nome do arquivo. Em falha de disco, salva o livro sem foto com aviso (spec 12). |
| CSV (exportar) | `CSVExporter.swift` | Gera o CSV (UTF-8 com BOM, separador `;`, colunas/ordem/nome de arquivo da seção 14). Chamado por `ExportViewModel`. |
| CSV (importar/restaurar) | `Exportar/CSVImporter.swift` + `Exportar/BackupRestore.swift` | Lê um CSV exportado (parser RFC 4180 sobre Unicode.Scalar, para o `\r\n` não virar um único grapheme) e **sobrescreve o banco**: apaga livros + metas + fotos órfãs e recria os livros como `lido` (spec 14). Disparado nas Configurações com confirmação explícita. |
| Cores/lombadas | `DesignTokens.swift` | Paleta e cor determinística por `id` do livro (`BookColor.color(for:)`). |

---

## 4. Mapa tela → dados

| Tela (arquivo) | Lê | Escreve |
|---|---|---|
| Home (`Home/HomeView.swift` + `HomeViewModel`) | `livros` | — |
| Cadastrar/Editar (`Livros/BookFormView.swift` + `BookFormViewModel`) | `livros`, `metas` | `livros`, `metas` (`meta_atingida_em`) |
| Detalhe (`Livros/BookDetailView.swift`) | `livros` | `livros` (exclusão) |
| Biblioteca (`Biblioteca/BibliotecaView.swift`) | `livros` | `livros` (atalho "Comecei a ler") |
| Metas (`Metas/GoalsView.swift` + `GoalFormView` + `GoalsViewModel`) | `metas`, `livros` | `metas` |
| Meta batida (`Metas/GoalReachedView.swift`) | `livros` | — |
| Exportar (`Exportar/ExportView.swift` + `ExportViewModel`) | `livros` | — (só arquivo temporário) |
| Cartão (`Compartilhado/ShareCardView.swift`) | `livros`, `metas` | — (só imagem temporária) |
| Paywall (`Compra/PaywallView.swift` + `StoreManager`) | StoreKit | — (entitlement fica no StoreKit, não no banco) |
| Configurações (`Configuracoes/SettingsView.swift`) | StoreKit, `livros`/`metas` (só ao importar backup) | `livros`, `metas` (sobrescrita na importação de CSV) |

---

## 5. Lógica por tela (o que valida / salva / calcula)

- **Cadastrar/Editar (8.1/8.2/8.3):** valida só título obrigatório; ao trocar status aplica a regra de `data_conclusao` (preenche/limpa); ao salvar, roda o trial (só p/ livro novo) e a verificação de meta batida (só p/ `lido`), apresentando Paywall ou celebração conforme o desfecho. Estrelas tocáveis (tocar de novo limpa).
- **Detalhe (8.2/8.5/8.11):** mostra todos os campos, posição `#N` no ano, duração; Editar reabre o formulário; Excluir pede confirmação e faz hard delete (apaga também a foto); botão do Cartão só para `lido`.
- **Biblioteca (8.4):** todos os livros com segmentado Todos/Quero ler/Lendo/Lido (default Todos; "Todos" ordena por `atualizado_em` desc). No filtro "Quero ler" mostra `indicado_por` e "Comecei a ler" (muda status para `lendo` sem abrir o formulário). Ícone de exportar na barra abre a tela Exportar; "+" pré-seleciona o status do filtro ativo. Estados vazios por filtro (copy da seção 15). O filtro é um `@Binding` controlado pelo `RootTabView`, para o "Ver tudo" da Home abrir a Biblioteca já em "Lendo".
- **Metas (8.6/8.7):** cria meta validando duplicata (`tipo`+`ano`+`numero`) e alvo > 0; progresso "X de Y" em tempo real; selo "BATIDA"; celebração com confete e atalho para o cartão.
- **Home (8.8):** 2 indicadores — mês e ano correntes (contagem "até hoje"; trimestre/semestre foram removidos da Home para poluir menos), "lendo agora" (até 2 mais recentes por `atualizado_em`, com link "Ver tudo" → Biblioteca em "Lendo" quando há mais de 2), Top 3 do ano, feed de lidos (desc); estado vazio com a copy da seção 15.
- **Exportar (8.9):** monta o `ExportScope` e gera o CSV; abre a folha de compartilhamento nativa; período vazio → só cabeçalho.
- **Importar backup / Configurações (8.9/seção 14):** o seletor de arquivos nativo escolhe um `.csv`; após confirmação explícita, `BackupRestore` sobrescreve o banco (apaga livros + metas + fotos e recria os livros como `lido`). Único ponto do app onde as Configurações escrevem no banco. Também: a política de privacidade abre o documento institucional da Dab Lab no Notion (`AppConstants.privacyPolicyURL`).
- **Paywall (8.10):** trial de 5; 6º dispara o Paywall; comprar/restaurar completa o salvamento pendente; restaurar também nas Configurações.
- **Cartões de compartilhar (8.7/8.11):** formato **stories 9:16 (1080×1920)**, estilo "Wrapped", renderizados por `ShareStoryCard` (uma arte, três variantes) via `ImageRenderer`; a tela `ShareCardView` tem três modos — `.lido` (calcula X e, se houver meta do período, Y → "X/Y"; seletor de período + cor), `.meta(Meta)` (celebração "X/Y" a partir da tela de meta batida) e `.amigo` (recomendação, novo, a partir do Detalhe). A lombada desenhada usa uma cor de contraste ao fundo escolhido; usa a foto quando existe. Sem escrita no banco.

---

## 6. Divergências em relação ao spec

1. **Preço no Paywall via `Product.displayPrice`** (ex.: "R$ 19,90") em vez do texto fixo "R$ 20" da copy da seção 15. Motivo: o preço vem da App Store (fonte de verdade da Apple), evita divergência preço↔copy e atende à recomendação de guideline. Decisão de tier confirmada: **R$ 19,90**.
2. **Fronteira de idioma na persistência (registro exigido pela seção 18):** as classes `@Model` são `Livro`/`Meta` (nome de entidade em português, singular) com **propriedades em `snake_case` português** espelhando 1:1 as colunas da seção 7; os enums são `status_livro`/`tipo_periodo_meta` (snake_case). Optou-se por espelhar o schema literalmente (em vez de camelCase + `originalName:`) para colar na seção 7; todo o resto do código é em inglês.
3. **StoreKit carregado de forma preguiçosa.** Na abertura, só o entitlement local é relido (sem buscar produto na rede), para não disparar prompt de conta Apple; o preço/produto é buscado quando o Paywall aparece. Comportamento de trial idêntico ao spec.
4. **Distinção indicadores × progresso de meta.** Os indicadores da Home contam "do início do período **até hoje**" (spec 11), enquanto o progresso das metas conta o período inteiro. São regras diferentes do spec, aplicadas onde cada uma cabe — podem exibir números diferentes para o mesmo período (ex.: mês).
5. **Auxiliares de DEBUG (não fazem parte do release):** flags de ambiente `ESTANTE_SKIP_STOREKIT` (pula StoreKit ao testar no Simulador sem conta de sandbox), `ESTANTE_SEED` (popula dados de exemplo na abertura) , `ESTANTE_SHOW_PAYWALL` (abre o Paywall direto na inicialização, para capturar a screenshot de review do IAP) e `ESTANTE_SHOW_META` (abre o cartão de meta batida, para conferir a arte), além de botões "Popular dados de exemplo"/"Limpar tudo" nas Configurações sob `#if DEBUG`. Servem ao teste manual/screenshots (spec 18); compilados fora apenas em Debug.
6. **Ícone do app** ainda é placeholder (asset vazio) — a arte final entra a partir da direção visual antes da submissão (spec 27.6).

> Regra de manutenção: qualquer mudança relevante em modelo de dados ou lógica de tela deve atualizar este documento no mesmo commit.
