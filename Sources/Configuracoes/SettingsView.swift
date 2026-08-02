// SettingsView.swift — Configurações (spec seção 10/8.10/17/20).
//
// Sobre o app, exportar, avaliar na App Store, política de privacidade e o botão
// "Restaurar compra" — que precisa estar acessível também fora do Paywall
// (exigência de guideline da App Store, spec 8.10/23). Inclui a nota de backup:
// como não há sincronização própria no MVP, os dados dependem do backup padrão do
// iOS (spec 17).

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: StoreManager
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    @State private var mostrarExport = false

    var body: some View {
        NavigationStack {
            List {
                #if DEBUG
                Section("Testes (DEBUG)") {
                    Button { SeedData.popular(context: context) } label: {
                        linha("Popular dados de exemplo", systemImage: "wand.and.stars")
                    }
                    Button(role: .destructive) { SeedData.limpar(context: context) } label: {
                        linha("Limpar tudo", systemImage: "trash")
                    }
                }
                #endif

                Section {
                    Button { mostrarExport = true } label: {
                        linha("Exportar livros lidos (CSV)", systemImage: "square.and.arrow.up")
                    }
                }

                Section("Compra") {
                    if store.compraDesbloqueada {
                        linha("Registros ilimitados desbloqueados ✓", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Palette.mint)
                    } else {
                        Button {
                            Task { await store.restaurar() }
                        } label: {
                            linha("Restaurar compra", systemImage: "arrow.clockwise")
                        }
                        .disabled(store.processando)
                    }
                }

                Section("Sobre") {
                    Button { openURL(AppConstants.appStoreReviewURL) } label: {
                        linha("Avaliar na App Store", systemImage: "star")
                    }
                    Button { openURL(AppConstants.privacyPolicyURL) } label: {
                        linha("Política de privacidade", systemImage: "hand.raised")
                    }
                }

                Section {
                    Text("Seus dados ficam só neste aparelho. Como o app não sincroniza na nuvem, mantenha o backup do iOS (iCloud ou computador) ativo para não perder sua estante ao trocar de iPhone.")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textSecondary)
                } header: {
                    Text("Backup dos seus dados")
                }
            }
            .navigationTitle("Configurações")
            .alert("Aviso", isPresented: Binding(
                get: { store.mensagem != nil }, set: { if !$0 { store.mensagem = nil } }
            )) {
                Button("OK", role: .cancel) { store.mensagem = nil }
            } message: { Text(store.mensagem ?? "") }
            .sheet(isPresented: $mostrarExport) { ExportView() }
        }
    }

    private func linha(_ titulo: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage).frame(width: 24)
            Text(titulo)
            Spacer()
        }
        .foregroundStyle(Palette.textPrimary)
    }
}
