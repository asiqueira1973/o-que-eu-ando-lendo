// PeriodCalculatorTests.swift — testes do cálculo de períodos (spec seção 11/22).
//
// Cobre trimestre/semestre, os intervalos de cada tipo de período, o recorte
// semiaberto na virada de mês/ano e a contagem "até hoje" dos indicadores.

import XCTest
@testable import Estante

final class PeriodCalculatorTests: XCTestCase {

    private let cal = TB.calendar()

    // Trimestre: Q1 jan–mar ... Q4 out–dez (spec 11).
    func testTrimestre() {
        XCTAssertEqual(PeriodCalculator.quarter(of: 1), 1)
        XCTAssertEqual(PeriodCalculator.quarter(of: 3), 1)
        XCTAssertEqual(PeriodCalculator.quarter(of: 4), 2)
        XCTAssertEqual(PeriodCalculator.quarter(of: 7), 3)
        XCTAssertEqual(PeriodCalculator.quarter(of: 12), 4)
    }

    // Semestre: S1 jan–jun, S2 jul–dez (spec 11).
    func testSemestre() {
        XCTAssertEqual(PeriodCalculator.semester(of: 6), 1)
        XCTAssertEqual(PeriodCalculator.semester(of: 7), 2)
        XCTAssertEqual(PeriodCalculator.semester(of: 12), 2)
    }

    // Intervalo de agosto/2026 = [01/08, 01/09) (spec 11).
    func testIntervaloMensal() {
        let p = ReadingPeriod(tipo: .mensal, ano: 2026, numero: 8)
        let i = p.dateInterval(calendar: cal)
        XCTAssertEqual(i.start, TB.date(2026, 8, 1, 0, calendar: cal))
        XCTAssertEqual(i.end, TB.date(2026, 9, 1, 0, calendar: cal))
    }

    // Intervalo do 3º trimestre/2026 = [01/07, 01/10) (spec 11).
    func testIntervaloTrimestral() {
        let p = ReadingPeriod(tipo: .trimestral, ano: 2026, numero: 3)
        let i = p.dateInterval(calendar: cal)
        XCTAssertEqual(i.start, TB.date(2026, 7, 1, 0, calendar: cal))
        XCTAssertEqual(i.end, TB.date(2026, 10, 1, 0, calendar: cal))
    }

    // Recorte semiaberto: 31/12 conta no ano; 01/01 do ano seguinte não (spec 11).
    func testViradaDeAno() {
        let ano = ReadingPeriod(tipo: .anual, ano: 2026, numero: nil)
        XCTAssertTrue(ano.contains(TB.date(2026, 12, 31, 23, calendar: cal), calendar: cal))
        XCTAssertFalse(ano.contains(TB.date(2027, 1, 1, 0, calendar: cal), calendar: cal))
    }

    // Virada de mês: 31/08 conta em agosto; 01/09 não (spec 11).
    func testViradaDeMes() {
        let ago = ReadingPeriod(tipo: .mensal, ano: 2026, numero: 8)
        XCTAssertTrue(ago.contains(TB.date(2026, 8, 31, 20, calendar: cal), calendar: cal))
        XCTAssertFalse(ago.contains(TB.date(2026, 9, 1, 0, calendar: cal), calendar: cal))
    }

    // Indicadores contam só do início do período até "hoje" (spec 8.8/11).
    func testContagemAteHoje() {
        let hoje = TB.date(2026, 8, 10, 12, calendar: cal)
        let livros = [
            TB.lido("A", conclusao: TB.date(2026, 8, 3, 12, calendar: cal)),
            TB.lido("B", conclusao: TB.date(2026, 8, 20, 12, calendar: cal)), // futuro relativo a hoje
            TB.lido("C", conclusao: TB.date(2026, 7, 1, 12, calendar: cal))   // fora do mês
        ]
        let mes = PeriodCalculator.currentPeriod(.mensal, containing: hoje, calendar: cal)
        XCTAssertEqual(PeriodCalculator.countLidos(livros, in: mes, upTo: hoje, calendar: cal), 1)
    }

    // Fuso do aparelho: uma conclusão perto da meia-noite cai no dia local, não em UTC.
    func testFusoHorario() {
        let calSP = TB.calendar("America/Sao_Paulo") // UTC-3
        // 01/08 01:00 em SP ainda é 31/07 22:00 em UTC — deve contar em agosto no fuso local.
        let d = calSP.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 1))!
        let ago = ReadingPeriod(tipo: .mensal, ano: 2026, numero: 8)
        XCTAssertTrue(ago.contains(d, calendar: calSP))
    }
}
