// DesignTokens.swift — cores, sombras e estilos base da identidade visual.
//
// Fonte definitiva: o projeto de design em `book-tracker-design-system/`
// (`Estante Screens.dc.html`), que prevalece sobre a prosa da spec seção 16. Os
// hex abaixo foram extraídos direto de lá. Paleta viva e alegre (múltiplas cores,
// não uma marca dominante), fundo neutro claro/creme, e modo escuro com fundo
// neutro escuro e os mesmos acentos vivos (spec 16).

import SwiftUI

extension Color {
    // Cria uma Color a partir de um inteiro hex 0xRRGGBB (spec 16 — helper interno).
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    // Cria uma Color que adapta entre claro e escuro (spec 16 — modo escuro dia 1).
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }
}

/// Paleta central do app (spec 16). Neutros adaptam claro/escuro; acentos são os
/// mesmos tons vivos nos dois temas.
enum Palette {
    // Neutros semânticos ----------------------------------------------------
    static let screen = Color(light: 0xFDF6EC, dark: 0x17130F)      // fundo de tela
    static let backdrop = Color(light: 0xEFE7DC, dark: 0x0F0C0A)    // fundo de página
    static let card = Color(light: 0xFFFFFF, dark: 0x241E18)        // cards
    static let textPrimary = Color(light: 0x2B2320, dark: 0xF4ECE0)
    static let textSecondary = Color(light: 0x8A7A67, dark: 0xB8A88F)
    static let textMuted = Color(light: 0xB29A80, dark: 0x8C7B65)
    static let fieldInset = Color(light: 0xFDF1E3, dark: 0x2C2420)
    static let fieldBorder = Color(light: 0xF0DFC8, dark: 0x3A3128)
    static let segmentTrack = Color(light: 0xF2E7D8, dark: 0x2F2721)
    static let hairline = Color(light: 0xF3EADD, dark: 0x332B24)
    static let dashedBorder = Color(light: 0xDCC9AF, dark: 0x4A3F33)

    // Acentos vivos (mesmos nos dois temas) ---------------------------------
    static let coral = Color(hex: 0xFF6B5A)
    static let mustard = Color(hex: 0xF5B72F)
    static let mint = Color(hex: 0x4FC79A)
    static let sky = Color(hex: 0x4FA8E8)
    static let lavender = Color(hex: 0x9B87F5)
    static let pink = Color(hex: 0xFF8FB1)
    static let ink = Color(hex: 0x2B2320)

    // Tons escuros da mesma família, para texto sobre pills coloridas (spec 16).
    static let mustardInk = Color(hex: 0x4A320A)
    static let mintInk = Color(hex: 0x0C3E2C)
    static let skyInk = Color(hex: 0x08304C)

    /// Cor das estrelas de avaliação (spec 8.3/16).
    static let star = Color(hex: 0xF5B72F)
    static let starEmpty = Color(light: 0xE7D9C5, dark: 0x4A3F33)
}

/// Cores de "lombada" de livro sem foto (spec 16). Determinísticas por `id`, para
/// o mesmo livro ter sempre a mesma cor entre sessões (spec 24).
enum BookColor {
    /// As 6 cores vivas usadas nas lombadas ilustradas (spec 16 — o preto/ink é
    /// reservado a badges/cards escuros, não a lombadas).
    static let spines: [Color] = [
        Palette.coral, Palette.mustard, Palette.mint,
        Palette.sky, Palette.lavender, Palette.pink
    ]

    // Escolhe a cor da lombada de um livro de forma determinística pelo seu `id`
    // (spec 16/24). Soma os bytes do UUID e usa o resto pela quantidade de cores —
    // hash simples e estável entre sessões, sem depender de Hashable do sistema.
    static func color(for id: UUID) -> Color {
        let bytes = withUnsafeBytes(of: id.uuid) { Array($0) }
        let sum = bytes.reduce(0) { $0 &+ Int($1) }
        return spines[sum % spines.count]
    }
}

extension View {
    // Aplica o visual de card padrão do app: cantos arredondados e a sombra quente
    // suave usada em todo o design (spec 16 — `0 2px 10px rgba(88,60,30,.07)`).
    func estanteCard(cornerRadius: CGFloat = 18) -> some View {
        self
            .background(Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color(hex: 0x583C1E).opacity(0.07), radius: 10, x: 0, y: 2)
    }
}
