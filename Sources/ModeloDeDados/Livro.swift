// Livro.swift — tabela `livros` do modelo de dados (spec seção 7.2).
//
// Registro de um livro do usuário, em "quero ler", "lendo" ou "lido". Exclusão é
// hard delete (spec 7.2). Não há relação de chave estrangeira com `metas` — o
// progresso de meta é recalculado a partir de `data_conclusao` (spec 7.1).
//
// Convenção de idioma (instrução do produto / spec 18): a classe `@Model` é a
// camada de tabela/coluna e usa nomes em português, snake_case, exatamente como
// na seção 7.2. O resto do código (views, helpers) fica em inglês.
//
// Disciplina CloudKit-ready (spec 24/28): toda propriedade tem valor default e
// nenhuma usa `@Attribute(.unique)`; a validação de faixa de `avaliacao_estrelas`
// e as regras de status vivem em código (spec 7.5/11), não no store — assim ligar
// CloudKit depois é uma mudança pequena.

import Foundation
import SwiftData

@Model
final class Livro {

    /// Chave primária (spec 7.2 — `id`).
    var id: UUID = UUID()

    /// Título do livro — único campo obrigatório no cadastro (spec 7.2 / 8.1).
    var titulo: String = ""

    /// Autor; nulo quando não preenchido (spec 7.2 — opcional).
    var autor: String?

    /// Editora; nula quando não preenchida (spec 7.2 — opcional).
    var editora: String?

    /// Nome do arquivo de imagem salvo em `Application Support/Fotos/`; nulo quando
    /// o livro não tem foto — a UI mostra a lombada colorida padrão (spec 7.2/16).
    var foto_arquivo: String?

    /// Estado atual de leitura (spec 7.2 — default `quero_ler`).
    var status: status_livro = status_livro.quero_ler

    /// Nota de 1 a 5; nula enquanto não avaliado. Opcional mesmo com status `lido`
    /// (spec 7.2/11/24). Faixa validada em código (spec 7.5).
    var avaliacao_estrelas: Int?

    /// Comentário livre; nulo quando vazio (spec 7.2).
    var comentario: String?

    /// Nome de quem indicou o livro; nulo quando não veio de indicação (spec 7.2).
    var indicado_por: String?

    /// Data de início da leitura; nula em "quero ler" ou quando não preenchida (spec 7.2).
    var data_inicio_leitura: Date?

    /// Data de conclusão; preenchida com hoje ao marcar `lido` e limpa ao sair de
    /// `lido` (regra em código, spec 11). Nula fora de `lido` (spec 7.2).
    var data_conclusao: Date?

    /// Quando o registro foi criado (spec 7.2 — `criado_em`).
    var criado_em: Date = Date()

    /// Última edição do registro (spec 7.2 — `atualizado_em`).
    var atualizado_em: Date = Date()

    // Cria um novo livro. Só `titulo` e `status` têm carga obrigatória; todo o
    // resto é opcional/preenchível depois, para o cadastro caber em poucos toques
    // (spec 0.2 / 8.1). Devolve a instância pronta para inserir no ModelContext.
    init(
        titulo: String = "",
        autor: String? = nil,
        editora: String? = nil,
        foto_arquivo: String? = nil,
        status: status_livro = .quero_ler,
        avaliacao_estrelas: Int? = nil,
        comentario: String? = nil,
        indicado_por: String? = nil,
        data_inicio_leitura: Date? = nil,
        data_conclusao: Date? = nil
    ) {
        self.id = UUID()
        self.titulo = titulo
        self.autor = autor
        self.editora = editora
        self.foto_arquivo = foto_arquivo
        self.status = status
        self.avaliacao_estrelas = avaliacao_estrelas
        self.comentario = comentario
        self.indicado_por = indicado_por
        self.data_inicio_leitura = data_inicio_leitura
        self.data_conclusao = data_conclusao
        self.criado_em = Date()
        self.atualizado_em = Date()
    }
}
