// Enums.swift — enumerações do modelo de dados (spec seção 7.4).
//
// Convenção de idioma não-negociável (instrução do produto / spec 18): os NOMES
// de enum e de caso seguem exatamente a seção 7.4, em português e snake_case
// (`status_livro`, `quero_ler`, `tipo_periodo_meta`, `mensal`...). Como o nome do
// caso já é snake_case, o `rawValue` persistido coincide com ele sem mapeamento.
// String-backed + Codable para o SwiftData guardar o valor de forma estável e
// deixar barata uma futura migração para CloudKit (spec 24/28).

import Foundation

/// Estado de leitura de um livro (spec 7.4 — enum `status_livro`).
enum status_livro: String, Codable, CaseIterable {
    case quero_ler
    case lendo
    case lido

    /// Rótulo de exibição em português para a UI (spec 15/16).
    var displayName: String {
        switch self {
        case .quero_ler: return "Quero ler"
        case .lendo: return "Lendo"
        case .lido: return "Lido"
        }
    }
}

/// Tipo de período de uma meta de leitura (spec 7.4 — enum `tipo_periodo_meta`).
enum tipo_periodo_meta: String, Codable, CaseIterable {
    case mensal
    case trimestral
    case semestral
    case anual

    /// Rótulo de exibição em português para a UI (spec 15/16).
    var displayName: String {
        switch self {
        case .mensal: return "Mensal"
        case .trimestral: return "Trimestral"
        case .semestral: return "Semestral"
        case .anual: return "Anual"
        }
    }

    // Faixa válida de `numero_periodo` para este tipo (spec 7.3): mensal 1–12,
    // trimestral 1–4, semestral 1–2, anual não usa (retorna nil).
    var numeroPeriodoRange: ClosedRange<Int>? {
        switch self {
        case .mensal: return 1...12
        case .trimestral: return 1...4
        case .semestral: return 1...2
        case .anual: return nil
        }
    }

    // Valida se um `numero_periodo` é coerente com o tipo (spec 7.3). Anual exige
    // numero_periodo nulo; os demais exigem um número dentro da faixa.
    func isValidNumeroPeriodo(_ numero: Int?) -> Bool {
        guard let range = numeroPeriodoRange else {
            return numero == nil // anual: numero_periodo deve ser nulo
        }
        guard let numero else { return false }
        return range.contains(numero)
    }
}
