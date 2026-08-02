// AppConstants.swift — identificadores e constantes de regra de negócio.
//
// Centraliza IDs de infraestrutura (produto de IAP) e constantes de regra (teto do
// trial, pasta de fotos, URLs institucionais) para não espalhar strings mágicas.
// Apoia as spec 4, 8.10, 11 e 17.

import Foundation

enum AppConstants {

    /// Produto de IAP não-consumível que desbloqueia registros ilimitados
    /// (spec 8.10 / 27). Mesmo ID no App Store Connect e no Estante.storekit.
    static let iapProductID = "estante_desbloqueio_completo"

    /// Teto de livros do trial grátis (spec 8.10/11): os 5 primeiros são livres;
    /// tentar salvar o 6º sem compra dispara o Paywall.
    static let trialLimit = 5

    /// Pasta, dentro de Application Support, onde as fotos de capa são salvas
    /// (spec 4). O registro do livro guarda só o nome do arquivo.
    static let fotosDirectoryName = "Fotos"

    /// URL de avaliação na App Store (spec 10 — Configurações). Placeholder até o
    /// App ID real ser emitido no App Store Connect (spec 25/27).
    static let appStoreReviewURL = URL(string: "https://apps.apple.com/app/id0000000000?action=write-review")!

    /// URL da política de privacidade (spec 10/20) — documento institucional da
    /// Dab Lab no Notion, compartilhado para os apps.
    static let privacyPolicyURL = URL(string: "https://app.notion.com/p/POL-TICA-DE-PRIVACIDADE-APLICATIVOS-DA-DAB-LAB-2bd4305f24e180c395cdda41879cf567?source=copy_link")!
}
