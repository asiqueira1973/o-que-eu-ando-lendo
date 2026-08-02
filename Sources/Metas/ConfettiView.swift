// ConfettiView.swift — animação leve de confete (spec seção 8.7/16).
//
// Celebração da tela de meta batida, reforçando o tom "divertido" do produto
// (spec 16). Implementação nativa em SwiftUI (sem biblioteca externa), com as
// cores da paleta viva do app.

import SwiftUI

struct ConfettiView: View {
    var count: Int = 46
    private let cores: [Color] = [
        Palette.coral, Palette.mustard, Palette.mint, Palette.sky,
        Palette.lavender, Palette.pink, .white
    ]

    @State private var animar = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let redondo = i % 3 == 0
                    let cor = cores[i % cores.count]
                    let x = CGFloat((i * 37) % 100) / 100 * geo.size.width
                    let atraso = Double((i * 13) % 30) / 10
                    let duracao = 2.6 + Double((i * 7) % 18) / 10

                    RoundedRectangle(cornerRadius: redondo ? 4 : 2)
                        .fill(cor)
                        .frame(width: redondo ? 8 : 6, height: redondo ? 8 : 14)
                        .position(x: x, y: animar ? geo.size.height + 40 : -40)
                        .rotationEffect(.degrees(animar ? 520 : 0))
                        .opacity(animar ? 0 : 1)
                        .animation(
                            .linear(duration: duracao).delay(atraso).repeatForever(autoreverses: false),
                            value: animar
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { animar = true }
    }
}
