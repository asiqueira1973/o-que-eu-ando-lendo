// TrialGate.swift — regra do trial de 5 livros (spec seção 8.10/11).
//
// Portão (gate) que decide se salvar um livro NOVO deve ser interrompido pelo
// Paywall. Lógica pura e testável (spec 22): recebe a contagem atual de livros e o
// estado de compra. A contagem é sempre sobre os livros que EXISTEM agora (excluir
// libera vaga) — não é um contador histórico cumulativo (spec 11/24). Editar um
// livro já existente nunca passa por aqui (o gate só vale para criar, spec 8.2).

import Foundation

enum TrialGate {

    // Diz se a criação de um livro novo precisa passar pelo Paywall (spec 8.10).
    //  - totalLivros: quantos livros (de qualquer status) existem agora;
    //  - compraDesbloqueada: se a compra única já foi feita.
    // Regra: os 5 primeiros são livres; com 5 já existentes e sem compra, o 6º
    // dispara o Paywall (spec 8.10/11).
    static func precisaComprar(totalLivros: Int, compraDesbloqueada: Bool) -> Bool {
        if compraDesbloqueada { return false }
        return totalLivros >= AppConstants.trialLimit
    }
}
