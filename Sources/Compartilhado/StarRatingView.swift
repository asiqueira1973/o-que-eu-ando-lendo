// StarRatingView.swift — seletor/visualizador de avaliação em estrelas (spec 8.3).
//
// De 1 a 5 estrelas. No modo interativo, tocar numa estrela define a nota; tocar
// de novo na MESMA estrela limpa a nota (volta a nulo) — regra do épico 8.3. A
// avaliação é opcional mesmo com status `lido` (spec 11/24). Também serve como
// visualização somente-leitura no feed/detalhe (`interactive: false`).

import SwiftUI

struct StarRatingView: View {
    /// Nota atual (1–5) ou nil quando não avaliado (spec 7.2).
    @Binding var rating: Int?
    var interactive: Bool = true
    var size: CGFloat = 38

    var body: some View {
        HStack(spacing: size * 0.26) {
            ForEach(1...5, id: \.self) { i in
                let preenchida = (rating ?? 0) >= i
                Image(systemName: preenchida ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(preenchida ? Palette.star : Palette.starEmpty)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard interactive else { return }
                        toggle(i)
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(interactive ? "Avaliação" : "Avaliação")
        .accessibilityValue(rating.map { "\($0) de 5 estrelas" } ?? "sem avaliação")
    }

    // Alterna a nota ao tocar na estrela `i`: se já é a nota atual, limpa (nil);
    // senão, define como `i` (spec 8.3).
    private func toggle(_ i: Int) {
        rating = (rating == i) ? nil : i
    }
}
