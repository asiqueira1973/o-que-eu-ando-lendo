// GoalReachedView.swift — celebração de meta batida (spec seção 8.7/10/15/16).
//
// Mostra a mensagem de parabéns quando uma meta é atingida pela primeira vez.
// Traz o tipo de meta, o período e a quantidade (spec 8.7), com confete (spec 16),
// e um atalho para o Cartão compartilhável já pré-preenchido com esse livro e esse
// período — atalho conveniente, não obrigatório (spec 8.7/8.11). Quando um livro
// bate mais de uma meta, o chamador apresenta uma tela por meta em sequência.

import SwiftUI
import SwiftData

struct GoalReachedView: View {
    let meta: Meta
    /// Livro que disparou a meta — passado adiante ao cartão (spec 8.7/8.11).
    let livro: Livro
    /// Chamado ao fechar (Depois ou após ir ao cartão) para avançar à próxima meta.
    var onFinish: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Query private var todosLivros: [Livro]
    @State private var mostrarCartao = false

    // Quantidade atingida no período (spec 8.7) — contagem real de livros lidos.
    private var quantidade: Int {
        max(GoalEvaluator.progresso(da: meta, livros: todosLivros), meta.quantidade_alvo)
    }

    var body: some View {
        ZStack {
            Palette.ink.ignoresSafeArea()
            ConfettiView().ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text(rotuloTopo.uppercased())
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(Palette.mustard)

                Text("\(quantidade)/\(meta.quantidade_alvo)")
                    .font(.system(size: 120, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.top, 14)

                // Copy exata da spec 15: "Você bateu sua meta de {período}: {n} livros lidos! 🎉"
                Text("Você bateu sua meta de \(fraseMeta): \(meta.quantidade_alvo) livros lidos! 🎉")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.horizontal, 8)

                // Mini lombadas coloridas decorativas (spec 16 — design de referência).
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(Palette.coral).frame(width: 34, height: 48)
                    RoundedRectangle(cornerRadius: 4).fill(Palette.mint).frame(width: 34, height: 48)
                    RoundedRectangle(cornerRadius: 4).fill(Palette.lavender).frame(width: 34, height: 48)
                }
                .padding(.top, 26)

                Spacer()

                Button {
                    mostrarCartao = true
                } label: {
                    Text("Criar card de compartilhar")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(Palette.mustardInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Palette.mustard)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button("Depois") {
                    dismiss()
                    onFinish()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $mostrarCartao, onDismiss: { dismiss(); onFinish() }) {
            ShareCardView(livro: livro, periodoInicial: meta.tipo_periodo)
        }
    }

    // Rótulo do topo, ex.: "META DO MÊS · AGOSTO" (spec 8.7/16).
    private var rotuloTopo: String {
        switch meta.tipo_periodo {
        case .mensal:     return "Meta do mês · \(PeriodCalculator.nomeDoMes(meta.numero_periodo ?? 1))"
        case .trimestral: return "Meta do trimestre · \(meta.numero_periodo ?? 1)º"
        case .semestral:  return "Meta do semestre · \(meta.numero_periodo ?? 1)º"
        case .anual:      return "Meta do ano · \(meta.ano)"
        }
    }

    // Frase de período para a mensagem da spec 15 ("sua meta de {período}").
    private var fraseMeta: String {
        switch meta.tipo_periodo {
        case .mensal:     return PeriodCalculator.nomeDoMes(meta.numero_periodo ?? 1)
        case .trimestral: return "\(meta.numero_periodo ?? 1)º trimestre"
        case .semestral:  return "\(meta.numero_periodo ?? 1)º semestre"
        case .anual:      return "\(meta.ano)"
        }
    }
}
