// CSVExporter.swift — geração do CSV de livros lidos (spec seção 14).
//
// Lógica pura e testável (spec 22): recebe os livros e o período escolhido e
// devolve o conteúdo do arquivo. Formato exato da spec 14:
//   Colunas (nesta ordem): Título; Autor; Estrelas; Comentário; Indicado por; Data de conclusão
//   Encoding: UTF-8 COM BOM (compatibilidade com Excel em pt-BR)
//   Separador: ponto e vírgula (;)
//   Ordenação: por data de conclusão, crescente (diário de leitura)
//   Período sem livros: só a linha de cabeçalho, não um erro.

import Foundation

/// Escopo de período de uma exportação (spec 8.9/14). Define o filtro de datas e
/// o nome do arquivo.
enum ExportScope {
    case mes(ano: Int, mes: Int)
    case trimestre(ano: Int, numero: Int)
    case semestre(ano: Int, numero: Int)
    case ano(Int)
    case intervalo(inicio: Date, fim: Date)

    // Intervalo de datas [início, fim) usado para filtrar os livros (spec 14).
    // No intervalo customizado, `fim` é inclusivo (dia inteiro), então somamos 1
    // dia para virar o limite exclusivo.
    func dateInterval(calendar: Calendar = .current) -> DateInterval {
        switch self {
        case let .mes(ano, mes):
            return ReadingPeriod(tipo: .mensal, ano: ano, numero: mes).dateInterval(calendar: calendar)
        case let .trimestre(ano, numero):
            return ReadingPeriod(tipo: .trimestral, ano: ano, numero: numero).dateInterval(calendar: calendar)
        case let .semestre(ano, numero):
            return ReadingPeriod(tipo: .semestral, ano: ano, numero: numero).dateInterval(calendar: calendar)
        case let .ano(ano):
            return ReadingPeriod(tipo: .anual, ano: ano, numero: nil).dateInterval(calendar: calendar)
        case let .intervalo(inicio, fim):
            let start = calendar.startOfDay(for: inicio)
            let endDay = calendar.startOfDay(for: fim)
            let end = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
            return DateInterval(start: start, end: end)
        }
    }

    // Nome do arquivo exato da spec 14 (ex.: livros-lidos-2026-08.csv,
    // livros-lidos-2026-T3.csv, livros-lidos-2026-S2.csv, livros-lidos-2026.csv,
    // livros-lidos-2026-01-15_2026-03-20.csv).
    var fileName: String {
        switch self {
        case let .mes(ano, mes):
            return String(format: "livros-lidos-%04d-%02d.csv", ano, mes)
        case let .trimestre(ano, numero):
            return "livros-lidos-\(ano)-T\(numero).csv"
        case let .semestre(ano, numero):
            return "livros-lidos-\(ano)-S\(numero).csv"
        case let .ano(ano):
            return "livros-lidos-\(ano).csv"
        case let .intervalo(inicio, fim):
            return "livros-lidos-\(CSVExporter.isoDate(inicio))_\(CSVExporter.isoDate(fim)).csv"
        }
    }
}

enum CSVExporter {

    private static let separator = ";"
    private static let header = ["Título", "Autor", "Estrelas", "Comentário", "Indicado por", "Data de conclusão"]

    // Gera o conteúdo do CSV (spec 14) a partir de uma lista de livros já filtrada
    // por período. Filtra defensivamente para `lido` com `data_conclusao` e ordena
    // por data crescente. Devolve Data em UTF-8 COM BOM. Lista vazia → só cabeçalho.
    static func makeCSV(from livros: [Livro], calendar: Calendar = .current) -> Data {
        let ordenados = livros
            .filter { $0.status == .lido && $0.data_conclusao != nil }
            .sorted { ($0.data_conclusao ?? .distantPast) < ($1.data_conclusao ?? .distantPast) }

        var linhas = [header.map(escape).joined(separator: separator)]
        for livro in ordenados {
            let colunas = [
                livro.titulo,
                livro.autor ?? "",
                livro.avaliacao_estrelas.map(String.init) ?? "",
                livro.comentario ?? "",
                livro.indicado_por ?? "",
                livro.data_conclusao.map(brDate) ?? ""
            ]
            linhas.append(colunas.map(escape).joined(separator: separator))
        }

        let texto = linhas.joined(separator: "\r\n")
        // BOM UTF-8 (\u{FEFF}) para o Excel reconhecer a acentuação (spec 14).
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(texto.utf8))
        return data
    }

    // Escapa um campo de CSV: se contém separador, aspas ou quebra de linha, envolve
    // em aspas duplas e duplica as aspas internas (RFC 4180 — evita quebrar colunas).
    private static func escape(_ campo: String) -> String {
        if campo.contains(separator) || campo.contains("\"") || campo.contains("\n") || campo.contains("\r") {
            return "\"" + campo.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return campo
    }

    // Data no formato brasileiro DD/MM/AAAA da coluna "Data de conclusão" (spec 14).
    private static func brDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = .current
        f.timeZone = .current
        f.dateFormat = "dd/MM/yyyy"
        return f.string(from: date)
    }

    // Data no formato AAAA-MM-DD usada no nome de arquivo de intervalo (spec 14).
    static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = .current
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
