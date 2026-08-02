// Formatters.swift — formatação de datas para exibição (spec 8.2/8.8/16).
//
// Formatos de exibição em português do Brasil, no calendário/fuso do aparelho
// (spec 11). São só para a UI — o CSV tem seu próprio formatador exato (spec 14,
// em CSVExporter).

import Foundation

enum AppDate {

    // "DD/MM" — usado nas datas compactas do feed e do detalhe (spec 8.8/16).
    static func curto(_ date: Date) -> String {
        formatar(date, formato: "dd/MM")
    }

    // "DD/MM/AAAA" — usado nos campos de data do cadastro (spec 8.1/16).
    static func completo(_ date: Date) -> String {
        formatar(date, formato: "dd/MM/yyyy")
    }

    private static func formatar(_ date: Date, formato: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.calendar = .current
        f.timeZone = .current
        f.dateFormat = formato
        return f.string(from: date)
    }
}
