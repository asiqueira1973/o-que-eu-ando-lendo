// CSVExporterTests.swift — testes do CSV de exportação (spec seção 14/22).

import XCTest
@testable import Estante

final class CSVExporterTests: XCTestCase {

    private let cal = TB.calendar()

    private func texto(_ data: Data) -> String {
        // Remove o BOM UTF-8 para inspecionar o conteúdo.
        var d = data
        if d.starts(with: [0xEF, 0xBB, 0xBF]) { d.removeFirst(3) }
        return String(data: d, encoding: .utf8) ?? ""
    }

    // Período vazio gera só o cabeçalho, não erro (spec 14).
    func testVazioSoCabecalho() {
        let data = CSVExporter.makeCSV(from: [], calendar: cal)
        let linhas = texto(data).components(separatedBy: "\r\n")
        XCTAssertEqual(linhas.count, 1)
        XCTAssertEqual(linhas[0], "Título;Autor;Estrelas;Comentário;Indicado por;Data de conclusão")
    }

    // Sempre grava com BOM UTF-8 (compatibilidade com Excel, spec 14).
    func testTemBOM() {
        let data = CSVExporter.makeCSV(from: [], calendar: cal)
        XCTAssertTrue(data.starts(with: [0xEF, 0xBB, 0xBF]))
    }

    // Colunas, separador `;`, data DD/MM/AAAA e ordem crescente por data (spec 14).
    func testLinhaFormatada() {
        let l1 = Livro(titulo: "Torto Arado", autor: "Itamar Vieira Junior", status: .lido,
                       avaliacao_estrelas: 5, data_conclusao: TB.date(2026, 8, 1, 12, calendar: cal))
        let l2 = Livro(titulo: "Klara e o Sol", autor: "Kazuo Ishiguro", status: .lido,
                       avaliacao_estrelas: 4, data_conclusao: TB.date(2026, 7, 14, 12, calendar: cal))
        let linhas = texto(CSVExporter.makeCSV(from: [l1, l2], calendar: cal)).components(separatedBy: "\r\n")
        // Ordem crescente: Klara (14/07) antes de Torto Arado (01/08).
        XCTAssertEqual(linhas[1], "Klara e o Sol;Kazuo Ishiguro;4;;;14/07/2026")
        XCTAssertEqual(linhas[2], "Torto Arado;Itamar Vieira Junior;5;;;01/08/2026")
    }

    // Campos com `;` ou aspas são escapados com aspas duplas (evita quebrar colunas).
    func testEscapeDeCampo() {
        let l = Livro(titulo: "Título; com ponto e vírgula", status: .lido,
                      comentario: "ele disse \"ótimo\"",
                      data_conclusao: TB.date(2026, 8, 1, 12, calendar: cal))
        let linha = texto(CSVExporter.makeCSV(from: [l], calendar: cal)).components(separatedBy: "\r\n")[1]
        XCTAssertTrue(linha.contains("\"Título; com ponto e vírgula\""))
        XCTAssertTrue(linha.contains("\"ele disse \"\"ótimo\"\"\""))
    }

    // Estrelas/campos opcionais ausentes viram célula vazia (spec 14).
    func testCamposOpcionaisVazios() {
        let l = Livro(titulo: "Sem nada", status: .lido,
                      data_conclusao: TB.date(2026, 8, 1, 12, calendar: cal))
        let linha = texto(CSVExporter.makeCSV(from: [l], calendar: cal)).components(separatedBy: "\r\n")[1]
        XCTAssertEqual(linha, "Sem nada;;;;;01/08/2026")
    }

    // Nomes de arquivo exatos por escopo (spec 14).
    func testNomesDeArquivo() {
        XCTAssertEqual(ExportScope.mes(ano: 2026, mes: 8).fileName, "livros-lidos-2026-08.csv")
        XCTAssertEqual(ExportScope.trimestre(ano: 2026, numero: 3).fileName, "livros-lidos-2026-T3.csv")
        XCTAssertEqual(ExportScope.semestre(ano: 2026, numero: 2).fileName, "livros-lidos-2026-S2.csv")
        XCTAssertEqual(ExportScope.ano(2026).fileName, "livros-lidos-2026.csv")
        let inicio = TB.date(2026, 1, 15, 12, calendar: cal)
        let fim = TB.date(2026, 3, 20, 12, calendar: cal)
        XCTAssertEqual(ExportScope.intervalo(inicio: inicio, fim: fim).fileName,
                       "livros-lidos-2026-01-15_2026-03-20.csv")
    }
}
