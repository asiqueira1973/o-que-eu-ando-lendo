// StoreManager.swift — compra única via StoreKit 2 (spec seção 4/8.10).
//
// Um único produto de IAP NÃO-CONSUMÍVEL (`estante_desbloqueio_completo`) que
// desbloqueia registros ilimitados (spec 8.10). O entitlement é lido de
// `Transaction.currentEntitlements`, que a Apple sincroniza entre aparelhos do
// mesmo Apple ID sem backend (spec 4). O flag de compra NÃO mora no banco `livros`
// — é derivado do StoreKit (spec 10/24). Preço exibido vem de `product.displayPrice`
// (ex.: "R$ 19,90"), não de texto fixo (decisão de implementação, ver DOCUMENTACAO).

import StoreKit

@MainActor
final class StoreManager: ObservableObject {

    /// Produto de desbloqueio carregado do StoreKit (nil enquanto carrega/erro).
    @Published private(set) var product: Product?

    /// Se a compra já foi feita (entitlement ativo) — libera cadastro ilimitado.
    @Published private(set) var compraDesbloqueada = false

    /// Mensagem transitória para a UI (ex.: "Nenhuma compra encontrada", spec 12).
    @Published var mensagem: String?

    /// Em processamento (compra/restauração em curso) para desabilitar botões.
    @Published private(set) var processando = false

    private var updatesTask: Task<Void, Never>?

    // Atalho de teste: quando ligado (via env `ESTANTE_SKIP_STOREKIT`), não toca em
    // StoreKit — evita o prompt de conta Apple no Simulador sem conta de sandbox.
    // Não afeta produção nem o teste real via scheme com Estante.storekit (spec 8.10).
    static var skipStoreKit: Bool {
        ProcessInfo.processInfo.environment["ESTANTE_SKIP_STOREKIT"] == "1"
    }

    init() {
        guard !Self.skipStoreKit else { return }
        // Escuta transações que chegam fora do fluxo de compra (ex.: aprovação
        // pedida a um responsável, ou compra feita em outro aparelho) — spec 8.10.
        updatesTask = Task { [weak self] in
            for await verificação in Transaction.updates {
                await self?.processar(verificação)
            }
        }
    }

    deinit { updatesTask?.cancel() }

    // Só relê o entitlement local (sem buscar produto na rede) — usado na abertura
    // para não disparar prompt de conta Apple (spec 8.10). Purchasers já entram
    // desbloqueados; quem nunca comprou fica em "não comprado" por padrão.
    func atualizarEntitlementsSilencioso() async {
        guard !Self.skipStoreKit else { return }
        await atualizarEntitlements()
    }

    // Carrega o produto e o estado atual de compra (spec 8.10). Chamado de forma
    // preguiçosa quando o Paywall ou as Configurações precisam do preço.
    func carregar() async {
        guard !Self.skipStoreKit else { return }
        await atualizarEntitlements()
        do {
            let produtos = try await Product.products(for: [AppConstants.iapProductID])
            product = produtos.first
        } catch {
            product = nil // sem rede/sandbox: o Paywall mostra estado sem preço
        }
    }

    /// Preço localizado para exibir no Paywall (spec 8.10) — ex.: "R$ 19,90".
    var precoExibicao: String? { product?.displayPrice }

    // Inicia a compra do desbloqueio (spec 8.10). Devolve true se comprou. Em
    // cancelamento/falha, volta sem travar e sem repetir o Paywall (spec 12).
    @discardableResult
    func comprar() async -> Bool {
        guard !Self.skipStoreKit else { return false }
        guard let product else {
            mensagem = "A compra está indisponível agora. Tente novamente em instantes."
            return false
        }
        processando = true
        defer { processando = false }
        do {
            let resultado = try await product.purchase()
            switch resultado {
            case .success(let verificação):
                await processar(verificação)
                return compraDesbloqueada
            case .userCancelled, .pending:
                return false // cancelou/pendente: sem alerta bloqueante (spec 12)
            @unknown default:
                return false
            }
        } catch {
            mensagem = "Não foi possível concluir a compra agora."
            return false
        }
    }

    // Restaura uma compra anterior do mesmo Apple ID (spec 8.10). Acessível no
    // Paywall e nas Configurações (exigência de guideline, spec 8.10/23).
    @discardableResult
    func restaurar() async -> Bool {
        guard !Self.skipStoreKit else { return compraDesbloqueada }
        processando = true
        defer { processando = false }
        try? await AppStore.sync()
        await atualizarEntitlements()
        if !compraDesbloqueada {
            mensagem = "Nenhuma compra encontrada para restaurar." // spec 12
        }
        return compraDesbloqueada
    }

    // Relê os entitlements atuais e atualiza o flag de desbloqueio (spec 8.10).
    private func atualizarEntitlements() async {
        for await verificação in Transaction.currentEntitlements {
            if case .verified(let transaction) = verificação,
               transaction.productID == AppConstants.iapProductID,
               transaction.revocationDate == nil {
                compraDesbloqueada = true
                return
            }
        }
        compraDesbloqueada = false
    }

    // Processa uma transação verificada e conclui (finish) para o StoreKit não a
    // reentregar (spec 8.10).
    private func processar(_ verificação: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verificação else { return }
        if transaction.productID == AppConstants.iapProductID, transaction.revocationDate == nil {
            compraDesbloqueada = true
        }
        await transaction.finish()
    }
}
