// TestSupport.swift — utilitários compartilhados pelos testes (spec seção 22).
//
// Facilita montar livros/metas de teste e datas em um calendário/fuso controlado,
// para exercitar a lógica pura de períodos, metas, trial e CSV sem UI/SwiftData.

import Foundation
@testable import Estante

enum TB {
    // Calendário gregoriano num fuso brasileiro fixo, para os testes não dependerem
    // do fuso da máquina (spec 11/22).
    static func calendar(_ tz: String = "America/Sao_Paulo") -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: tz)!
        return c
    }

    // Monta uma data (ano/mês/dia, hora opcional) no calendário dado.
    static func date(_ ano: Int, _ mes: Int, _ dia: Int, _ hora: Int = 12, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: ano, month: mes, day: dia, hour: hora)) ?? Date()
    }

    // Livro `lido` com data de conclusão e (opcional) estrelas/criado_em.
    static func lido(_ titulo: String, estrelas: Int? = nil, conclusao: Date, criado: Date? = nil) -> Livro {
        let l = Livro(titulo: titulo, status: .lido, avaliacao_estrelas: estrelas, data_conclusao: conclusao)
        if let criado { l.criado_em = criado }
        return l
    }
}
