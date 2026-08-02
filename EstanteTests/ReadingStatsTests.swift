// ReadingStatsTests.swift — testes de Top 3 e posição no período (spec 8.8/8.11/11/22).

import XCTest
@testable import Estante

final class ReadingStatsTests: XCTestCase {

    private let cal = TB.calendar()

    // Top 3 ordena por estrelas desc; empate por data de conclusão desc; ignora
    // livros sem avaliação (spec 8.8/11).
    func testTop3OrdemEEmpate() {
        let a = TB.lido("A", estrelas: 5, conclusao: TB.date(2026, 3, 1, 12, calendar: cal))
        let b = TB.lido("B", estrelas: 5, conclusao: TB.date(2026, 6, 1, 12, calendar: cal)) // empate 5★, mais recente
        let c = TB.lido("C", estrelas: 4, conclusao: TB.date(2026, 7, 1, 12, calendar: cal))
        let semNota = TB.lido("D", estrelas: nil, conclusao: TB.date(2026, 7, 20, 12, calendar: cal))
        let top = ReadingStats.top3DoAno([a, b, c, semNota], ano: 2026, calendar: cal)
        XCTAssertEqual(top.map(\.titulo), ["B", "A", "C"]) // B antes de A por desempate de data
    }

    // Mostra menos de 3 quando não há elegíveis suficientes (spec 8.8).
    func testTop3ComPoucos() {
        let a = TB.lido("A", estrelas: 3, conclusao: TB.date(2026, 3, 1, 12, calendar: cal))
        XCTAssertEqual(ReadingStats.top3DoAno([a], ano: 2026, calendar: cal).count, 1)
    }

    // Posição no ano: ordem crescente por data; desempate por criado_em (spec 11).
    func testPosicaoNoPeriodo() {
        let a = TB.lido("A", conclusao: TB.date(2026, 2, 1, 12, calendar: cal))
        let b = TB.lido("B", conclusao: TB.date(2026, 5, 1, 12, calendar: cal))
        let alvo = TB.lido("Alvo", conclusao: TB.date(2026, 8, 1, 12, calendar: cal))
        let pos = ReadingStats.posicaoNoPeriodo(alvo, tipo: .anual, todos: [b, alvo, a], calendar: cal)
        XCTAssertEqual(pos, 3) // 3º livro do ano
    }

    // Desempate de posição por criado_em quando as datas de conclusão coincidem (spec 11/24).
    func testPosicaoDesempatePorCriadoEm() {
        let mesmaData = TB.date(2026, 8, 1, 12, calendar: cal)
        let primeiro = TB.lido("Primeiro", conclusao: mesmaData, criado: TB.date(2026, 7, 1, 9, calendar: cal))
        let segundo = TB.lido("Segundo", conclusao: mesmaData, criado: TB.date(2026, 7, 1, 10, calendar: cal))
        XCTAssertEqual(ReadingStats.posicaoNoPeriodo(primeiro, tipo: .anual, todos: [segundo, primeiro], calendar: cal), 1)
        XCTAssertEqual(ReadingStats.posicaoNoPeriodo(segundo, tipo: .anual, todos: [segundo, primeiro], calendar: cal), 2)
    }
}
