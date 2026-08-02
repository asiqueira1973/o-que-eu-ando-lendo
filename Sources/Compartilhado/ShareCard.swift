// ShareCard.swift — a arte 1:1 do cartão compartilhável (spec seção 8.11/16).
//
// Composição quadrada (1080×1080 no export, padrão de post de feed): fundo colorido
// da paleta viva, foto/lombada do livro em destaque, título e autor, e o número
// "X" ou a fração "X/Y" como elemento central (spec 16). Tudo dimensionado a partir
// de `side` para servir tanto ao preview na tela quanto ao render em alta resolução
// via `ImageRenderer` (spec 4). É só uma View — não grava nada no banco (spec 8.11).

import SwiftUI

struct ShareCard: View {
    /// Lado do quadrado (pt na tela, ou 1080 no export).
    let side: CGFloat
    let titulo: String
    let autor: String?
    /// Cor determinística da lombada do livro (spec 16).
    let spineColor: Color
    /// Foto já carregada (sync) ou nil → mostra a lombada (spec 8.11/16).
    let coverImage: UIImage?
    /// Cor de fundo do cartão, escolhida da paleta (spec 16).
    let bgColor: Color
    /// Numerador "X" (posição do livro no período, spec 11).
    let numeradorX: Int
    /// Denominador "Y" quando existe meta do período; nil mostra só "X" (spec 11/8.11).
    let denominadorY: Int?
    /// Legenda de baixo, copy da spec 15 (com ou sem meta).
    let legenda: String

    private var onColor: Color { .white }

    var body: some View {
        ZStack {
            bgColor
            // Círculos decorativos suaves (spec 16 — design de referência).
            Circle().fill(Color.white.opacity(0.12))
                .frame(width: side * 0.45, height: side * 0.45)
                .offset(x: side * 0.34, y: -side * 0.34)
            Circle().fill(Color.black.opacity(0.10))
                .frame(width: side * 0.38, height: side * 0.38)
                .offset(x: -side * 0.32, y: side * 0.36)

            VStack(spacing: side * 0.03) {
                // Capa/lombada do livro em destaque.
                Group {
                    if let coverImage {
                        Image(uiImage: coverImage)
                            .resizable().scaledToFill()
                            .frame(width: side * 0.27, height: side * 0.38)
                            .clipShape(RoundedRectangle(cornerRadius: side * 0.027, style: .continuous))
                    } else {
                        // Lombada na cor real do livro, com a inicial do título (spec 16).
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: side * 0.027, style: .continuous)
                                .fill(spineColor)
                            RoundedRectangle(cornerRadius: side * 0.005, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                                .frame(width: side * 0.012)
                                .padding(.vertical, side * 0.03)
                                .padding(.leading, side * 0.03)
                            Text(inicial)
                                .font(.system(size: side * 0.16, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.leading, side * 0.04)
                        }
                        .frame(width: side * 0.27, height: side * 0.38)
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: side * 0.03, y: side * 0.02)

                Text(titulo)
                    .font(.system(size: side * 0.048, weight: .heavy))
                    .foregroundStyle(onColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, side * 0.02)

                if let autor, !autor.isEmpty {
                    Text(autor)
                        .font(.system(size: side * 0.034))
                        .foregroundStyle(onColor.opacity(0.85))
                        .lineLimit(1)
                }

                // Número/fração — o herói da composição (spec 16).
                HStack(alignment: .firstTextBaseline, spacing: side * 0.02) {
                    Text("\(numeradorX)")
                        .font(.system(size: side * 0.19, weight: .heavy))
                        .foregroundStyle(onColor)
                    if let denominadorY {
                        Text("/\(denominadorY)")
                            .font(.system(size: side * 0.095, weight: .heavy))
                            .foregroundStyle(onColor.opacity(0.62))
                    }
                }
                .padding(.top, side * 0.03)

                Text(legenda.uppercased())
                    .font(.system(size: side * 0.028, weight: .heavy))
                    .tracking(side * 0.0025)
                    .foregroundStyle(onColor.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, side * 0.06)
            }
            .padding(side * 0.07)
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: side * 0.06, style: .continuous))
    }

    private var inicial: String {
        titulo.trimmingCharacters(in: .whitespacesAndNewlines).first.map { String($0).uppercased() } ?? "?"
    }
}
