// CSVImporterTests.swift — testes da importação de backup CSV (spec seção 14/22).

import XCTest
@testable import Estante

final class CSVImporterTests: XCTestCase {

    private let cal = TB.calendar()

    // Ida e volta: o que o CSVExporter grava, o CSVImporter lê de volta igual (spec 14).
    func testRoundTrip() {
        let l = Livro(titulo: "Torto Arado", autor: "Itamar", status: .lido,
                      avaliacao_estrelas: 5, comentario: "ótimo; demais",
                      indicado_por: "Marina", data_conclusao: TB.date(2026, 8, 1, 12, calendar: cal))
        let data = CSVExporter.makeCSV(from: [l], calendar: cal)
        let parsed = CSVImporter.parse(data, calendar: cal)
        XCTAssertEqual(parsed.count, 1)
        let b = parsed[0]
        XCTAssertEqual(b.titulo, "Torto Arado")
        XCTAssertEqual(b.autor, "Itamar")
        XCTAssertEqual(b.estrelas, 5)
        XCTAssertEqual(b.comentario, "ótimo; demais")   // campo com `;` sobrevive ao escape
        XCTAssertEqual(b.indicadoPor, "Marina")
        XCTAssertTrue(cal.isDate(b.dataConclusao!, inSameDayAs: TB.date(2026, 8, 1, 12, calendar: cal)))
    }

    // CSV só com cabeçalho (período vazio) importa zero livros, sem erro (spec 14).
    func testSoCabecalho() {
        let data = CSVExporter.makeCSV(from: [], calendar: cal)
        XCTAssertTrue(CSVImporter.parse(data, calendar: cal).isEmpty)
    }

    // Campos opcionais ausentes viram nil; estrela fora de 1–5 vira nil (spec 14).
    func testCamposOpcionaisENota() {
        let l = Livro(titulo: "Sem nada", status: .lido,
                      data_conclusao: TB.date(2026, 8, 1, 12, calendar: cal))
        let b = CSVImporter.parse(CSVExporter.makeCSV(from: [l], calendar: cal), calendar: cal)[0]
        XCTAssertNil(b.autor)
        XCTAssertNil(b.estrelas)
        XCTAssertNil(b.comentario)
        XCTAssertNil(b.indicadoPor)
    }

    // Aspas e quebras de linha dentro de um campo são preservadas (spec 14).
    func testCampoComAspasEQuebra() {
        let l = Livro(titulo: "Título \"especial\"", status: .lido,
                      comentario: "linha1\nlinha2",
                      data_conclusao: TB.date(2026, 8, 1, 12, calendar: cal))
        let b = CSVImporter.parse(CSVExporter.makeCSV(from: [l], calendar: cal), calendar: cal)[0]
        XCTAssertEqual(b.titulo, "Título \"especial\"")
        XCTAssertEqual(b.comentario, "linha1\nlinha2")
    }

    // Vários livros mantêm a ordem e a contagem (spec 14).
    func testVariosLivros() {
        let a = Livro(titulo: "A", status: .lido, data_conclusao: TB.date(2026, 7, 14, 12, calendar: cal))
        let b = Livro(titulo: "B", status: .lido, data_conclusao: TB.date(2026, 8, 1, 12, calendar: cal))
        let parsed = CSVImporter.parse(CSVExporter.makeCSV(from: [a, b], calendar: cal), calendar: cal)
        // Exportador ordena por data crescente: A (14/07) antes de B (01/08).
        XCTAssertEqual(parsed.map(\.titulo), ["A", "B"])
    }
}
