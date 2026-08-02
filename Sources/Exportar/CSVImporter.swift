// CSVImporter.swift — leitura do CSV de backup (spec seção 14).
//
// Contraparte do CSVExporter: lê um arquivo no MESMO formato exportado (seção 14)
// e devolve os livros contidos nele. Como a exportação só inclui livros `lido`
// (spec 14), a importação restaura livros com status `lido`. Lógica pura e testável
// (spec 22): faz o parsing respeitando aspas, `;` e o BOM UTF-8; a gravação/
// sobrescrita do banco fica no BackupRestore.

import Foundation

/// Um livro lido a partir de uma linha do CSV (spec 14).
struct ImportedBook: Equatable {
    var titulo: String
    var autor: String?
    var estrelas: Int?
    var comentario: String?
    var indicadoPor: String?
    var dataConclusao: Date?
}

enum CSVImporter {

    // Lê o conteúdo do CSV e devolve os livros (spec 14). Ignora o BOM, o cabeçalho
    // e linhas sem título. Datas em DD/MM/AAAA; estrelas 1–5 (fora disso vira nil).
    static func parse(_ data: Data, calendar: Calendar = .current) -> [ImportedBook] {
        var bytes = data
        if bytes.starts(with: [0xEF, 0xBB, 0xBF]) { bytes.removeFirst(3) } // remove BOM
        guard let texto = String(data: bytes, encoding: .utf8) else { return [] }

        let registros = parseRecords(texto, delimiter: ";")
        guard registros.count > 1 else { return [] } // vazio ou só cabeçalho

        var resultado: [ImportedBook] = []
        for (idx, campos) in registros.enumerated() {
            if idx == 0 { continue }                             // pula cabeçalho
            if campos.allSatisfy({ $0.isEmpty }) { continue }    // linha em branco
            let titulo = col(campos, 0).trimmingCharacters(in: .whitespacesAndNewlines)
            if titulo.isEmpty { continue }                       // sem título → ignora
            resultado.append(ImportedBook(
                titulo: titulo,
                autor: nilSeVazio(col(campos, 1)),
                estrelas: parseEstrelas(col(campos, 2)),
                comentario: nilSeVazio(col(campos, 3)),
                indicadoPor: nilSeVazio(col(campos, 4)),
                dataConclusao: parseData(col(campos, 5), calendar: calendar)
            ))
        }
        return resultado
    }

    // Parser RFC 4180 (com separador configurável): respeita aspas, aspas duplas
    // escapadas ("") e quebras \r\n. Devolve linhas de campos (spec 14).
    //
    // Percorre por Unicode.Scalar (não por Character): em Swift, "\r\n" é UM único
    // grapheme Character, o que faria o separador de linha nunca casar. Em scalars,
    // \r e \n são separados.
    static func parseRecords(_ text: String, delimiter: Character) -> [[String]] {
        let delim = delimiter.unicodeScalars.first!
        let quote: Unicode.Scalar = "\""
        let cr: Unicode.Scalar = "\r"
        let lf: Unicode.Scalar = "\n"

        var records: [[String]] = []
        var field = String.UnicodeScalarView()
        var record: [String] = []
        var inQuotes = false
        let scalars = Array(text.unicodeScalars)
        var i = 0
        while i < scalars.count {
            let c = scalars[i]
            if inQuotes {
                if c == quote {
                    if i + 1 < scalars.count && scalars[i + 1] == quote {
                        field.append(quote); i += 1       // "" → aspas literal
                    } else {
                        inQuotes = false                  // fecha campo entre aspas
                    }
                } else {
                    field.append(c)
                }
            } else {
                switch c {
                case quote: inQuotes = true
                case delim: record.append(String(field)); field = String.UnicodeScalarView()
                case lf: record.append(String(field)); field = String.UnicodeScalarView(); records.append(record); record = []
                case cr: break                            // ignora \r (o \n encerra a linha)
                default: field.append(c)
                }
            }
            i += 1
        }
        if !String(field).isEmpty || !record.isEmpty {
            record.append(String(field))
            records.append(record)
        }
        return records
    }

    // MARK: - Helpers

    private static func col(_ campos: [String], _ i: Int) -> String {
        i < campos.count ? campos[i] : ""
    }

    private static func nilSeVazio(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private static func parseEstrelas(_ s: String) -> Int? {
        guard let n = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)), (1...5).contains(n) else { return nil }
        return n
    }

    private static func parseData(_ s: String, calendar: Calendar) -> Date? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.dateFormat = "dd/MM/yyyy"
        return f.date(from: t)
    }
}
