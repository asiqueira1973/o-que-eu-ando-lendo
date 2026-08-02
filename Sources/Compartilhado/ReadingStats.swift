// ReadingStats.swift — cálculos de estatística de leitura (spec seção 8.8/11).
//
// Lógica pura sobre uma lista de livros (sem UI/SwiftData), testável (spec 22):
// Top 3 do ano e posição de um livro dentro de um período (usada no cartão, 8.11).

import Foundation

enum ReadingStats {

    // Top 3 do ano (spec 8.8/11): entre livros `lido` E com avaliação preenchida,
    // com `data_conclusao` no ano `ano` (default: ano corrente), ordena por
    // estrelas desc e, no empate, por `data_conclusao` desc; devolve até 3.
    static func top3DoAno(_ livros: [Livro],
                          ano: Int? = nil,
                          calendar: Calendar = .current) -> [Livro] {
        let anoRef = ano ?? calendar.component(.year, from: Date())
        let period = ReadingPeriod(tipo: .anual, ano: anoRef, numero: nil)
        return livros
            .filter { livro in
                livro.status == .lido
                    && livro.avaliacao_estrelas != nil
                    && (livro.data_conclusao.map { period.contains($0, calendar: calendar) } ?? false)
            }
            .sorted { a, b in
                let ea = a.avaliacao_estrelas ?? 0
                let eb = b.avaliacao_estrelas ?? 0
                if ea != eb { return ea > eb }
                return (a.data_conclusao ?? .distantPast) > (b.data_conclusao ?? .distantPast)
            }
            .prefix(3)
            .map { $0 }
    }

    // Posição do livro dentro do período do tipo escolhido (spec 11 — cartão 8.11).
    // X = quantos livros `lido` têm `data_conclusao` no MESMO período (mesmo
    // mês/trimestre/semestre/ano do livro), ordenados por `data_conclusao` crescente
    // e, no empate, por `criado_em` crescente, até e incluindo o próprio livro.
    static func posicaoNoPeriodo(_ livro: Livro,
                                 tipo: tipo_periodo_meta,
                                 todos: [Livro],
                                 calendar: Calendar = .current) -> Int {
        guard let data = livro.data_conclusao else { return 0 }
        let period = PeriodCalculator.currentPeriod(tipo, containing: data, calendar: calendar)
        let mesmoPeriodo = todos
            .filter { l in
                l.status == .lido && (l.data_conclusao.map { period.contains($0, calendar: calendar) } ?? false)
            }
            .sorted { a, b in
                let da = a.data_conclusao ?? .distantPast
                let db = b.data_conclusao ?? .distantPast
                if da != db { return da < db }
                return a.criado_em < b.criado_em
            }
        if let idx = mesmoPeriodo.firstIndex(where: { $0.id == livro.id }) {
            return idx + 1
        }
        return mesmoPeriodo.count
    }

    // Período concreto (tipo+ano+numero) que contém a `data_conclusao` do livro
    // (spec 8.11) — usado pelo cartão para procurar uma meta do mesmo período.
    static func periodo(de livro: Livro,
                        tipo: tipo_periodo_meta,
                        calendar: Calendar = .current) -> ReadingPeriod? {
        guard let data = livro.data_conclusao else { return nil }
        return PeriodCalculator.currentPeriod(tipo, containing: data, calendar: calendar)
    }
}
