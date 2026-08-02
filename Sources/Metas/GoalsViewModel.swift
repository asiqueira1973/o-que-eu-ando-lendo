// GoalsViewModel.swift — regras de criação/validação de metas (spec seção 8.6/11).
//
// Lógica pura e testável (spec 22): valida a criação de uma meta antes de inserir.
// Regras: não pode haver duas metas para o mesmo `tipo_periodo` + `ano` +
// `numero_periodo` (spec 7.3/11), e `quantidade_alvo` precisa ser maior que zero
// (spec 8.6). O progresso é sempre recalculado a partir de `livros` (sem FK, spec 11).

import Foundation

enum GoalsViewModel {

    /// Motivo pelo qual uma meta não pode ser criada (spec 8.6/12).
    enum ValidationError {
        case duplicada        // já existe meta para este tipo+período (spec 12)
        case alvoInvalido     // quantidade-alvo precisa ser > 0 (spec 8.6)
        case numeroInvalido   // numero_periodo incoerente com o tipo (spec 7.3)

        var mensagem: String {
            switch self {
            case .duplicada: return "Já existe uma meta para este período."
            case .alvoInvalido: return "A quantidade precisa ser maior que zero."
            case .numeroInvalido: return "Período inválido para este tipo de meta."
            }
        }
    }

    // Valida os dados de uma nova meta contra as metas existentes (spec 8.6/11).
    // Devolve nil quando está tudo certo, ou o erro correspondente.
    static func validar(tipo: tipo_periodo_meta,
                        ano: Int,
                        numero: Int?,
                        alvo: Int,
                        existentes: [Meta]) -> ValidationError? {
        guard alvo > 0 else { return .alvoInvalido }
        guard tipo.isValidNumeroPeriodo(numero) else { return .numeroInvalido }
        let jaExiste = existentes.contains {
            $0.tipo_periodo == tipo && $0.ano == ano && $0.numero_periodo == numero
        }
        if jaExiste { return .duplicada }
        return nil
    }

    /// Progresso atual de uma meta (livros lidos no período, spec 8.6/11).
    static func progresso(da meta: Meta, livros: [Livro]) -> Int {
        GoalEvaluator.progresso(da: meta, livros: livros)
    }
}
