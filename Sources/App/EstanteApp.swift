// EstanteApp.swift — ponto de entrada do app "O que eu ando lendo" (spec 4).
//
// Sobe o ModelContainer local-first (ContainerModelo) e injeta no ambiente
// SwiftUI. A navegação real (abas Estante/Quero ler/Metas/Configurações) vive em
// RootTabView (spec 10).

import SwiftUI
import SwiftData

@main
struct EstanteApp: App {

    let container: ModelContainer
    @StateObject private var store = StoreManager()

    init() {
        do {
            container = try ContainerModelo.criar()
        } catch {
            // Falha ao subir o store local é erro de ambiente, não estado de
            // usuário — travar cedo facilita o diagnóstico.
            fatalError("Falha ao criar o ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .tint(Palette.coral)
                // Entitlement é lido de forma preguiçosa (na 1ª vez que o Paywall
                // ou as Configurações aparecem) para não disparar prompt de conta
                // Apple na abertura — o trial já assume "não comprado" por padrão
                // e desbloqueia assim que o entitlement é verificado (spec 8.10).
                .task { await store.atualizarEntitlementsSilencioso() }
                #if DEBUG
                // Auto-seed opcional para capturar screenshots com volume de dados
                // sem navegar pela UI (env ESTANTE_SEED=1). Só DEBUG (spec 18/22).
                .task { autoSeedSeSolicitado() }
                #endif
        }
        .modelContainer(container)
    }

    #if DEBUG
    // Popula dados de exemplo na abertura quando ESTANTE_SEED=1 e a estante está
    // vazia — atalho de teste/screenshot (spec 18). Nunca roda em release.
    private func autoSeedSeSolicitado() {
        guard ProcessInfo.processInfo.environment["ESTANTE_SEED"] == "1" else { return }
        let ctx = container.mainContext
        let vazio = (try? ctx.fetch(FetchDescriptor<Livro>()))?.isEmpty ?? true
        if vazio { SeedData.popular(context: ctx) }
    }
    #endif
}
