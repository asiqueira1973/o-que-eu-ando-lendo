// AccessibilityLabels.swift — rótulos de VoiceOver (spec seção 17).
//
// Os cards ilustrados do feed são o ponto mais frágil de acessibilidade do app
// (design custom, spec 22/23); por isso cada um recebe um label descritivo em
// linguagem natural, ex.: "Livro: Torto Arado, 4 estrelas" (spec 17).

import Foundation

enum AccessibilityLabels {

    // Monta o label de VoiceOver de um livro para o feed/listas (spec 17). Inclui
    // título, autor (quando houver) e a avaliação em estrelas (ou "sem avaliação").
    static func book(_ livro: Livro) -> String {
        var partes = ["Livro: \(livro.titulo)"]
        if let autor = livro.autor, !autor.isEmpty {
            partes.append("de \(autor)")
        }
        if let estrelas = livro.avaliacao_estrelas {
            partes.append("\(estrelas) \(estrelas == 1 ? "estrela" : "estrelas")")
        } else {
            partes.append("sem avaliação")
        }
        return partes.joined(separator: ", ")
    }
}
