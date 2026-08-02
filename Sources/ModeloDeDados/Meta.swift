// Meta.swift — tabela `metas` do modelo de dados (spec seção 7.3).
//
// Meta de leitura definida pelo usuário para um período (mês, trimestre, semestre
// ou ano). O progresso é calculado em tempo real consultando `livros` com
// status = `lido` e `data_conclusao` dentro do período — não há chave estrangeira
// (spec 7.1/11). Exclusão é hard delete (spec 7.3).
//
// Convenção de idioma e disciplina CloudKit-ready: idem `Livro` (spec 7/18/24).
// A unicidade (`tipo_periodo`, `ano`, `numero_periodo`) e `quantidade_alvo > 0`
// são validadas em código (spec 7.3/8.6), não pelo store.

import Foundation
import SwiftData

@Model
final class Meta {

    /// Chave primária (spec 7.3 — `id`).
    var id: UUID = UUID()

    /// Tipo de período da meta (spec 7.3 — `tipo_periodo`).
    var tipo_periodo: tipo_periodo_meta = tipo_periodo_meta.anual

    /// Ano de referência da meta, ex.: 2026 (spec 7.3 — `ano`).
    var ano: Int = Calendar.current.component(.year, from: Date())

    /// Número do período dentro do ano: 1–12 (mensal), 1–4 (trimestral), 1–2
    /// (semestral) ou nulo (anual) (spec 7.3 — `numero_periodo`).
    var numero_periodo: Int?

    /// Quantidade-alvo de livros no período; deve ser maior que zero (spec 7.3/8.6).
    var quantidade_alvo: Int = 1

    /// Quando a meta foi atingida pela primeira vez; nulo até lá. Uma vez
    /// preenchido, não regride (regra em código, spec 11).
    var meta_atingida_em: Date?

    /// Quando a meta foi criada (spec 7.3 — `criado_em`).
    var criado_em: Date = Date()

    /// Última edição da meta (spec 7.3 — `atualizado_em`).
    var atualizado_em: Date = Date()

    // Cria uma nova meta para um período. Recebe tipo, ano, número do período
    // (conforme o tipo) e a quantidade-alvo; devolve a instância pronta para
    // inserir. A validação de coerência/unicidade acontece antes de inserir, no
    // GoalsViewModel (spec 8.6).
    init(
        tipo_periodo: tipo_periodo_meta,
        ano: Int,
        numero_periodo: Int?,
        quantidade_alvo: Int
    ) {
        self.id = UUID()
        self.tipo_periodo = tipo_periodo
        self.ano = ano
        self.numero_periodo = numero_periodo
        self.quantidade_alvo = quantidade_alvo
        self.meta_atingida_em = nil
        self.criado_em = Date()
        self.atualizado_em = Date()
    }
}
