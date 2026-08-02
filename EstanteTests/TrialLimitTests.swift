// TrialLimitTests.swift — testes do portão do trial (spec seção 8.10/11/22).

import XCTest
@testable import Estante

final class TrialLimitTests: XCTestCase {

    // Os 5 primeiros são livres (spec 8.10).
    func testPrimeirosCincoLivres() {
        for total in 0..<5 {
            XCTAssertFalse(TrialGate.precisaComprar(totalLivros: total, compraDesbloqueada: false),
                           "total=\(total) deveria ser livre")
        }
    }

    // O 6º (com 5 já existentes) sem compra dispara o Paywall (spec 8.10/11).
    func testSextoBloqueia() {
        XCTAssertTrue(TrialGate.precisaComprar(totalLivros: 5, compraDesbloqueada: false))
    }

    // Com a compra feita, nunca bloqueia (spec 8.10).
    func testCompraDesbloqueiaTudo() {
        XCTAssertFalse(TrialGate.precisaComprar(totalLivros: 50, compraDesbloqueada: true))
    }

    // Contagem é sobre os livros que existem AGORA — excluir libera vaga (spec 11/24).
    // Se havia 6 e um foi excluído, restam 5 → criar o próximo volta a bloquear em 5.
    func testExclusaoLiberaVaga() {
        XCTAssertTrue(TrialGate.precisaComprar(totalLivros: 5, compraDesbloqueada: false))
        // após excluir um, total = 4 → livre novamente
        XCTAssertFalse(TrialGate.precisaComprar(totalLivros: 4, compraDesbloqueada: false))
    }
}
