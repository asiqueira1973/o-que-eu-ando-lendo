// PaywallView.swift — tela de compra única (spec seção 8.10 / 10 / 15).
//
// Aparece ao tentar salvar o 6º livro sem compra (interceptado no cadastro, 8.1),
// ou manualmente pelas Configurações. Mostra o preço real do StoreKit e os botões
// "Comprar" e "Restaurar compra". Ao desbloquear, chama `onDesbloqueado` para o
// cadastro completar o salvamento pendente sem o usuário tocar em salvar de novo
// (spec 8.10). Copy fixa da spec 15; o preço vem de `displayPrice` (ver DOCUMENTACAO).

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    /// Chamado quando a compra/restauração desbloqueia — o chamador completa o
    /// salvamento pendente (spec 8.10).
    var onDesbloqueado: () -> Void = {}

    private var preco: String { store.precoExibicao ?? "R$ 19,90" }

    var body: some View {
        ZStack {
            Palette.screen.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(Palette.coral)

                Text("Continue registrando sem limites")
                    .font(.system(size: 26, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.textPrimary)

                Text("Você já registrou 5 livros de graça. Desbloqueie registros ilimitados com um pagamento único de \(preco) — sem assinatura, sem cobrança recorrente.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, 8)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        Task { await comprar() }
                    } label: {
                        Text("Desbloquear por \(preco)")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Palette.coral)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .disabled(store.processando)

                    Button {
                        Task { await restaurar() }
                    } label: {
                        Text("Já comprei — restaurar")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .disabled(store.processando)
                }
            }
            .padding(24)

            if store.processando {
                ProgressView().controlSize(.large)
            }
        }
        .presentationDragIndicator(.visible)
        .task { await store.carregar() }
        .alert("Aviso", isPresented: Binding(
            get: { store.mensagem != nil },
            set: { if !$0 { store.mensagem = nil } }
        )) {
            Button("OK", role: .cancel) { store.mensagem = nil }
        } message: {
            Text(store.mensagem ?? "")
        }
    }

    // Dispara a compra; se desbloquear, avisa o chamador e fecha (spec 8.10).
    private func comprar() async {
        if await store.comprar() {
            onDesbloqueado()
            dismiss()
        }
    }

    // Restaura compra anterior; se desbloquear, avisa o chamador e fecha (spec 8.10).
    private func restaurar() async {
        if await store.restaurar() {
            onDesbloqueado()
            dismiss()
        }
    }
}
