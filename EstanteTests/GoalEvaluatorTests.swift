// GoalEvaluatorTests.swift — testes de "meta batida" (spec seção 8.7/11/22).

import XCTest
@testable import Estante

final class GoalEvaluatorTests: XCTestCase {

    private let cal = TB.calendar()

    // Meta atingida pela primeira vez ao salvar o livro que fecha a contagem (spec 8.7).
    func testMetaBatidaPrimeiraVez() {
        let meta = Meta(tipo_periodo: .mensal, ano: 2026, numero_periodo: 8, quantidade_alvo: 2)
        let livros = [
            TB.lido("A", conclusao: TB.date(2026, 8, 1, 12, calendar: cal)),
            TB.lido("B", conclusao: TB.date(2026, 8, 5, 12, calendar: cal))
        ]
        let batidas = GoalEvaluator.metasBatidas(aoConcluir: TB.date(2026, 8, 5, 12, calendar: cal),
                                                 metas: [meta], livros: livros, calendar: cal)
        XCTAssertEqual(batidas.count, 1)
    }

    // Meta já com `meta_atingida_em` preenchido não dispara de novo (spec 11 — não repete).
    func testNaoRepeteSeJaAtingida() {
        let meta = Meta(tipo_periodo: .mensal, ano: 2026, numero_periodo: 8, quantidade_alvo: 2)
        meta.meta_atingida_em = Date()
        let livros = [
            TB.lido("A", conclusao: TB.date(2026, 8, 1, 12, calendar: cal)),
            TB.lido("B", conclusao: TB.date(2026, 8, 5, 12, calendar: cal))
        ]
        let batidas = GoalEvaluator.metasBatidas(aoConcluir: TB.date(2026, 8, 5, 12, calendar: cal),
                                                 metas: [meta], livros: livros, calendar: cal)
        XCTAssertTrue(batidas.isEmpty)
    }

    // Edição retroativa para período de meta já batida não dispara mensagem (spec 8.7/11).
    func testEdicaoRetroativaNaoDispara() {
        let meta = Meta(tipo_periodo: .anual, ano: 2026, numero_periodo: nil, quantidade_alvo: 1)
        meta.meta_atingida_em = TB.date(2026, 3, 1, 12, calendar: cal) // já batida antes
        let livros = [TB.lido("A", conclusao: TB.date(2026, 2, 1, 12, calendar: cal))]
        let batidas = GoalEvaluator.metasBatidas(aoConcluir: TB.date(2026, 2, 1, 12, calendar: cal),
                                                 metas: [meta], livros: livros, calendar: cal)
        XCTAssertTrue(batidas.isEmpty)
    }

    // Um livro pode bater mais de uma meta ao mesmo tempo (spec 8.7).
    func testMultiplasMetasBatidas() {
        let mensal = Meta(tipo_periodo: .mensal, ano: 2026, numero_periodo: 8, quantidade_alvo: 1)
        let anual = Meta(tipo_periodo: .anual, ano: 2026, numero_periodo: nil, quantidade_alvo: 1)
        let livros = [TB.lido("A", conclusao: TB.date(2026, 8, 3, 12, calendar: cal))]
        let batidas = GoalEvaluator.metasBatidas(aoConcluir: TB.date(2026, 8, 3, 12, calendar: cal),
                                                 metas: [mensal, anual], livros: livros, calendar: cal)
        XCTAssertEqual(batidas.count, 2)
    }

    // Progresso é a contagem de lidos no período (spec 8.6).
    func testProgresso() {
        let meta = Meta(tipo_periodo: .mensal, ano: 2026, numero_periodo: 8, quantidade_alvo: 5)
        let livros = [
            TB.lido("A", conclusao: TB.date(2026, 8, 1, 12, calendar: cal)),
            TB.lido("B", conclusao: TB.date(2026, 8, 9, 12, calendar: cal)),
            TB.lido("C", conclusao: TB.date(2026, 7, 9, 12, calendar: cal)) // fora do mês
        ]
        XCTAssertEqual(GoalEvaluator.progresso(da: meta, livros: livros, calendar: cal), 2)
    }
}
