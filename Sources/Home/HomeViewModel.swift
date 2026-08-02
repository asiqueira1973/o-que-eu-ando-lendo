// HomeViewModel.swift — dados da tela inicial (spec seção 8.8/11).
//
// Deriva, a partir da lista de livros, tudo que a Home mostra: os 4 indicadores de
// período (mês/trimestre/semestre/ano correntes), a lista "lendo agora", o Top 3 do
// ano e o feed de lidos (mais recente primeiro). Lógica de período delegada ao
// PeriodCalculator/ReadingStats (spec 11), para tudo ficar testável (spec 22).

import Foundation

struct HomeViewModel {
    let livros: [Livro]
    var referencia: Date = Date()
    var calendar: Calendar = .current

    // Indicadores: livros `lido` do início de cada período corrente até hoje
    // (spec 8.8/11 — não é janela móvel). "Até hoje" = `referencia`.
    var indicadores: (mes: Int, trimestre: Int, semestre: Int, ano: Int) {
        func conta(_ tipo: tipo_periodo_meta) -> Int {
            let period = PeriodCalculator.currentPeriod(tipo, containing: referencia, calendar: calendar)
            return PeriodCalculator.countLidos(livros, in: period, upTo: referencia, calendar: calendar)
        }
        return (conta(.mensal), conta(.trimestral), conta(.semestral), conta(.anual))
    }

    /// Livros com status `lendo` (spec 8.8 — destacados no topo).
    var lendoAgora: [Livro] {
        livros.filter { $0.status == .lendo }
              .sorted { $0.atualizado_em > $1.atualizado_em }
    }

    /// Top 3 do ano corrente (spec 8.8/11).
    var top3: [Livro] {
        ReadingStats.top3DoAno(livros, calendar: calendar)
    }

    /// Feed: livros `lido` por `data_conclusao` decrescente (spec 8.8).
    var feed: [Livro] {
        livros.filter { $0.status == .lido }
              .sorted { ($0.data_conclusao ?? .distantPast) > ($1.data_conclusao ?? .distantPast) }
    }

    /// Instalação nova sem nenhum livro lido → estado vazio (spec 8.8).
    var temAlgumLido: Bool { livros.contains { $0.status == .lido } }

    // Mapa id→posição no ano de cada livro lido (spec 11), pré-calculado uma vez
    // para o feed não recalcular a posição por linha (spec 17 — Home rápida).
    var posicoesNoAno: [UUID: Int] {
        var mapa: [UUID: Int] = [:]
        let lidos = livros.filter { $0.status == .lido && $0.data_conclusao != nil }
        let porAno = Dictionary(grouping: lidos) { calendar.component(.year, from: $0.data_conclusao!) }
        for (_, doAno) in porAno {
            let ordenados = doAno.sorted { a, b in
                let da = a.data_conclusao ?? .distantPast
                let db = b.data_conclusao ?? .distantPast
                if da != db { return da < db }
                return a.criado_em < b.criado_em
            }
            for (i, livro) in ordenados.enumerated() { mapa[livro.id] = i + 1 }
        }
        return mapa
    }
}
