# Spec — O que eu ando lendo (app de registro de leitura)

**Versão do documento:** 1.3
**Responsável de produto:** Alexandre Siqueira
**Status:** rascunho
**Data:** 2026-08-02

## Como usar este documento

Este documento é a fonte única de verdade do produto "O que eu ando lendo" (nome confirmado — codinome técnico do projeto/repositório segue "Estante", ver seção 24) para quem for implementá-lo, incluindo um agente de código. Toda decisão de UX, dado, regra ou fluxo que o time de implementação precisar já está — ou deveria estar — resolvida aqui; quando não está, ela foi movida deliberadamente para a seção 24 (Assunções declaradas) ou 25 (Perguntas abertas).

**Antes de gerar qualquer código a partir deste spec, revise a seção 24.** Assunção não revisada vira verdade no momento em que o agente de código começa a implementar — e reverter uma decisão depois de codada custa muito mais do que revisar uma frase agora.

---

## 0. Princípios não-negociáveis

1. **Local-first, sem exceção.** O app funciona 100% offline, sempre. Não há nenhuma chamada de rede no MVP — nem para buscar capa, nem para sincronizar, nem para telemetria "always-on".
2. **Registrar um livro nunca leva mais de 1 minuto.** Título, foto (opcional) e status já bastam para salvar; avaliação, comentário e data são preenchíveis depois, sem bloquear o registro.
3. **Simplicidade antes de complexidade prematura.** Duas tabelas, sem relação de chave estrangeira entre elas, sem triggers, sem servidor — cada regra nova só se justifica se um princípio acima não bastar para resolvê-la de outro jeito.
4. **O app nunca inventa nota.** Toda estrela, toda contagem de meta batida, todo "Top 3" vem de dado que o próprio usuário registrou — nunca de inferência, sugestão automática ou preenchimento por IA.
5. **Divertido e colorido, mas sem atrito.** Cor e ilustração de livro entram como identidade visual, nunca como decoração que atrapalha encontrar ou registrar um livro em poucos toques.

---

## 1. Visão e problema

"O que eu ando lendo" é um app iOS para registrar, de forma rápida e visualmente bonita, os livros que a pessoa está lendo, já leu ou quer ler — com estrelas, comentários, metas de leitura por mês/trimestre/semestre/ano e um cartão colorido pronto para compartilhar nas redes sociais. Nasce de um comportamento real: compartilhar quantos livros já leu no ano (o clássico post "8/2016") virou um símbolo de status nas redes sociais, mas hoje quem quer fazer isso precisa manter uma planilha ou contar na cabeça. Este app é esse controle — e o próprio post pronto — num app nativo, bonito, 100% local e sem fricção.

**Avaliação de complexidade (resposta direta ao pedido original):** este é um app de complexidade **baixa a média** para um desenvolvedor solo. Não há backend, não há login, não há integração com API externa nenhuma (a decisão de usar só foto manual eliminou a maior fonte de complexidade possível, que seria integrar uma API de metadados de livro). A maior parte do esforço está em UI (feed colorido, telas de registro, gráficos simples de indicadores, o cartão compartilhável) e em regras de cálculo de período (mês/trimestre/semestre/ano) — lógica direta, sem complexidade algorítmica ou de infraestrutura. O cartão compartilhável (seção 8.11) usa só `ImageRenderer`, API nativa do SwiftUI, sem biblioteca externa. Ver seção 8 para o tamanho real em épicos e seção 23 para riscos.

**Anti-escopo** — o que este produto explicitamente não é:
- Não é uma rede social: não há perfil público, seguidores, feed de outras pessoas nem comentários de terceiros.
- Não é um catálogo/enciclopédia de livros: não busca metadados, sinopse ou informações de terceiros sobre o livro — só o que o usuário digita.
- Não é um leitor de e-book (não abre nem exibe o conteúdo do livro, só o registro de que foi lido).
- Não sincroniza entre aparelhos nem tem conta própria no MVP (ver seção 4).
- Não gera cobrança recorrente — é compra única.

---

## 2. Personas e cenários de uso

- **Leitor(a) que posta no Instagram** — já tem o hábito de compartilhar "livro 8 do ano" nos stories; hoje faz isso de memória ou com uma nota no celular. Quer abrir o app, ver o número certo na hora e, no fim do mês/ano, ter a lista pronta para compartilhar.
- **Leitor(a) com meta de leitura** — definiu para si "12 livros este ano" ou "2 por mês" e quer ver o progresso sem fazer conta, e ser avisado quando bater a meta.
- **Leitor(a) que recebe indicações** — amigos indicam livros o tempo todo; hoje isso se perde em conversas de WhatsApp. Quer uma lista de "quero ler" com quem indicou cada um, para lembrar depois.

O cenário mais difícil de uso, e que mais define a arquitetura, é: a pessoa acabou de fechar um livro agora, quer registrar em segundos (foto da capa, nota, uma frase de comentário) sem digitar author bio nem procurar o livro numa base de dados — e sem depender de internet para isso.

---

## 3. Escopo do MVP

### Dentro do MVP

- Cadastro de livro com título, autor (opcional), editora (opcional), foto tirada na hora ou escolhida da galeria (opcional), status (quero ler / lendo / lido), avaliação em estrelas (1 a 5, opcional), comentário (opcional), quem indicou (opcional, relevante sobretudo para "quero ler"), data de início e data de conclusão da leitura.
- Três status de leitura: **quero ler**, **lendo atualmente**, **lido** — com transição livre entre eles (seção 12).
- Metas de leitura opcionais, por mês, trimestre, semestre ou ano, com quantidade-alvo definida pelo usuário; múltiplas metas de tipos diferentes podem coexistir (ex.: uma meta mensal e uma anual ao mesmo tempo).
- Mensagem de parabéns quando uma meta ativa é atingida pela primeira vez.
- Tela inicial (Home): indicadores no topo (livros lidos no mês/trimestre/semestre/ano correntes), Top 3 livros do ano (por estrelas), e feed cronológico dos livros lidos, mais recente primeiro.
- Tela **Biblioteca**: todos os livros do usuário, filtráveis por status (Todos / Quero ler / Lendo / Lido) — inclui a lista de "quero ler" com o campo de quem indicou como um dos filtros, não como tela separada.
- Exportação em CSV da lista de livros lidos, filtrando por mês, trimestre, semestre, ano ou intervalo de datas customizado (seção 14) — acessível a partir de um botão na tela Biblioteca **e** de um item nas Configurações (dois caminhos, seção 10, para não ficar escondida).
- **Cartão compartilhável**: imagem colorida, gerada localmente, mostrando a posição do livro dentro do período escolhido (ex.: "livro 8 do ano") — com "X/Y" quando existe uma meta ativa para aquele período, ou só "X" quando não existe nenhuma meta. **Funciona mesmo para quem nunca criou nenhuma meta** — não depende da seção 8.6 (épico 8.11).
- Editar e excluir um livro a qualquer momento.
- Modelo de negócio: download grátis, com **paywall ao atingir 5 livros registrados** (qualquer status: quero ler, lendo ou lido) e compra única (IAP não-consumível) de aproximadamente R$ 20 para desbloquear registros ilimitados (seção 4, 11 e 24) — decisão confirmada.
- Identidade visual divertida e colorida, com ilustrações de livro coloridas mesmo quando não há foto cadastrada (seção 16).

### Fora do MVP

| Item | Destino | Motivo / dependência |
|---|---|---|
| Busca automática de capa/metadados por API de livro (ex.: Open Library) | Descartado no MVP | Decisão explícita do usuário: só foto manual, para manter o app 100% offline sem nenhuma dependência externa (seção 24) |
| Sincronização entre aparelhos via iCloud/CloudKit | Adiado — v1.1 | Decisão explícita do usuário: MVP é local em um único aparelho. É uma mudança pequena em SwiftData (`cloudKitDatabase: .automatic`) se o usuário decidir mudar de ideia depois — ver seção 28 |
| Layout dedicado para iPad | Adiado — v1.1 | Não pedido; MVP funciona no iPad rodando a UI de iPhone, sem otimização de espaço extra |
| Notificações/lembretes de leitura | Descartado no MVP | Não pedido; adicionaria complexidade de permissões de notificação sem benefício claro ainda |
| Multi-idioma (inglês) | Descartado no MVP | App em português do Brasil apenas — decisão de escopo (seção 24) |
| Login / conta de usuário | Descartado | Contraria o princípio 0.1 (local-first) e não há necessidade de multiusuário |

---

## 4. Arquitetura

**Projeto de referência:** o Alexandre indicou o spec do **Leitor.md** (outro app iOS dele, mesma conta de desenvolvedor Apple) como referência de stack. O Leitor.md, por sua vez, reaproveitou convenções do app anterior "Hora do Remédio" (prefixo de bundle ID, team de assinatura, abordagem de projeto Xcode). Este app ("O que eu ando lendo", codinome técnico "Estante" — seção 24) deve seguir a mesma cadeia: reaproveitar o que já está consolidado nesses dois projetos (prefixo de bundle ID, team de assinatura/signing, `xcodegen` ou `.xcodeproj` conforme o padrão já em uso, estrutura geral de pastas) sempre que fizer sentido, e divergir só onde a natureza do produto exige — este app não usa WebView, não lê GitHub, não integra Google Drive, e (por decisão do usuário) não usa CloudKit no MVP.

| Decisão | Escolha | Por quê | Alternativa descartada |
|---|---|---|---|
| Plataforma-alvo | iOS 17.0+ (iPhone; roda no iPad sem layout dedicado — ver seção 3) | SwiftData (persistência escolhida abaixo) exige iOS 17+; em ago/2026 a versão vigente é iOS 26, então 17+ ainda cobre a grande maioria dos aparelhos ativos, mesmo padrão usado no Leitor.md | Suportar iOS 15+ com Core Data puro — mais boilerplate para um público residual pequeno em 2026 |
| Linguagem/UI | Swift + SwiftUI | Padrão atual da Apple para apps novos, mesmo padrão do Leitor.md/Hora do Remédio | UIKit — mais verboso, sem ganho para este produto |
| Persistência local | SwiftData **sem CloudKit** (`ModelContainer` local puro, sem `cloudKitDatabase`) | Decisão explícita do usuário: app funciona isolado em um único aparelho no MVP | CloudKit automático (como no Leitor.md) — adiado para v1.1 (seção 28); é uma mudança pequena de configuração se o usuário decidir mudar |
| Fotos de capa | Arquivo de imagem salvo localmente no sandbox do app (`Application Support/Fotos/`), redimensionado para no máximo 1200px no lado maior e comprimido em JPEG (qualidade ≈0.7) antes de salvar; o registro do livro guarda só o nome do arquivo | Mantém o tamanho do app/dados sob controle mesmo com muitas fotos; evita depender de biblioteca de terceiros para compressão | Guardar a imagem original sem redimensionar — cresce o espaço em disco sem necessidade, já que a foto é só ilustrativa, não precisa de alta resolução |
| Captura/escolha de foto | `PhotosPicker` (SwiftUI nativo) para escolher da galeria; `UIImagePickerController` (via `UIViewControllerRepresentable`) com `sourceType = .camera` para tirar foto na hora | APIs nativas padrão da Apple, sem dependência de terceiros | Biblioteca de terceiros para câmera — desnecessária, a API nativa já resolve |
| Compra e desbloqueio | StoreKit 2 (`Product`, `Transaction`), um produto de IAP **não-consumível** (compra única, ≈R$ 20) | Padrão atual da Apple para compra única; sincroniza entitlement automaticamente entre aparelhos do mesmo Apple ID via `Transaction.currentEntitlements`, sem precisar de backend — mesmo padrão usado no Leitor.md | Assinatura recorrente — descartada; modelo escolhido é pagamento único (seção 24) |
| Cálculo de períodos (mês/trimestre/semestre/ano) | Lógica pura em Swift usando `Calendar.current` do aparelho | Sem necessidade de biblioteca externa; usa o fuso horário e calendário do próprio usuário (seção 11) | Guardar campos derivados (ex.: "mês/ano" como coluna) no banco — desnecessário, mais fácil recalcular na consulta |
| Geração do cartão compartilhável | `ImageRenderer` (SwiftUI, nativo desde iOS 16 — coberto pelo mínimo de iOS 17 deste app) renderizando uma `View` customizada como imagem PNG, exportada via `UIActivityViewController` (folha de compartilhamento nativa) | API 100% nativa, sem dependência de terceiros; o card é só uma `View` SwiftUI comum, reaproveita os mesmos componentes visuais do app (seção 16) | Gerar a imagem em Core Graphics manual, ou via captura de tela (`snapshot`) de uma view real na tela — `ImageRenderer` é a API pensada exatamente para este caso, sem os efeitos colaterais de manipular a hierarquia de views visível |
| Distribuição | App Store, sem servidor próprio, sem conta de usuário do app | A única "conta" envolvida é a compra via Apple ID (StoreKit) — mesmo padrão do Leitor.md | — |

**Premissa técnica a validar:** confirmar, no início da implementação, o prefixo exato de bundle ID e o Apple Developer Team já usados no Leitor.md/Hora do Remédio, para reaproveitar (seção 27).

---

## 5. Perfis de usuário

Não aplicável: o app tem um único perfil (a pessoa que está lendo/registrando), sem papéis diferenciados nem multiusuário no mesmo aparelho.

---

## 6. Autenticação e identidade

Não aplicável: o app **não tem tela de login, conta, senha nem cadastro**. Não há identidade de usuário nenhuma dentro do app — os dados pertencem ao aparelho onde o app está instalado. A única interação com uma "conta" é indireta, via StoreKit, ao processar a compra única com o Apple ID já autenticado no aparelho (padrão do sistema, o app não vê nem armazena essa identidade).

---

## 7. Modelo de dados

### 7.1 Diagrama de relacionamento (texto)

```
livros    (livros da pessoa — quero ler / lendo / lido)
metas     (metas de leitura por período — mensal/trimestral/semestral/anual)
```

Não há relacionamento (`Ref`) entre as duas tabelas — são independentes por design (trade-off declarado abaixo). O progresso de uma meta é calculado em tempo real consultando `livros` (status = `lido` e `data_conclusao` dentro do período da meta), não por uma chave estrangeira.

**Trade-off de modelagem declarado:** não existe uma tabela de junção "livro concluiu meta X" — a contagem é sempre recalculada a partir de `livros.data_conclusao`. Isso simplifica o modelo (princípio 0.3), mas significa que excluir um livro depois pode fazer a contagem atual de uma meta parecer menor do que quando ela foi originalmente batida; o selo de "meta batida" já mostrado não é desfeito, porque `metas.meta_atingida_em` não regride automaticamente (ver regra na seção 11).

### 7.2 Tabela `livros`

| Campo | Tipo | Nullable | Default | Descrição |
|---|---|---|---|---|
| `id` | uuid | não | gerado | Chave primária |
| `titulo` | texto | não | — | Título do livro |
| `autor` | texto | sim | — | Nulo quando o usuário não preenche (campo opcional) |
| `editora` | texto | sim | — | Nulo quando o usuário não preenche (campo opcional) |
| `foto_arquivo` | texto | sim | — | Nome do arquivo de imagem salvo localmente (`Application Support/Fotos/`); nulo quando o livro não tem foto — nesse caso a UI mostra a ilustração colorida padrão (seção 16) |
| `status` | enum `status_livro` | não | `quero_ler` | Estado atual de leitura |
| `avaliacao_estrelas` | inteiro | sim | — | 1 a 5; nulo enquanto o usuário não avalia — não é obrigatório mesmo com status `lido` (seção 24) |
| `comentario` | texto | sim | — | Nulo quando o usuário não escreve nada |
| `indicado_por` | texto | sim | — | Nome de quem indicou o livro; nulo quando não veio de indicação de ninguém |
| `data_inicio_leitura` | data | sim | — | Nulo enquanto o livro está só em "quero ler" ou quando o usuário não preenche |
| `data_conclusao` | data | sim | — | Preenchida automaticamente com a data de hoje ao marcar como `lido` (editável); limpa automaticamente se o status muda para outro valor (regra na seção 11) |
| `criado_em` | datetime | não | agora | Quando o registro foi criado |
| `atualizado_em` | datetime | não | agora | Última edição do registro |

**Constraints:** `avaliacao_estrelas` entre 1 e 5 quando não nulo (validado em código — SwiftData não tem check constraint nativo, ver seção 7.5).

**Estratégia de exclusão:** hard delete. Não há histórico de terceiros referenciando o livro (app single-user, sem FK de outra tabela) — remover apaga de vez, sem necessidade de manter rastro.

### 7.3 Tabela `metas`

| Campo | Tipo | Nullable | Default | Descrição |
|---|---|---|---|---|
| `id` | uuid | não | gerado | Chave primária |
| `tipo_periodo` | enum `tipo_periodo_meta` | não | — | Mensal, trimestral, semestral ou anual |
| `ano` | inteiro | não | — | Ano de referência da meta (ex.: 2026) |
| `numero_periodo` | inteiro | sim | — | 1–12 quando `tipo_periodo = mensal`; 1–4 quando `trimestral`; 1–2 quando `semestral`; **nulo** quando `anual` (seção 24) |
| `quantidade_alvo` | inteiro | não | — | Número de livros que a pessoa quer ler no período; deve ser maior que zero |
| `meta_atingida_em` | datetime | sim | — | Nulo até a meta ser atingida pela primeira vez; uma vez preenchido, não regride (seção 11) |
| `criado_em` | datetime | não | agora | Quando a meta foi criada |
| `atualizado_em` | datetime | não | agora | Última edição da meta |

**Constraints:** único por (`tipo_periodo`, `ano`, `numero_periodo`) — não pode haver duas metas para o mesmo tipo e período (ex.: duas metas para "agosto/2026").

**Estratégia de exclusão:** hard delete. Apagar uma meta não afeta os livros já registrados, só remove o acompanhamento daquele período.

### 7.4 Enums

- `status_livro`: `quero_ler`, `lendo`, `lido`
- `tipo_periodo_meta`: `mensal`, `trimestral`, `semestral`, `anual`

### 7.5 Lógica que vive fora do banco

Não há triggers/funções/políticas — não é um banco relacional com servidor (é SwiftData local puro). Toda regra de negócio das seções 11/12 é aplicada em código Swift no próprio app: validação de faixa de `avaliacao_estrelas`, preenchimento/limpeza automática de `data_conclusao` na troca de status, cálculo de contadores de período, cálculo de Top 3, e verificação de meta batida.

### 7.6 Dados de seed

Nenhum dado de seed é necessário — o app começa vazio para cada instalação nova (não há conteúdo de catálogo pré-carregado, coerente com a decisão de não integrar API de livros).

---

## 8. Épicos e critérios de aceite

### 8.1 Cadastrar um livro
Objetivo: registrar um livro novo em poucos toques, em qualquer status.
Fluxo: Home → botão "+" → formulário (título obrigatório; autor, editora, foto, status inicial, estrelas, comentário, indicado por, datas — todos opcionais/preenchíveis depois) → Salvar.
Critérios de aceite:
- Salvar um livro só com título preenchido funciona (todos os outros campos são opcionais).
- Escolher "Tirar foto" abre a câmera; escolher "Escolher da galeria" abre o `PhotosPicker`; é possível salvar sem foto.
- Se o status escolhido for "lido" e a data de conclusão não for preenchida manualmente, ela é preenchida automaticamente com a data de hoje.
- Ao tentar salvar o 6º livro (de qualquer status) sem compra desbloqueada, o fluxo é interrompido pelo Paywall (épico 8.10) antes de gravar o registro.
- Livro salvo aparece imediatamente nas listas correspondentes ao seu status (no filtro certo da Biblioteca, e no feed da Home se `lido`).

### 8.2 Editar um livro e mudar de status
Objetivo: corrigir ou evoluir o registro de um livro (ex.: passar de "lendo" para "lido").
Fluxo: tocar num livro em qualquer lista → tela de detalhe/edição → editar campos ou trocar o segmento de status → Salvar.
Critérios de aceite:
- Mudar o status para "lido" com `data_conclusao` vazia preenche automaticamente com a data de hoje (editável antes de salvar).
- Mudar o status para longe de "lido" limpa `data_conclusao` automaticamente (regra da seção 11).
- Editar um livro já registrado nunca conta contra o limite de 5 livros do trial (o limite é só sobre criar registros novos).
- Se essa edição fizer uma meta ativa ser batida pela primeira vez, a mensagem de parabéns (épico 8.7) aparece ao salvar.

### 8.3 Avaliar e comentar um livro
Objetivo: registrar nota em estrelas e um comentário livre sobre o livro.
Fluxo: dentro da tela de detalhe/edição do livro (épico 8.2) → seletor de 1 a 5 estrelas (tocável) → campo de texto livre para comentário.
Critérios de aceite:
- Tocar na 3ª estrela, por exemplo, define `avaliacao_estrelas = 3`; tocar de novo na mesma estrela limpa a nota (volta a nulo).
- Comentário aceita texto livre, sem limite de caracteres artificial imposto pela UI (só o razoável de um campo de texto multilinha).
- Livro sem avaliação não aparece na lista de "Top 3" (regra da seção 11), mas aparece normalmente no feed.

### 8.4 Biblioteca — ver e filtrar todos os livros
Objetivo: dar um lugar único para ver **todos** os livros cadastrados, filtrando por status — inclusive a lista de "quero ler" com indicação, que passa a ser um dos filtros desta tela, não uma tela própria. Resolve a lacuna de não existir, antes desta versão, nenhum jeito de ver a lista completa de livros "lendo" ou "lido" além do que cabe na Home.
Fluxo: aba "Biblioteca" → segmentado no topo com 4 opções: **Todos / Quero ler / Lendo / Lido** (abre em "Todos" por padrão) → lista de livros do filtro ativo → tocar em "+" abre o mesmo formulário do épico 8.1, já com status pré-selecionado conforme o filtro ativo no momento (ou "quero ler" se o filtro ativo for "Todos").
Critérios de aceite:
- Filtro "Todos" mostra todos os livros, de qualquer status, ordenados por `atualizado_em` decrescente (regra da seção 11).
- Filtro "Quero ler" mostra só `status = quero_ler`, com o nome de quem indicou visível quando preenchido — mesmo comportamento que a extinta tela dedicada de "Quero ler" tinha.
- Filtro "Lendo" mostra só `status = lendo`; filtro "Lido" mostra só `status = lido`, ordenado por `data_conclusao` decrescente (mesma ordenação do feed da Home, épico 8.8).
- Tocar em "Comecei a ler" num item do filtro "Quero ler" muda o status para `lendo` sem precisar abrir o formulário de edição completo.
- Botão de exportar (ícone na barra de ferramentas) abre a tela de Exportar (épico 8.9) — segundo caminho de acesso além das Configurações (seção 10).
- Cada filtro vazio mostra seu próprio estado vazio (copy da seção 15) com atalho para cadastrar.

### 8.5 Excluir um livro
Objetivo: remover um registro incorreto ou indesejado.
Fluxo: tela de detalhe do livro → "Excluir" → confirmação → remoção.
Critérios de aceite:
- Exclusão pede confirmação explícita (não é uma ação de 1 toque só).
- Livro excluído desaparece de todas as listas (Home, Biblioteca em qualquer filtro, exportações futuras) imediatamente.
- Excluir um livro `lido` que fazia parte da contagem de uma meta já batida não desfaz a mensagem de parabéns já mostrada nem limpa `metas.meta_atingida_em` (regra da seção 11) — a contagem exibida na tela de metas passa a refletir o novo total, menor.
- Excluir um livro libera uma vaga no limite de 5 do trial (a contagem usada no Paywall é sempre sobre os livros que existem no momento, não cumulativa histórica — ver seção 24).

### 8.6 Definir e acompanhar metas de leitura
Objetivo: permitir que o usuário (opcionalmente) estabeleça quantos livros quer ler por mês, trimestre, semestre ou ano, e acompanhe o progresso.
Fluxo: tela "Metas" → "+" → escolher tipo de período, período específico (ex.: agosto/2026, ou "2026" se anual) e quantidade-alvo → Salvar. Tela lista todas as metas ativas com barra/contador de progresso.
Critérios de aceite:
- Não é possível criar duas metas para o mesmo tipo e mesmo período (ex.: duas metas de "setembro/2026") — a UI bloqueia e explica.
- Quantidade-alvo precisa ser maior que zero para salvar.
- Progresso de cada meta mostra "X de Y livros" calculado em tempo real a partir de `livros.lido` com `data_conclusao` dentro do período.
- Metas de tipos diferentes (ex.: mensal e anual) podem existir e progredir ao mesmo tempo, de forma independente.
- Usuário sem nenhuma meta definida usa o app normalmente — metas são inteiramente opcionais (nenhuma tela obriga a criar uma).

### 8.7 Mensagem de parabéns ao bater a meta
Objetivo: celebrar o momento em que uma meta ativa é atingida pela primeira vez.
Fluxo: ao salvar um livro como `lido` (épico 8.1 ou 8.2) cuja `data_conclusao` cai dentro do período de uma meta com `meta_atingida_em` ainda nulo, e essa mudança faz a contagem atingir ou ultrapassar `quantidade_alvo` → app marca `meta_atingida_em = agora` e mostra uma tela/alerta de parabéns.
Critérios de aceite:
- A mensagem só aparece uma vez por meta (na primeira vez que ela é atingida) — reaberturas do app ou novos livros na mesma meta não repetem a mensagem.
- A mensagem mostra o tipo de meta, o período e a quantidade atingida (ex.: "Você bateu sua meta de agosto: 8 livros lidos! 🎉").
- A tela de parabéns tem um atalho direto para o Cartão compartilhável (épico 8.11) na variante **meta batida** (celebração "X/Y", já pré-preenchida com essa meta) — não é obrigatório passar por essa tela para gerar o cartão, é só um atalho conveniente.
- Se mais de uma meta for atingida pelo mesmo livro salvo (ex.: mensal e anual ao mesmo tempo), as mensagens aparecem em sequência, uma por meta.
- Editar retroativamente um livro para uma data de um período passado, cuja meta já estava com `meta_atingida_em` preenchido antes dessa edição, **não** dispara a mensagem de novo — só atualiza o contador silenciosamente (regra da seção 11).

### 8.8 Tela inicial (Home): indicadores, Top 3 e feed
Objetivo: dar, na abertura do app, uma visão rápida e bonita do hábito de leitura da pessoa.
Fluxo: abertura do app → Home com três blocos, nesta ordem: indicadores no topo, Top 3 do ano, feed cronológico de livros lidos.
Critérios de aceite:
- Indicadores mostram, lado a lado, a contagem de livros com `status = lido` no mês corrente e no ano corrente (ambos "a partir do início do período até hoje", seção 11). Só esses dois, para a Home ficar mais limpa; trimestre e semestre seguem disponíveis como filtros na Exportação e no Cartão.
- Top 3 mostra até 3 livros com `status = lido` e `avaliacao_estrelas` preenchida no ano corrente, ordenados por estrelas (desc) e, em empate, por data de conclusão mais recente; mostra menos de 3 se não houver livros suficientes elegíveis, e nada (com estado vazio) se não houver nenhum.
- Feed lista os livros `lido`, ordenados por `data_conclusao` decrescente (mais recente primeiro), mostrando foto/ilustração, título, autor e estrelas.
- Se houver algum livro com `status = lendo`, a seção "Lendo agora" mostra até 2 deles (os mais recentes por `atualizado_em`); havendo mais de 2, aparece um link "Ver tudo" que abre a Biblioteca (épico 8.4) já com o filtro "Lendo" ativo.
- Instalação nova (sem nenhum livro `lido`) mostra estado vazio nos indicadores (zeros) e no feed, com copy da seção 15 e atalho para cadastrar o primeiro livro.

### 8.9 Exportar lista de livros lidos por período
Objetivo: gerar um arquivo com os livros lidos num período escolhido, para guardar ou compartilhar.
Fluxo: acesso pela tela Biblioteca (ícone de exportar na barra de ferramentas, épico 8.4) **ou** pelas Configurações → tela "Exportar" → escolher tipo de período (mês, trimestre, semestre, ano ou intervalo de datas customizado) → escolher o período específico → "Exportar" → gera CSV → abre folha de compartilhamento nativa do iOS.
Critérios de aceite:
- Exportação inclui só livros com `status = lido` cuja `data_conclusao` cai dentro do período escolhido, ordenados por `data_conclusao` crescente.
- Arquivo CSV segue exatamente o formato da seção 14 (colunas, encoding, separador, nome do arquivo).
- Período sem nenhum livro lido gera um CSV só com o cabeçalho, não um erro.
- Depois de gerado, abre a folha de compartilhamento nativa do iOS — o app nunca decide sozinho para onde o arquivo vai.

**Importar backup (restaurar):** nas Configurações há também "Importar backup (CSV)", para o caso de a pessoa ter exportado, reinstalado o app e querer restaurar. Critérios de aceite:
- Abre o seletor de arquivos nativo do iOS para escolher um `.csv` no formato exportado (seção 14).
- A importação **sobrescreve todo o banco**: apaga os livros e as metas atuais (e as fotos órfãs) e recria os livros a partir do arquivo, todos com `status = lido` (a exportação só contém lidos; autor, estrelas, comentário, indicado por e data de conclusão são restaurados; editora, foto, data de início e metas não constam do CSV e não são restaurados).
- Por ser destrutiva e irreversível, a importação pede confirmação explícita antes de aplicar, dizendo que substitui tudo.
- Arquivo vazio (só cabeçalho) ou inválido não quebra o app — importa zero livros.

### 8.10 Paywall e compra única
Objetivo: permitir uso gratuito até 5 livros registrados, com desbloqueio ilimitado via compra única.
Esta regra se aplica sobre o épico 8.1 (cadastro de livro) — é um portão (gate) que intercepta a criação de um livro novo quando aplicável, não um fluxo isolado.
Fluxo: usuário cadastra livros normalmente (1 a 5) → ao tentar salvar o 6º livro sem `compra_desbloqueada = true`, o app interrompe o salvamento e mostra a tela de Paywall → usuário compra (StoreKit) ou toca "Restaurar compra" → app libera e completa o salvamento do livro que estava pendente.
Critérios de aceite:
- Os 5 primeiros livros registrados (contando qualquer status: quero ler, lendo ou lido) são sempre livres, sem tela de paywall.
- Tentar salvar um 6º livro sem compra interrompe o fluxo e mostra a tela de Paywall, com o preço e os botões "Comprar" e "Restaurar compra".
- Após compra bem-sucedida (ou restauração), o app libera o cadastro ilimitado e completa automaticamente o salvamento do livro que estava pendente, sem exigir tocar em salvar de novo.
- Todas as funcionalidades (editar, avaliar, comentar, metas, exportar) funcionam normalmente sobre os livros já cadastrados no período de trial — a restrição é só sobre criar registros novos além do 5º.
- Botão "Restaurar compra" também está acessível pelas Configurações (não só no Paywall) — exigência do guideline de pagamentos da App Store.
- Se a compra falhar ou for cancelada, o app volta para onde estava, sem travar e sem repetir o paywall automaticamente.

### 8.11 Gerar e compartilhar o cartão de leitura
Objetivo: gerar uma imagem colorida, pronta para postar em redes sociais, mostrando em que posição aquele livro está dentro de um período — o equivalente digital do post "8/2016". **Não depende de nenhuma meta criada** — funciona para qualquer usuário, com ou sem meta ativa.
**Formato e estilo (atualizado):** os cartões saem no tamanho de **stories, 9:16 (1080×1920)**, não mais quadrado, no espírito "Wrapped" — fundo colorido da paleta do app, formas divertidas e tipografia grande arredondada (seção 16). São **três variantes**, na mesma família visual:
1. **Livro lido** — posição do livro no período ("Nº X" ou "X/Y"), a partir do Detalhe.
2. **Meta batida** — celebração da meta ("X/Y", "Você bateu sua meta!", confete), a partir do atalho da mensagem de parabéns (épico 8.7).
3. **Compartilhar com um amigo** *(novo)* — cartão de recomendação de um livro `lido` (capa/lombada, título, autor, estrelas, "recomendo pra você"), a partir do Detalhe. Usa a foto do livro quando há uma; senão, a lombada colorida desenhada (seção 16).
Fluxo (livro lido): a partir do Detalhe de um livro `lido` (épico 8.2) → botão "Card de compartilhar" → escolher o tipo de período (mês, trimestre, semestre ou ano) → app calcula a posição do livro dentro do período escolhido e monta o cartão → escolher a cor de fundo (paleta) → "Compartilhar" → folha de compartilhamento nativa do iOS.
Critérios de aceite:
- O botão "Card de compartilhar" e o "Compartilhar com um amigo" aparecem em qualquer livro com `status = lido`, independentemente de existir alguma meta cadastrada.
- Ao escolher, por exemplo, "ano", o app calcula X = quantas vezes esse livro entra na contagem de livros lidos naquele ano (ver regra de posição, seção 11) e mostra "livro nº X de {ano}".
- Se existir uma meta ativa do mesmo tipo de período e mesmo ano/período para esse livro, o cartão mostra "X/Y" (Y = `quantidade_alvo` daquela meta) em vez de só "X".
- Se não existir meta para aquele tipo de período, o cartão mostra só "X", sem barra de fração — o card não fica com aparência de "incompleto" por não ter meta (ver seção 16).
- Cartão inclui a foto do livro (ou a ilustração colorida padrão quando não há foto, seção 16), título e autor quando preenchido.
- Gerar o cartão nunca grava nada nas tabelas `livros` ou `metas` — é uma renderização temporária, sem efeito colateral no banco.
- Depois de gerado, abre a folha de compartilhamento nativa do iOS — o app nunca decide sozinho para onde a imagem vai.

---

## 9. Fluxos principais ponta a ponta

**Fluxo A — de "terminei de ler" até aparecer no feed e bater uma meta:**
1. Usuário toca em "+" na Home (ou edita um livro que já estava em "lendo").
2. Preenche título (se novo) e muda o status para "lido"; `data_conclusao` é preenchida com hoje automaticamente.
3. Opcionalmente avalia com estrelas e escreve um comentário.
4. Ao salvar, o app recalcula os indicadores e verifica todas as metas ativas cujo período inclui a data de conclusão.
5. Se alguma meta acabou de ser atingida pela primeira vez, mostra a mensagem de parabéns (épico 8.7).
6. Livro aparece no topo do feed da Home (épico 8.8).

**Fluxo B — primeira abertura do app (sem nenhum livro registrado):**
1. Home mostra indicadores zerados, Top 3 vazio e feed vazio, com copy de estado vazio e atalho para cadastrar.
2. Usuário cadastra o primeiro livro (épico 8.1), em qualquer status.
3. Se cadastrar direto como "lido", já aparece no feed e conta nos indicadores; se "quero ler" ou "lendo", aparece nas listas correspondentes.

**Fluxo C — atingir o limite do trial:**
1. Usuário já tem 5 livros registrados (de qualquer status) e ainda não comprou.
2. Tenta cadastrar o 6º livro.
3. App mostra o Paywall antes de gravar o registro.
4. Usuário compra (ou restaura compra anterior) → app completa o cadastro do livro pendente automaticamente.

**Fluxo D — gerar e compartilhar o cartão de um livro lido:**
1. Usuário está no Detalhe de um livro `lido` (ou acabou de bater uma meta, vindo do épico 8.7).
2. Toca em "Cartão" → escolhe o tipo de período (mês/trimestre/semestre/ano).
3. App calcula a posição do livro no período (regra da seção 11) e verifica se existe meta ativa para aquele tipo+período.
4. Card é renderizado (com "X/Y" se houver meta, ou só "X" se não houver) → usuário toca "Compartilhar" → folha de compartilhamento nativa do iOS.

---

## 10. Inventário de telas

| Tela | Acesso | Mostra | Lê | Escreve |
|---|---|---|---|---|
| Início (Home) | Abertura do app | Indicadores de mês e ano, "lendo agora" (com "Ver tudo"), Top 3 do ano, feed de lidos | `livros` | — |
| Cadastrar/Editar livro | "+" na Home, na Biblioteca, ou tocando num livro existente | Formulário completo (título, autor, editora, foto, status, estrelas, comentário, indicado por, datas) | `livros` | `livros` |
| Detalhe do livro | Tocar num livro em qualquer lista | Todos os campos do livro, botão excluir, "Card de compartilhar" e "Compartilhar com um amigo" (épico 8.11) | `livros` | `livros` (edição/exclusão) |
| Biblioteca | Aba dedicada, ou "Ver tudo" a partir da Home | Todos os livros, com filtro por status: Todos / Quero ler / Lendo / Lido (épico 8.4); botão de exportar na barra de ferramentas | `livros` | `livros` (atalho "Comecei a ler") |
| Metas | Aba/seção dedicada | Lista de metas ativas com progresso, botão para criar nova | `metas`, `livros` (para calcular progresso) | `metas` |
| Exportar | Botão na Biblioteca, ou atalho nas Configurações | Seleção de período, botão exportar | `livros` | Nenhuma tabela — só gera arquivo temporário e abre a folha de compartilhamento |
| Cartão compartilhável | Detalhe de um livro `lido`, ou atalho na tela de meta batida | Seleção de tipo de período, preview do cartão (foto/ilustração, título, autor, posição "X" ou "X/Y") | `livros` (para calcular a posição), `metas` (para saber se existe meta do período) | Nenhuma tabela — só gera imagem temporária e abre a folha de compartilhamento |
| Paywall | Ao tentar cadastrar o 6º livro sem compra, ou manualmente pelas Configurações | Preço, botão comprar, botão restaurar compra | StoreKit (`Product`) | `livros` (preferência local de compra, ver seção 24 sobre onde esse flag mora) |
| Configurações | Aba/botão dedicado | Sobre o app, avaliar na App Store, política de privacidade, botão restaurar compra, atalho para Exportar e Importar backup (CSV) | — | `livros`, `metas` (só a importação sobrescreve o banco — épico 8.9/seção 14) |

---

## 11. Regras de negócio

| Regra | Condição | Resultado | Onde é aplicada |
|---|---|---|---|
| Preenchimento automático de data de conclusão | Status de um livro muda para `lido` e `data_conclusao` está vazia | `data_conclusao` recebe a data de hoje (editável em seguida) | App |
| Limpeza automática de data de conclusão | Status de um livro muda para longe de `lido` | `data_conclusao` é apagada (`null`) | App |
| Cálculo de trimestre | Qualquer contagem/filtro trimestral | Q1 = jan–mar, Q2 = abr–jun, Q3 = jul–set, Q4 = out–dez | App |
| Cálculo de semestre | Qualquer contagem/filtro semestral | S1 = jan–jun, S2 = jul–dez | App |
| Fuso horário dos períodos | Qualquer cálculo de mês/trimestre/semestre/ano | Usa o calendário e fuso horário atuais do aparelho (`Calendar.current`), não um fuso fixo | App |
| Indicadores da Home | Contagem de "livros lidos no mês e no ano" | Conta livros com `status = lido` e `data_conclusao` do início do período corrente até hoje (não é janela móvel de X dias). A Home mostra só mês e ano (trimestre/semestre saíram para poluir menos) | App |
| Top 3 do ano | Cálculo do bloco "Top 3" na Home | Entre livros `status = lido` **e** `avaliacao_estrelas` preenchida, com `data_conclusao` no ano corrente; ordena por estrelas desc, empate por `data_conclusao` desc; mostra menos de 3 se não houver suficientes | App |
| Avaliação sem limite obrigatório | Livro marcado como `lido` | `avaliacao_estrelas` continua opcional mesmo assim — não é obrigatório avaliar para marcar como lido | App |
| Meta batida (primeira vez) | Uma meta ativa com `meta_atingida_em` nulo tem sua contagem atingindo ou ultrapassando `quantidade_alvo` **no momento em que um livro é salvo como `lido`** | `meta_atingida_em` é preenchido com a data/hora atual e a mensagem de parabéns (épico 8.7) é exibida | App |
| Meta batida não regride | `meta_atingida_em` já preenchido | Excluir ou editar livros depois não limpa `meta_atingida_em`, mesmo que a contagem recalculada fique abaixo da meta | App |
| Meta batida retroativamente não dispara mensagem | Edição de um livro faz sua `data_conclusao` cair num período cuja meta **já tinha** `meta_atingida_em` preenchido antes da edição | Contador é atualizado normalmente, mas a mensagem de parabéns **não** aparece de novo | App |
| Meta sem sobreposição | Criar uma meta com `tipo_periodo` + `ano` + `numero_periodo` já usados por outra meta | Bloqueado na criação, com aviso claro | App |
| Limite do trial | Usuário sem `compra_desbloqueada = true` tenta salvar um livro novo além do 5º já existente (qualquer status — quero ler, lendo ou lido — sem contar excluídos) | Bloqueia o salvamento e mostra a tela de Paywall (épico 8.10) — regra confirmada | App |
| Contagem do trial não é cumulativa histórica | Cálculo de "quantos livros já existem" para o limite do trial | Conta os livros que **existem agora** (exclusão libera vaga) — não um contador histórico de "quantos já foram criados alguma vez" | App |
| Posição do livro no período (cartão compartilhável) | Gerar o cartão de um livro `lido` para um tipo de período escolhido (mês/trimestre/semestre/ano) | X = contagem de livros `lido` cuja `data_conclusao` cai no mesmo período (mesmo mês/trimestre/semestre/ano do livro em questão), ordenados por `data_conclusao` crescente e, em empate, por `criado_em` crescente, até e incluindo o próprio livro | App |
| Cartão sem meta mostra só o numerador | Não existe meta com o mesmo `tipo_periodo` + `ano` + `numero_periodo` do livro/período escolhido no cartão | Cartão mostra só "X" (sem "/Y") — gerar o cartão nunca depende de o usuário ter criado alguma meta | App |
| Cartão com meta mostra fração | Existe meta com o mesmo `tipo_periodo` + `ano` + `numero_periodo` do livro/período escolhido no cartão | Cartão mostra "X/{quantidade_alvo da meta}" | App |
| Ordenação do filtro "Todos" na Biblioteca | Filtro "Todos" ativo na tela Biblioteca (épico 8.4) | Ordena por `atualizado_em` decrescente, misturando qualquer status | App |
| "Ver tudo" de "Lendo agora" | Home mostra a seção "Lendo agora" (épico 8.8) e existem mais de 2 livros com `status = lendo` | Mostra só os 2 mais recentes por `atualizado_em` e exibe um link "Ver tudo" que abre a Biblioteca com o filtro "Lendo" já ativo | App |

Nada nesta lista é derivado automaticamente além do que está escrito aqui — não há, por exemplo, nenhuma pontuação de "leitor do mês" ou ranking social.

---

## 12. Máquinas de estado e tratamento de erro

**Estados de `status_livro`:** `quero_ler` ⇄ `lendo` ⇄ `lido`, com transição livre em qualquer direção entre os três (é um app single-user editando os próprios dados — não há necessidade de restringir transições, princípio 0.3). O único efeito colateral automático é sobre `data_conclusao` (seção 11).

**Estados de compra:** `não comprado` → `comprando` (aguardando StoreKit) → `comprado` | `erro/cancelado` (volta para `não comprado` sem travar o app).

Erros possíveis e tratamento:

| Erro | Mensagem ao usuário |
|---|---|
| Falha ao salvar imagem (espaço em disco insuficiente, por exemplo) | "Não foi possível salvar a foto agora. O livro pode ser salvo sem foto." + opção de continuar sem foto |
| Compra falhou ou foi cancelada | Sem alerta bloqueante — o app volta discretamente para onde o usuário estava, sem repetir o Paywall automaticamente |
| Restaurar compra sem nenhuma compra anterior | "Nenhuma compra encontrada para restaurar." |
| Tentativa de criar meta duplicada (mesmo tipo+período) | "Já existe uma meta para este período." |
| Câmera/galeria sem permissão concedida pelo usuário | "Para adicionar uma foto, permita o acesso à câmera/fotos nas Configurações do iOS." + atalho para Configurações do sistema |

---

## 13. Contratos de API

Não aplicável — o MVP não tem nenhuma integração externa. Não há chamada de rede em nenhum fluxo (decisão explícita de manter só foto manual, seção 24). Se a busca automática de metadados de livro entrar em uma release futura (ver roadmap, seção 28), esta seção precisa ser reescrita com o contrato da API escolhida.

---

## 14. Relatórios, exportação e importação

O MVP exporta em **CSV**, acessível pela tela "Exportar" (épico 8.9). O cartão compartilhável (épico 8.11) é um recurso separado — uma imagem para redes sociais, não uma exportação de dados — e está descrito na seção 8.11 e na regra de negócio da seção 11, não nesta seção.

**Colunas, nesta ordem exata:**

| Coluna | Formato |
|---|---|
| Título | texto |
| Autor | texto (vazio se não preenchido) |
| Estrelas | número inteiro de 1 a 5, ou vazio se não avaliado |
| Comentário | texto (vazio se não preenchido) |
| Indicado por | texto (vazio se não preenchido) |
| Data de conclusão | `DD/MM/AAAA` |

- **Granularidade:** uma linha por livro com `status = lido` cuja `data_conclusao` cai dentro do período escolhido.
- **Ordenação:** por Data de conclusão, crescente (mais antigo primeiro) — pensado como um "diário de leitura" cronológico, diferente da ordem do feed na Home (que é decrescente).
- **Nome do arquivo:**
  - Mês: `livros-lidos-2026-08.csv`
  - Trimestre: `livros-lidos-2026-T3.csv`
  - Semestre: `livros-lidos-2026-S2.csv`
  - Ano: `livros-lidos-2026.csv`
  - Intervalo customizado: `livros-lidos-2026-01-15_2026-03-20.csv`
- **Encoding:** UTF-8 **com BOM** (compatibilidade com Excel, inclusive acentuação em português).
- **Separador:** ponto e vírgula (`;`) — configuração regional do Excel em português do Brasil usa vírgula como separador decimal, então `;` evita que o arquivo abra com todas as colunas numa célula só.
- Período sem nenhum livro lido gera um CSV só com a linha de cabeçalho (não um erro).

**Importação (restaurar backup):** o app importa de volta um CSV que ele mesmo exportou, pelas Configurações → "Importar backup (CSV)" (épico 8.9). É uma restauração de backup, não uma migração de outro app: **sobrescreve todo o banco** (apaga livros e metas atuais e recria os livros do arquivo, todos com `status = lido`, já que a exportação só contém lidos). Só reimporta os campos presentes no CSV (título, autor, estrelas, comentário, indicado por, data de conclusão); editora, foto, data de início e metas não constam do arquivo. Pede confirmação explícita por ser destrutiva. O parsing respeita aspas, o separador `;` e o BOM da seção acima.

---

## 15. Copy e tom de voz

Tom: caloroso, direto, em português do Brasil natural, com leveza (emoji pontual cabe na identidade "divertida e colorida" do produto, sem exagerar). Textos-âncora:

| Contexto | Texto |
|---|---|
| Estado vazio da Home (nenhum livro lido ainda) | "Sua estante está esperando o primeiro livro. Bora começar? 📚" |
| Biblioteca — estado vazio do filtro "Quero ler" | "Nenhum livro na sua lista de desejos ainda. Alguém te indicou algo bom recentemente?" |
| Biblioteca — estado vazio do filtro "Lendo" | "Você não está com nenhum livro em andamento agora. Bora começar um?" |
| Biblioteca — estado vazio do filtro "Todos" (instalação nova) | "Sua biblioteca está vazia. Registre o primeiro livro pra começar." |
| Botão principal da Home | "Registrar livro" |
| Mensagem de meta batida | "Você bateu sua meta de {período}: {quantidade} livros lidos! 🎉" |
| Tela de Paywall — título | "Continue registrando sem limites" |
| Tela de Paywall — corpo | "Você já registrou 5 livros de graça. Desbloqueie registros ilimitados com um pagamento único de R$ 20 — sem assinatura, sem cobrança recorrente." |
| Botão de compra | "Desbloquear por R$ 20" |
| Botão de restaurar compra | "Já comprei — restaurar" |
| Campo de comentário (placeholder) | "O que você achou desse livro?" |
| Botão do cartão (livro lido) | "Card de compartilhar" |
| Botão do cartão (amigo) | "Compartilhar com um amigo" |
| Cartão livro lido — herói | "Nº {X}" (com meta: "Nº {X}/{Y}") |
| Cartão livro lido — legenda, sem meta | "livro que li {em agosto / no 3º trimestre / este ano}" |
| Cartão livro lido — legenda, com meta | "livros da minha meta {período}" |
| Cartão meta batida — título | "Você bateu sua meta!" (kicker "meta {de agosto} batida", herói "{X}/{Y}") |
| Cartão amigo — kicker/selo | "Acabei de ler" · "recomendo pra você" · rodapé "achei que ia gostar · da minha estante" |
| Botão de compartilhar o cartão | "Compartilhar" |

Estes são textos finais candidatos, não placeholder — ajustáveis em revisão de copy antes do lançamento, mas o agente de código deve usá-los como estão, não inventar substitutos.

---

## 16. Direção visual / design system

**Referência visual definitiva: projeto no Claude Design.** As telas de referência para este app foram desenhadas no Claude Design (a partir do prompt de tom/telas elaborado nesta mesma sessão) e estão versionadas no repositório em `book-tracker-design-system/` (arquivos `Estante Screens.dc.html`, `ios-frame.jsx`, `support.js`, `README.md`). A descrição textual desta seção 16 continua valendo como racional, princípios e regras — mas em caso de conflito de detalhe visual (cor exata, espaçamento, tipografia, composição de tela), **a versão do Claude Design prevalece**, por ser mais precisa que qualquer descrição em texto.

Para importar/atualizar o projeto de design a partir do Claude Design (se precisar reimportar depois de uma edição lá):
```
Use the claude_design MCP (https://api.anthropic.com/v1/design/mcp, auth via /design-login) to import this project:
https://claude.ai/design/p/bb79ad4e-8406-4f86-bc04-dc0b37297ea4?file=Estante+Screens.dc.html
Focus on these files (the whole project is readable):
- `Estante Screens.dc.html`
Also read these files the selection imports:
- `ios-frame.jsx`
- `support.js`
Implement: `Estante Screens.dc.html`
```
Como os arquivos já foram colocados dentro da pasta do projeto que vai ser usada no Claude Code, a implementação **não depende de rodar essa importação de novo** — o agente de código pode simplesmente ler os arquivos locais em `book-tracker-design-system/` diretamente. O comando acima fica registrado aqui só para o caso de precisar reimportar uma versão atualizada do design mais tarde.

- **Nome confirmado:** "O que eu ando lendo" (nome de exibição — App Store e dentro do app). Codinome técnico do projeto/repositório: "Estante" (seção 24).
- **Cartões compartilháveis (épico 8.11):** formato **stories 9:16 (1080×1920)**, estilo "Wrapped" — fundo de cor chapada da paleta viva do app, formas decorativas divertidas (círculos, confete), tipografia grande arredondada e ícones em SVG (sem emoji). Três variantes na mesma família: **livro lido** (número "X"/"X/Y" como herói + capa/lombada + título/autor/estrelas), **meta batida** (fundo escuro com confete, "X/Y" gigante e "Você bateu sua meta!") e **compartilhar com um amigo** (capa/lombada em destaque + "Acabei de ler" + estrelas + selo "recomendo pra você"). A foto do livro é usada quando existe; senão, a lombada colorida desenhada (com cor de contraste ao fundo). O usuário escolhe a cor de fundo na paleta. Cada card é o "post pronto", sem edição externa. Quando não há meta (só "X"), a copy celebra o número sozinho (seção 15), sem parecer que falta algo.
- **Paleta:** múltiplas cores vivas e alegres (não uma única cor de marca dominante) — proposta inicial de 6 a 8 tons vibrantes (ex.: coral, amarelo-mostarda, verde-menta, azul-céu, roxo-lavanda, rosa-chiclete), usados sobretudo nas "lombadas" de livro ilustradas e em badges de status/meta batida. Fundo neutro claro (quase branco ou levemente creme) para não competir com as cores dos livros. Modo escuro: fundo neutro escuro, mesma paleta viva nos acentos.
- **Ilustração de livro sem foto:** quando `foto_arquivo` é nulo, a UI mostra um cartão colorido estilo "lombada de livro" com a inicial do título, numa cor escolhida de forma determinística a partir do `id` do livro (hash simples) — assim a cor de um livro específico é sempre a mesma entre sessões, e o feed/lista fica visualmente variado mesmo sem nenhuma foto cadastrada. Isso atende diretamente ao pedido de "ícones coloridos de livros".
- **Base:** Apple Human Interface Guidelines, SF Symbols para ícones de sistema (configurações, exportar, etc.), tipografia San Francisco padrão no chrome do app.
- **Densidade:** feed e listas em formato de card (não linha densa tipo planilha) — o produto é visual por natureza (capas/ilustrações), cards dão espaço para isso.
- **Confete/celebração:** a tela de meta batida (épico 8.7) usa uma animação leve de celebração (ex.: confete caindo), reforçando o tom "divertido" pedido — implementação livre para o time (SF Symbols animados ou uma biblioteca leve de confete em SwiftUI).
- **Modo escuro:** suportado desde o dia 1, mesma paleta viva nos acentos, fundo escuro neutro.
- O que fica livre para o time de implementação decidir: hex exatos da paleta, fonte de exibição de números grandes (indicadores), formato exato do card do feed — desde que sigam a direção acima.
- **Screenshots da App Store:** capturar via iOS Simulator, cobrindo Home (com indicadores e feed coloridos), tela de registrar livro, Metas com progresso, mensagem de meta batida, o Cartão compartilhável, e modo escuro — confirmar o tamanho de tela exigido vigente em App Store Connect no momento da submissão (muda por geração de aparelho).

---

## 17. Requisitos não-funcionais

- Abertura da Home (com até algumas centenas de livros) renderizada em menos de 1 segundo.
- Registrar um livro (título + salvar, sem foto) em até 3 toques a partir da Home.
- Gerar o cartão compartilhável (épico 8.11), do toque em "Cartão" até o preview pronto, em menos de 1 segundo.
- Funcionamento 100% offline, sempre, sem exceção — modo avião não muda nada no app.
- Acessibilidade: Dynamic Type em todo o texto do app, VoiceOver funcional em todas as telas (inclusive nos cards ilustrados do feed, com label descritivo tipo "Livro: {título}, {estrelas} estrelas"), contraste mínimo AA em todos os temas e cores de acento.
- Tamanho do binário: meta abaixo de 15MB (app simples, sem bibliotecas pesadas).
- Compatibilidade: iPhone SE (tela pequena) até iPhone Pro Max; roda no iPad sem layout dedicado (seção 3).
- Idioma: português do Brasil apenas no MVP (seção 24).
- Volume esperado de dados: uso individual, de dezenas a poucas centenas de livros ao longo de anos — volume irrelevante para performance de SwiftData local.
- **Backup:** como não há sincronização própria no MVP, a preservação dos dados depende do backup padrão do iOS (iCloud Backup do aparelho ou backup via Finder/computador) — isso deve estar explícito na política de privacidade e, se fizer sentido, numa nota nas Configurações do app.

---

## 18. Convenções de código, documentação e estrutura do repositório

- **Modelos de dados (SwiftData) em português**, `snake_case` nos nomes conforme a seção 7 (`livros`, `metas`, `status_livro`, `tipo_periodo_meta`, etc.) — mesmo não havendo um banco relacional tradicional, a convenção de nomenclatura do domínio vale igual, mesmo padrão usado no Leitor.md.
- Código, variáveis, funções, nomes de arquivo e de `struct`/`class` Swift em inglês, como é padrão da comunidade iOS — a fronteira de idioma fica nos nomes que espelham o modelo de dados da seção 7. Decisão do time de implementação se as `@Attribute` das structs Swift mantêm os nomes em português (espelhando 1:1) ou usam `originalName:` para mapear — registrar a escolha em `DOCUMENTACAO-TECNICA.md`.
- Toda função, `ViewModel` e rotina de cálculo (períodos, Top 3, meta batida) leva comentário de cabeçalho em português explicando o que faz, o que recebe, o que devolve e qual seção deste spec implementa (ex.: `// Calcula se uma meta foi batida pela primeira vez ao salvar um livro como lido (spec seção 11)`).
- Organização de pastas por feature: `Sources/Livros` (cadastro, edição, detalhe), `Sources/Home` (indicadores, Top 3, feed), `Sources/Biblioteca` (lista filtrável por status), `Sources/Metas`, `Sources/Exportar`, `Sources/Cartao` (épico 8.11), `Sources/Compra` (StoreKit), `Sources/Configuracoes`, `Sources/ModeloDeDados` (SwiftData), `Sources/Compartilhado` (componentes de UI reutilizáveis, ex.: card de livro ilustrado).
- `book-tracker-design-system/` na raiz do repositório: pasta de referência visual gerada no Claude Design (seção 16) — `Estante Screens.dc.html`, `ios-frame.jsx`, `support.js`, `README.md`. É material de referência para implementação da UI, não faz parte do target do app (não compila).
- README na raiz com setup local, como rodar o app, e como popular dados de exemplo para teste manual (útil especialmente para testar o feed/Top 3/metas com volume de dados).
- Variáveis de ambiente/segredos: nenhuma — não há servidor nem chave de API neste MVP.

---

## 19. Documento de documentação técnica

Ao fim da implementação, gerar `DOCUMENTACAO-TECNICA.md` na raiz do repositório, em português, descrevendo o sistema como implementado de fato (não como planejado), com:

1. Modelo de dados explicado em português — cada tabela SwiftData, para que serve, o que cada campo significa em linguagem de negócio, valores de cada enum.
2. Relacionamento entre as tabelas (mesmo sendo só duas, e independentes — documentar isso explicitamente, incluindo como o progresso de meta é calculado sem FK).
3. Lógica que roda fora da UI — cálculo de períodos, Top 3, verificação de meta batida, redimensionamento/compressão de foto, geração do CSV — onde vive cada uma, o que dispara.
4. Mapa tela → dados: para cada tela da seção 10, o que ela lê e escreve de fato no código implementado.
5. Lógica das principais funcionalidades por tela: o que é validado, o que é salvo, o que é calculado e onde.
6. Divergências em relação a este spec — o que saiu diferente do especificado e por quê.

Toda mudança relevante em modelo de dados ou lógica de tela atualiza este documento no mesmo commit.

---

## 20. Privacidade, segurança e conformidade

- **Dados coletados por servidor próprio: nenhum** — não há servidor. Todos os dados (livros, metas, fotos) ficam só no aparelho do usuário.
- Não há sincronização com nenhum serviço de terceiros no MVP (decisão explícita, seção 4) — nem CloudKit, nem qualquer nuvem.
- Fotos ficam salvas no sandbox local do app, nunca enviadas a lugar nenhum.
- O cartão compartilhável (épico 8.11) é gerado inteiramente no aparelho; só sai do app se o próprio usuário escolher compartilhar pela folha nativa do iOS — o app não publica nada sozinho em nenhuma rede social.
- Compra é processada inteiramente pela Apple (StoreKit) — o app não vê nem guarda dado de pagamento.
- Permissões do sistema necessárias: acesso à Câmera (`NSCameraUsageDescription`) e à Biblioteca de Fotos (`NSPhotoLibraryUsageDescription`), com texto explicando exatamente o uso ("para adicionar uma foto da capa do livro que você está registrando").
- LGPD: como não há coleta nem processamento de dados pessoais por servidor próprio, a exposição é mínima; ainda assim, publicar uma política de privacidade (exigência da App Store) explicando isso — inclusive que os dados residem só localmente e dependem do backup padrão do iOS (seção 17).
- App Store Privacy Nutrition Label: declaração correta é "Dados não coletados" (sem analytics de terceiros no MVP, seção 21).
- Sem dados sensíveis por natureza do produto (não há categoria de saúde, financeiro, menores, biometria envolvida).

---

## 21. Métricas de sucesso e telemetria

Sem analytics de terceiros no MVP (coerente com "local-first, sem exceção", princípio 0.1). Métricas de produto vêm só do que o App Store Connect já fornece nativamente:

- Taxa de conversão do Paywall (downloads vs. compras) — visível no relatório de IAP do App Store Connect.
- Retenção D7/D30.
- Nota média e volume de avaliações na App Store.

Se o time decidir adicionar uma ferramenta de analytics própria orientada a privacidade no futuro, isso é uma pergunta aberta (seção 25) — qualquer evento coletado não pode carregar título, autor, comentário ou foto do usuário (seção 20).

---

## 22. Estratégia de teste

- Regras de cálculo de período (mês/trimestre/semestre/ano, seção 11) merecem teste automatizado por serem lógica pura — incluindo casos de borda: virada de ano, virada de mês, fuso horário do aparelho diferente de UTC.
- Lógica de "meta batida pela primeira vez" (seção 11) merece teste automatizado, incluindo o caso de edição retroativa não repetir a mensagem.
- Lógica do limite do trial (5 livros, contagem não cumulativa) merece teste automatizado, incluindo o caso de excluir um livro liberar vaga.
- Teste manual em device real do fluxo de câmera/galeria (picker de foto), incluindo negar permissão e verificar a mensagem de erro da seção 12.
- Teste manual do fluxo de compra via sandbox do StoreKit: primeira compra, restaurar compra em instalação nova com o mesmo Apple ID, compra cancelada.
- Teste de exportação CSV: abrir o arquivo gerado no Excel/Numbers e conferir acentuação (BOM), separador e formatação de data.
- Teste de acessibilidade: VoiceOver navegando pelo feed de cards ilustrados (ponto mais frágil de acessibilidade do produto, por ser um design custom).

---

## 23. Riscos e mitigação

| Risco | Impacto | Probabilidade | Mitigação |
|---|---|---|---|
| Usuário que já leu muitos livros na vida tenta cadastrar seu histórico inteiro de uma vez e esbarra no limite de 5 já no início | Baixo (é justamente o público mais propenso a comprar — leitor engajado) | Alto (é o comportamento esperado de quem instala o app já querendo registrar retroativamente) | Nenhuma ação necessária — é o comportamento pretendido do modelo de negócio (seção 24); considerar deixar isso claro na copy do Paywall |
| Sem sincronização entre aparelhos, troca de iPhone perde os dados se o usuário não tiver backup do iOS ativo | Alto para quem for afetado | Baixo (a maioria dos usuários iOS tem iCloud Backup ativo por padrão) | Nota clara nas Configurações/política de privacidade sobre a dependência do backup padrão do iOS (seção 17); reavaliar prioridade do CloudKit (v1.1, seção 28) se isso gerar reclamação |
| Ilustração colorida "genérica" (sem foto real) ser confundida com falha de carregamento de imagem | Baixo | Médio | Design da ilustração precisa parecer claramente intencional (não um placeholder cinza) — validar com o usuário/design antes de fechar (seção 16) |
| Redimensionamento/compressão de foto malfeito deixar capas borradas ou com proporção distorcida | Médio | Baixo | Testar com fotos reais de capas de livro (formato retrato, geralmente) antes de fechar os parâmetros de compressão (seção 4) |
| App rejeitado na revisão da App Store por não ter "Restaurar compra" acessível fora do Paywall | Alto se ignorado (bloqueia lançamento) | Baixo (mitigação simples) | Botão de restaurar compra sempre visível nas Configurações também (já especificado no épico 8.10) |
| Cartão sem meta ("só X", sem "/Y") parecer incompleto ou menos celebrativo que o cartão com meta | Baixo | Médio (a maioria dos usuários provavelmente não vai criar meta) | Copy e layout tratados desde o design como duas variações igualmente prontas, não como "com meta = completo" vs. "sem meta = faltando algo" (seção 16) |

---

## 24. Assunções declaradas

> Assunção não revisada vira verdade no minuto em que o agente de código começa a implementar. Revise esta seção antes de gerar qualquer código.

- **Campos "autor" e "editora" confirmados** — o autor foi proposta desta spec (v1.0) e aprovada; a editora foi pedida diretamente. Ambos opcionais, sem custo de fricção no cadastro.
- **Contagem do limite de 5 livros do trial considera qualquer status** (quero ler, lendo ou lido), não só livros lidos — confirmado pelo Alexandre.
- **Nome de exibição confirmado: "O que eu ando lendo".** Como esse nome tem espaços e não é ideal como identificador técnico (nome de target Xcode, nome de pasta, prefixo de bundle ID), o codinome técnico do projeto continua "Estante" (usado neste spec só quando o contexto é técnico/interno) — decisão de conveniência, não visível ao usuário final. Se preferir usar outro codinome técnico, é só avisar.
- **Cartão compartilhável incluído no MVP** (épico 8.11), por pedido explícito — funciona com ou sem meta ativa para o período escolhido, mostrando "X" sozinho quando não há meta.
- **Ordem de desempate na posição do livro do cartão** (quando dois livros têm a mesma `data_conclusao`): por `criado_em` crescente — decisão de baixo impacto para resolver um empate que deve ser raro na prática.
- **Avaliação em estrelas não é obrigatória** para marcar um livro como `lido` — algumas pessoas não gostam de avaliar todo livro. Se preferir tornar obrigatório, afeta o épico 8.1/8.2 e a UI de transição de status.
- **Status "lendo atualmente" incluído** (três estados: quero ler / lendo / lido) — decisão confirmada pelo usuário durante a coleta de requisitos.
- **App só local em um único aparelho, sem sincronização** — decisão confirmada pelo usuário. Estrutura do SwiftData foi desenhada para tornar essa mudança pequena no futuro (v1.1, seção 28), caso o usuário mude de ideia.
- **Capa só por foto manual (câmera ou galeria), sem busca automática por API** — decisão confirmada pelo usuário, elimina toda dependência de rede do MVP.
- **iOS mínimo: 17.0**, pela dependência do SwiftData, mesmo padrão do Leitor.md.
- **iPhone como alvo principal, sem layout dedicado para iPad no MVP** — não foi pedido; o app roda no iPad mesmo assim, só sem otimização extra de espaço.
- **Idioma único: português do Brasil** — não foi pedido suporte a outro idioma, e o contexto do produto (hábito de redes sociais brasileiras) é local.
- **Sem analytics de terceiros no MVP** — métricas vêm só do App Store Connect (seção 21).
- **Preço da compra única em torno de R$ 20** — valor exato dentro dos tiers de preço da Apple (candidatos naturais: R$ 19,90 ou R$ 20,90) fica como pergunta aberta (seção 25).
- **Exclusão de livro é hard delete** — não há necessidade de manter histórico, dado que é um app single-user sem auditoria nem colaboração.
- **Ilustração colorida do livro sem foto é determinística por livro** (mesma cor sempre para o mesmo `id`), não aleatória a cada abertura — para dar consistência visual ao feed.
- **Nenhum dado de seed/catálogo pré-carregado** — o app começa vazio, coerente com não integrar nenhuma base de livros.

---

## 25. Perguntas abertas

O agente de código deve **perguntar em vez de assumir** ao esbarrar em qualquer um destes pontos:

- **Tier de preço exato na Apple** (R$ 19,90 vs R$ 20,90, por exemplo), dentro da faixa "em torno de R$ 20" já definida (seção 24) — quem decide: Alexandre. Prazo: antes do lançamento.
- **Prefixo de bundle ID e Apple Developer Team exatos** a reaproveitar do Leitor.md/Hora do Remédio (seção 4) — quem decide: conferir nos projetos existentes no início da implementação. Prazo: antes de criar o App ID.

---

## 26. Definition of Done

- [ ] Todos os épicos da seção 8 implementados e validados contra seus critérios de aceite.
- [ ] Testado em device real o fluxo de câmera/galeria (permissões negadas e concedidas).
- [ ] Trial testado de ponta a ponta: 5 primeiros livros livres, 6º bloqueado pelo Paywall, compra via sandbox do StoreKit libera corretamente, "Restaurar compra" testado numa instalação diferente com o mesmo Apple ID.
- [ ] Produto de IAP não-consumível criado e configurado no App Store Connect, com preço no tier definido (seção 25).
- [ ] Exportação CSV testada abrindo o arquivo gerado no Excel/Numbers, conferindo acentuação, separador e formato de data (seção 14).
- [ ] Cálculo de indicadores/Top 3/metas testado em casos de borda de fuso horário e virada de mês/ano (seção 22).
- [ ] Mensagem de meta batida testada: primeira vez aparece, edições retroativas não repetem, exclusão não desfaz o selo.
- [ ] Ilustração colorida de livro sem foto implementada e validada visualmente (seção 16).
- [ ] Telas implementadas conferidas visualmente contra o projeto de referência em `book-tracker-design-system/` (seção 16) — cores, tipografia e composição batendo com o que foi desenhado no Claude Design.
- [ ] Cartão compartilhável testado com e sem meta ativa para o período escolhido (mostrando "X" e "X/Y" corretamente), incluindo abrir a folha de compartilhamento nativa (épico 8.11).
- [ ] Biblioteca testada nos 4 filtros (Todos/Quero ler/Lendo/Lido), incluindo os estados vazios de cada um (épico 8.4).
- [ ] Exportar testado a partir dos dois pontos de acesso (Biblioteca e Configurações) — mesmo comportamento a partir de qualquer um dos dois (épico 8.9, seção 10).
- [ ] Modelos de dados (SwiftData) em português conforme a convenção da seção 7, sem tabela/enum fora do padrão.
- [ ] Todas as funções e rotinas de cálculo comentadas conforme seção 18.
- [ ] `DOCUMENTACAO-TECNICA.md` gerado e conferido contra o sistema implementado de fato.
- [ ] Política de privacidade publicada e Privacy Nutrition Label preenchido na App Store Connect.
- [ ] Acessibilidade validada: Dynamic Type, VoiceOver nos cards ilustrados, contraste AA em todos os temas.
- [ ] Seção 24 (Assunções) e seção 25 (Perguntas abertas) revisadas e confirmadas por Alexandre antes da submissão à App Store.

---

## 27. Próximos passos operacionais

1. Revisar as seções 24 (Assunções) e 25 (Perguntas abertas) deste documento, incluindo o nome final do app.
2. Conferir que a pasta `book-tracker-design-system/` (seção 16 e 18) está presente na raiz do repositório antes de começar a implementar as telas — o agente de código deve ler esses arquivos como referência visual definitiva, não inventar a UI a partir só da descrição em prosa da seção 16.
3. Conferir e reaproveitar o prefixo de bundle ID e o Apple Developer Team já usados no Leitor.md/Hora do Remédio (seção 4).
4. Criar o produto de IAP não-consumível no App Store Connect (ex.: identificador `estante_desbloqueio_completo`) antes de implementar o épico 8.10, para já testar contra um produto real em sandbox.
5. Implementar primeiro o modelo de dados (seção 7), depois as telas (seção 10), seguindo a ordem dos épicos (8.1 → 8.11), usando o projeto de design (`book-tracker-design-system/`) como referência de cada tela.
6. Gerar o ícone final do app a partir da direção visual do projeto de design (seção 16) — o ícone em si não faz parte das telas geradas no Claude Design e precisa ser produzido à parte.
7. Rodar o app no iOS Simulator para capturar os screenshots da App Store (seção 16) assim que os épicos 8.1, 8.6, 8.7, 8.8 e 8.11 estiverem estáveis.

---

## 28. Roadmap: próximas releases

**v1.1**
- Contador de livros na tela Biblioteca (épico 8.4): mostrar, de forma discreta, o total de livros conforme o filtro selecionado (Todos / Quero ler / Lendo / Lido) — o número acompanha o segmento ativo. Pedido do usuário para uma próxima versão.
- Sincronização entre aparelhos do mesmo usuário via iCloud/CloudKit (`ModelContainer` com `cloudKitDatabase: .automatic`) — adiada do MVP por decisão explícita do usuário (seção 3), mas tecnicamente simples de ligar depois, já que o modelo de dados (seção 7) foi desenhado sem dependências que impeçam isso.
- Layout dedicado para iPad (aproveitando mais espaço horizontal no feed e nas Metas).
- Mais de um layout/template de cartão compartilhável (o MVP entrega um layout só, seção 16) — variações de composição para quem quer postar com mais frequência sem repetir sempre o mesmo visual.

**v1.2**
- Busca automática de capa/metadados por API pública de livro (ex.: Open Library, que não exige chave de API), com fallback para foto manual — só se o usuário decidir abrir mão do princípio "100% offline" em troca de conveniência no cadastro. Precisaria de uma nova seção 13 (Contratos de API) nesse momento.
- Notificações locais opcionais (lembrete de meta perto do fim do período, por exemplo).

---

## 29. Protocolo de mudanças incrementais

Depois que a v1 estiver pronta e publicada, para qualquer ajuste pequeno:

1. Faça um commit de checkpoint antes de qualquer mudança, para ter um `git diff` confiável depois.
2. Não cole este spec inteiro de novo — cole só o trecho novo ou alterado, ou escreva um spec adicional específico da feature.
3. Escreva a instrução como diff sobre o que já existe, não como um recomeço — deixe explícito que o projeto já existe e funciona.
4. Diga nominalmente o que **não** deve mudar.
5. Peça a lista de arquivos que serão criados/alterados **antes** de qualquer código, e aprove antes de deixar o agente prosseguir.
6. Revise o `git diff` contra o que foi aprovado; reverta qualquer arquivo que passou do escopo combinado e refaça o pedido de forma mais específica.
7. Exija a atualização do `DOCUMENTACAO-TECNICA.md` no mesmo commit da mudança.

**Modelo de prompt para colar:**

```
O projeto "O que eu ando lendo" já existe e está funcionando (não é um projeto novo).
Mudança pontual: [descreva a mudança].
Não altere nada fora de: [liste os arquivos/telas esperados].
Antes de codar, monte o plano e a lista de arquivos que vai criar/alterar e me mostre para aprovação.
Depois de implementar, atualize o DOCUMENTACAO-TECNICA.md refletindo essa mudança.
```

---

## Anexo — Fontes

Pesquisa técnica realizada em 2026-08-01:

- [Upcoming SDK minimum requirements — Apple Developer](https://developer.apple.com/news/?id=ueeok6yw) — confirma iOS 26/iPadOS 26 SDK como mínimo obrigatório para submissões à App Store a partir de 28/abr/2026, e a versão vigente do iOS como iOS 26 em ago/2026.
- [Open Library Covers API — documentação oficial](https://openlibrary.org/dev/docs/api/covers) — confirmou que existe uma API pública gratuita, sem chave, para busca de capa por ISBN; **não usada no MVP** por decisão explícita do usuário de manter o app 100% offline (ver seção 3/24), mas registrada aqui como opção validada para o roadmap v1.2 (seção 28).
- [SwiftData vs Core Data: Which Local Storage Framework Should iOS Developers Use in 2026? — Medium](https://medium.com/@bhumibhuva18/swiftdata-is-here-but-should-you-actually-ditch-core-data-49a3c8665e13)
- Spec de referência "Leitor.md" (arquivo `specleitormd.md`, compartilhado pelo Alexandre nesta conversa) — usado como referência de stack (Swift + SwiftUI + SwiftData + StoreKit 2), convenções de nomenclatura e estrutura de documento.
