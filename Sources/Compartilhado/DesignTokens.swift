// DesignTokens.swift — cores, sombras e estilos base da identidade visual.
//
// Fonte definitiva: o projeto de design em `book-tracker-design-system/`
// (`Estante Screens.dc.html`), que prevalece sobre a prosa da spec seção 16. Os
// hex abaixo foram extraídos direto de lá. Paleta viva e alegre (múltiplas cores,
// não uma marca dominante), fundo neutro branco, e modo escuro com fundo
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
    // Revisão 27/09/2026: o creme/marrom do design original saiu. Fundo cinza de
    // lista agrupada do iOS (#F2F2F7, igual ao Quando Vence) com cards brancos no
    // claro; preto com cards cinza-escuro no escuro.
    static let screen = Color(light: 0xF2F2F7, dark: 0x000000)      // fundo de tela
    static let backdrop = Color(light: 0xF2F2F7, dark: 0x000000)    // fundo de página
    static let card = Color(light: 0xFFFFFF, dark: 0x1C1C1E)        // cards
    static let textPrimary = Color(light: 0x1D1D1F, dark: 0xF5F5F7)
    static let textSecondary = Color(light: 0x6E6E73, dark: 0xAEAEB2)
    static let textMuted = Color(light: 0x8E8E93, dark: 0x8E8E93)
    static let fieldInset = Color(light: 0xF5F5F7, dark: 0x2C2C2E)
    static let fieldBorder = Color(light: 0xE5E5EA, dark: 0x3A3A3C)
    static let segmentTrack = Color(light: 0xE3E3E8, dark: 0x2C2C2E)
    static let hairline = Color(light: 0xE5E5EA, dark: 0x38383A)
    static let dashedBorder = Color(light: 0xC7C7CC, dark: 0x48484A)
    static let tile = Color(light: 0xFFFFFF, dark: 0x1C1C1E)        // blocos de número (padrão iOS)

    // Cor de destaque da interface --------------------------------------------
    // Revisão 27/09/2026: uma cor só para botões, abas, links e seleção — o azul
    // do sistema, mais discreto que o coral. Os acentos vivos abaixo ficam para
    // conteúdo (lombadas, cards de compartilhar, confete).
    static let accent = Color(light: 0x007AFF, dark: 0x0A84FF)

    // Acentos vivos (mesmos nos dois temas) ---------------------------------
    static let coral = Color(hex: 0xFF6B5A)
    static let mustard = Color(hex: 0xF5B72F)
    static let mint = Color(hex: 0x4FC79A)
    static let sky = Color(hex: 0x4FA8E8)
    static let lavender = Color(hex: 0x9B87F5)
    static let pink = Color(hex: 0xFF8FB1)
    static let ink = Color(hex: 0x1D1D1F)

    // Tons escuros da mesma família, para texto sobre pills coloridas (spec 16).
    static let mustardInk = Color(hex: 0x4A320A)
    static let mintInk = Color(hex: 0x0C3E2C)
    static let skyInk = Color(hex: 0x08304C)

    /// Cor das estrelas de avaliação (spec 8.3/16).
    static let star = Color(hex: 0xF5B72F)
    static let starEmpty = Color(light: 0xE0E0E5, dark: 0x48484A)
}

/// Cores de "lombada" de livro sem foto (spec 16). Determinísticas por `id`, para
/// o mesmo livro ter sempre a mesma cor entre sessões (spec 24).
enum BookColor {
    /// As 6 cores das lombadas ilustradas (spec 16). Revisão 27/09/2026: tons
    /// pastel no lugar dos acentos vivos, para as capas sem foto ficarem discretas.
    /// A ordem segue a família antiga (coral, mostarda, verde, azul, lilás, rosa),
    /// então cada livro mantém a mesma família de cor de antes.
    static let spines: [Color] = [
        Color(hex: 0xFBDCD3), Color(hex: 0xFBEDC4), Color(hex: 0xD5EFDF),
        Color(hex: 0xD5E5F6), Color(hex: 0xE3DCF6), Color(hex: 0xF8DAE4)
    ]

    /// Tom escuro de cada pastel, para a inicial e textos sobre/ao lado da lombada
    /// (mesma ordem de `spines`; contraste legível sobre o pastel).
    static let inks: [Color] = [
        Color(hex: 0x8A3B2C), Color(hex: 0x7A5A0C), Color(hex: 0x23603E),
        Color(hex: 0x1F4B78), Color(hex: 0x4B3A8A), Color(hex: 0x8A3552)
    ]

    // Escolhe a cor da lombada de um livro de forma determinística pelo seu `id`
    // (spec 16/24). Soma os bytes do UUID e usa o resto pela quantidade de cores —
    // hash simples e estável entre sessões, sem depender de Hashable do sistema.
    static func color(for id: UUID) -> Color {
        let bytes = withUnsafeBytes(of: id.uuid) { Array($0) }
        let sum = bytes.reduce(0) { $0 &+ Int($1) }
        return spines[sum % spines.count]
    }

    // Tom escuro correspondente à lombada do livro (mesmo hash de `color(for:)`).
    static func ink(for id: UUID) -> Color {
        let bytes = withUnsafeBytes(of: id.uuid) { Array($0) }
        let sum = bytes.reduce(0) { $0 &+ Int($1) }
        return inks[sum % inks.count]
    }
}

extension View {
    // Aplica o visual de card padrão do app: card branco de cantos arredondados, sem
    // contorno nem sombra, sobre o fundo cinza agrupado (spec 16; revisão 27/09/2026
    // — padrão nativo do iOS, como o `groupedCard` do Quando Vence).
    func estanteCard(cornerRadius: CGFloat = 18) -> some View {
        self
            .background(Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
