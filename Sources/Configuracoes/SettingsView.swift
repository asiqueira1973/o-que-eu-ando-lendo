// SettingsView.swift — Configurações (spec seção 10/8.10/17/20).
//
// Sobre o app, exportar, avaliar na App Store, política de privacidade e o botão
// "Restaurar compra" — que precisa estar acessível também fora do Paywall
// (exigência de guideline da App Store, spec 8.10/23). Inclui a nota de backup:
// como não há sincronização própria no MVP, os dados dependem do backup padrão do
// iOS (spec 17).

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: StoreManager
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    @State private var mostrarExport = false
    // Importação de backup CSV (spec 14).
    @State private var mostrarImporter = false
    @State private var dadosImportacao: Data?
    @State private var contagemImportacao = 0
    @State private var confirmarImport = false

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
                    Button { mostrarImporter = true } label: {
                        linha("Importar backup (CSV)", systemImage: "square.and.arrow.down")
                    }
                } footer: {
                    Text("Importar um CSV exportado antes substitui todos os livros e metas atuais pelos do arquivo.")
                        .font(.system(size: 12)).foregroundStyle(Palette.textMuted)
                }

                Section("Compra") {
                    if store.compraDesbloqueada {
                        linha("Registros ilimitados desbloqueados ✓", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Palette.accent)
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
            // Seletor de arquivo para restaurar o backup (spec 14).
            .fileImporter(isPresented: $mostrarImporter,
                          allowedContentTypes: [.commaSeparatedText, .plainText, .text],
                          allowsMultipleSelection: false) { resultado in
                guard case .success(let urls) = resultado, let url = urls.first else { return }
                let acessou = url.startAccessingSecurityScopedResource()
                defer { if acessou { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url) else {
                    store.mensagem = "Não foi possível ler o arquivo."
                    return
                }
                dadosImportacao = data
                contagemImportacao = CSVImporter.parse(data).count
                confirmarImport = true
            }
            // Confirmação explícita antes de sobrescrever o banco (spec 12/14).
            .confirmationDialog("Importar backup?", isPresented: $confirmarImport, titleVisibility: .visible) {
                Button("Importar \(contagemImportacao) \(contagemImportacao == 1 ? "livro" : "livros")", role: .destructive) {
                    if let data = dadosImportacao {
                        let n = BackupRestore.restaurar(context: context, de: data)
                        store.mensagem = "Backup restaurado: \(n) \(n == 1 ? "livro importado" : "livros importados")."
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Isso substitui TODOS os livros e metas atuais pelos livros do arquivo. Não dá para desfazer.")
            }
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
