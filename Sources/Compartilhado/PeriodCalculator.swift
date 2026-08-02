// PeriodCalculator.swift — cálculo puro de períodos de leitura (spec seção 11).
//
// Toda a matemática de mês/trimestre/semestre/ano vive aqui, sem UI e sem
// SwiftData, para ser testável de forma isolada (spec 22). Usa `Calendar.current`,
// ou seja, o fuso e o calendário do próprio aparelho (spec 11 — não é um fuso
// fixo). Regras de recorte (spec 11):
//   Trimestre: Q1 jan–mar, Q2 abr–jun, Q3 jul–set, Q4 out–dez.
//   Semestre:  S1 jan–jun, S2 jul–dez.

import Foundation

/// Um período concreto de leitura (tipo + ano + número), com seu intervalo de
/// datas. Ex.: mensal/2026/8 = agosto de 2026 (spec 7.3/11).
struct ReadingPeriod: Equatable {
    let tipo: tipo_periodo_meta
    let ano: Int
    /// 1–12 (mensal), 1–4 (trimestral), 1–2 (semestral) ou nil (anual) — spec 7.3.
    let numero: Int?

    // Intervalo de datas [início, fim) do período (spec 11). O fim é exclusivo:
    // o primeiro instante do período seguinte. Calculado no calendário do aparelho.
    func dateInterval(calendar: Calendar = .current) -> DateInterval {
        let startMonth: Int
        let monthSpan: Int
        switch tipo {
        case .mensal:      startMonth = numero ?? 1;                 monthSpan = 1
        case .trimestral:  startMonth = ((numero ?? 1) - 1) * 3 + 1; monthSpan = 3
        case .semestral:   startMonth = ((numero ?? 1) - 1) * 6 + 1; monthSpan = 6
        case .anual:       startMonth = 1;                            monthSpan = 12
        }
        var comps = DateComponents()
        comps.year = ano
        comps.month = startMonth
        comps.day = 1
        let start = calendar.date(from: comps) ?? Date()
        let end = calendar.date(byAdding: .month, value: monthSpan, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    // Diz se uma data cai neste período, usando intervalo semiaberto [início, fim)
    // para não contar em dobro na virada de período (spec 11).
    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let interval = dateInterval(calendar: calendar)
        return date >= interval.start && date < interval.end
    }

    /// Rótulo curto do período para UI/nome de arquivo (spec 14/16). Ex.: "agosto",
    /// "3º trimestre", "2º semestre", "2026".
    func shortLabel() -> String {
        switch tipo {
        case .mensal:      return "\(PeriodCalculator.nomeDoMes(numero ?? 1))"
        case .trimestral:  return "\(numero ?? 1)º trimestre"
        case .semestral:   return "\(numero ?? 1)º semestre"
        case .anual:       return "\(ano)"
        }
    }
}

enum PeriodCalculator {

    // Trimestre (1–4) de um mês (spec 11 — Q1 jan–mar ... Q4 out–dez).
    static func quarter(of month: Int) -> Int { (month - 1) / 3 + 1 }

    // Semestre (1–2) de um mês (spec 11 — S1 jan–jun, S2 jul–dez).
    static func semester(of month: Int) -> Int { month <= 6 ? 1 : 2 }

    // Período corrente (o que contém `date`) para um tipo, no calendário do
    // aparelho (spec 11 — indicadores "do início do período corrente até hoje").
    static func currentPeriod(_ tipo: tipo_periodo_meta,
                              containing date: Date = Date(),
                              calendar: Calendar = .current) -> ReadingPeriod {
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        switch tipo {
        case .mensal:     return ReadingPeriod(tipo: .mensal, ano: year, numero: month)
        case .trimestral: return ReadingPeriod(tipo: .trimestral, ano: year, numero: quarter(of: month))
        case .semestral:  return ReadingPeriod(tipo: .semestral, ano: year, numero: semester(of: month))
        case .anual:      return ReadingPeriod(tipo: .anual, ano: year, numero: nil)
        }
    }

    // Conta livros `lido` com `data_conclusao` dentro do período (spec 8.8/11).
    // `upTo` limita a contagem "até hoje" nos indicadores da Home (spec 11 — não é
    // janela móvel); quando nil, conta o período inteiro (usado no cartão, spec 11).
    static func countLidos(_ livros: [Livro],
                           in period: ReadingPeriod,
                           upTo limit: Date? = nil,
                           calendar: Calendar = .current) -> Int {
        livros.filter { livro in
            guard livro.status == .lido, let d = livro.data_conclusao else { return false }
            if let limit, d > limit { return false }
            return period.contains(d, calendar: calendar)
        }.count
    }

    /// Nome do mês em português (spec 15/16). 1 = janeiro ... 12 = dezembro.
    static func nomeDoMes(_ mes: Int) -> String {
        let nomes = ["janeiro", "fevereiro", "março", "abril", "maio", "junho",
                     "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]
        guard mes >= 1, mes <= 12 else { return "" }
        return nomes[mes - 1]
    }
}
