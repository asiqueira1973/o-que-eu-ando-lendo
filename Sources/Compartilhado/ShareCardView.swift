// ShareCardView.swift — tela dos cards de compartilhar (spec seção 8.7/8.11/10/16).
//
// Formato stories (9:16 → 1080×1920 no export), estilo "Wrapped". Três modos:
//  - .lido: posição do livro no período (seletor mês/trimestre/semestre/ano), "Nº X"
//    ou "X/Y" se houver meta do período (spec 8.11/11);
//  - .meta: celebração da meta batida, aberta pela tela de meta batida (spec 8.7);
//  - .amigo: recomendação para compartilhar um livro lido com um amigo (spec 16).
// Gera a imagem com ImageRenderer e abre a folha de compartilhamento. Não grava
// nada no banco (spec 8.11).

import SwiftUI
import SwiftData

struct ShareCardView: View {
    enum Mode: Equatable { case lido, meta(Meta), amigo }

    let livro: Livro
    var mode: Mode = .lido
    var periodoInicial: tipo_periodo_meta = .anual

    @Environment(\.dismiss) private var dismiss
    @Query private var todosLivros: [Livro]
    @Query private var todasMetas: [Meta]

    @State private var tipo: tipo_periodo_meta
    @State private var accentIndex: Int
    @State private var shareImage: UIImage?

    // Paleta de fundo dos cards + cor de texto que contrasta (spec 16).
    private struct Accent { let bg: Color; let on: Color }
    private static let cream = Color(hex: 0xFDF6EC)
    private static let accents: [Accent] = [
        Accent(bg: Palette.coral, on: cream),
        Accent(bg: Palette.mustard, on: Palette.mustardInk),
        Accent(bg: Palette.mint, on: Palette.mintInk),
        Accent(bg: Palette.sky, on: Palette.skyInk),
        Accent(bg: Palette.lavender, on: cream),
        Accent(bg: Palette.pink, on: Palette.ink),
        Accent(bg: Palette.ink, on: cream)
    ]
    private static let inkIndex = 6

    init(livro: Livro, mode: Mode = .lido, periodoInicial: tipo_periodo_meta = .anual) {
        self.livro = livro
        self.mode = mode
        self.periodoInicial = periodoInicial
        _tipo = State(initialValue: periodoInicial)
        // Meta batida usa fundo escuro fixo; lido/amigo começam na cor do livro.
        let idx: Int
        if case .meta = mode { idx = ShareCardView.inkIndex }
        else { idx = ShareCardView.indiceCorDoLivro(livro.id) }
        _accentIndex = State(initialValue: idx)
    }

    private var accent: Accent { ShareCardView.accents[accentIndex] }
    private var coverImage: UIImage? { livro.foto_arquivo.flatMap { PhotoStorage.loadImage(named: $0) } }

    // Cor da lombada desenhada: a cor do livro, mas trocada quando coincide com o
    // fundo escolhido, para a lombada nunca se perder no fundo (spec 16).
    private var spineColor: Color {
        let bookIdx = ShareCardView.indiceCorDoLivro(livro.id) // 0..5
        var idx = bookIdx
        if accentIndex < 6 && idx == accentIndex { idx = (idx + 2) % 6 }
        return ShareCardView.accents[idx].bg
    }
    private var permitePeriodo: Bool { if case .lido = mode { return true }; return false }
    private var permiteCor: Bool { if case .meta = mode { return false }; return true }

    var body: some View {
        VStack(spacing: 0) {
            header
            if permitePeriodo {
                periodoSelector.padding(.horizontal, 20).padding(.top, 6)
            }
            ScrollView {
                cartaoPreview.padding(.horizontal, 30).padding(.top, 20)
                if permiteCor { corSelector.padding(.top, 16) }
            }
            Button { shareImage = gerarImagem() } label: {
                Text("Compartilhar")
                    .font(.system(size: 17.5, weight: .heavy)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 17)
                    .background(Palette.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.horizontal, 20)
            Text("Salva em 1080×1920 — tamanho de stories.")
                .font(.system(size: 12.5)).foregroundStyle(Palette.textMuted)
                .padding(.top, 10).padding(.bottom, 24)
        }
        .background(Palette.screen.ignoresSafeArea())
        .sheet(item: Binding(
            get: { shareImage.map { ShareImage(image: $0) } },
            set: { shareImage = $0?.image }
        )) { wrapper in
            ActivityView(items: [wrapper.image])
        }
    }

    private var header: some View {
        HStack {
            Button("Fechar") { dismiss() }.foregroundStyle(Palette.coral)
            Spacer()
            Text(tituloTela).font(.system(size: 17, weight: .heavy)).foregroundStyle(Palette.textPrimary)
            Spacer()
            Text("Fechar").foregroundStyle(.clear)
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
    }

    private var periodoSelector: some View {
        HStack(spacing: 4) {
            ForEach(tipo_periodo_meta.allCases, id: \.self) { t in
                let sel = t == tipo
                Text(rotuloCurto(t))
                    .font(.system(size: 13, weight: sel ? .heavy : .semibold))
                    .foregroundStyle(sel ? Palette.textPrimary : Palette.textSecondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(sel ? Palette.card : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .onTapGesture { tipo = t }
            }
        }
        .padding(4).background(Palette.segmentTrack)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var cartaoPreview: some View {
        GeometryReader { geo in
            ShareStoryCard(width: geo.size.width, livro: livro, coverImage: coverImage,
                           bg: accent.bg, onColor: accent.on, spineColor: spineColor, kind: kind)
                .clipShape(RoundedRectangle(cornerRadius: geo.size.width * 0.05, style: .continuous))
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
    }

    private var corSelector: some View {
        HStack(spacing: 8) {
            ForEach(0..<ShareCardView.accents.count, id: \.self) { i in
                Circle().fill(ShareCardView.accents[i].bg)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Palette.screen, lineWidth: i == accentIndex ? 2.5 : 0))
                    .overlay(Circle().stroke(ShareCardView.accents[i].bg, lineWidth: i == accentIndex ? 2 : 0).padding(-4))
                    .onTapGesture { accentIndex = i }
            }
        }
    }

    // MARK: - Conteúdo da variante

    private var kind: ShareStoryCard.Kind {
        switch mode {
        case .lido:
            let x = ReadingStats.posicaoNoPeriodo(livro, tipo: tipo, todos: todosLivros)
            let p = ReadingStats.periodo(de: livro, tipo: tipo)
            let metaDoPeriodo = p.flatMap { pp in
                todasMetas.first { $0.tipo_periodo == tipo && $0.ano == pp.ano && $0.numero_periodo == pp.numero }
            }
            let den = metaDoPeriodo?.quantidade_alvo
            let ano = p?.ano ?? Calendar.current.component(.year, from: Date())
            let legenda = den != nil ? "livros da minha meta \(fraseTemporal(tipo, ano: ano, numero: p?.numero))"
                                     : "livro que li \(fraseTemporal(tipo, ano: ano, numero: p?.numero))"
            return .lido(numero: x, denominador: den, kicker: kickerPeriodo(tipo, ano: ano, numero: p?.numero), legenda: legenda)

        case let .meta(m):
            let prog = max(GoalEvaluator.progresso(da: m, livros: todosLivros), m.quantidade_alvo)
            let kicker = "meta \(fraseMetaCurta(m)) batida"
            let sub = "\(m.quantidade_alvo) livros \(fraseTemporal(m.tipo_periodo, ano: m.ano, numero: m.numero_periodo))"
            return .meta(progresso: prog, alvo: m.quantidade_alvo, kicker: kicker,
                         titulo: "Você bateu sua meta!", subtitulo: sub)

        case .amigo:
            return .amigo(kicker: "acabei de ler", chip: "recomendo pra você",
                          rodape: "achei que ia gostar · da minha estante")
        }
    }

    private var tituloTela: String {
        switch mode {
        case .lido: return "Cartão do livro"
        case .meta: return "Cartão da meta"
        case .amigo: return "Compartilhar com um amigo"
        }
    }

    // MARK: - Frases de período (spec 15/16)

    private func kickerPeriodo(_ t: tipo_periodo_meta, ano: Int, numero: Int?) -> String {
        switch t {
        case .mensal: return "\(PeriodCalculator.nomeDoMes(numero ?? 1)) de \(ano)"
        case .trimestral: return "\(numero ?? 1)º trimestre · \(ano)"
        case .semestral: return "\(numero ?? 1)º semestre · \(ano)"
        case .anual: return "meu ano de leitura · \(ano)"
        }
    }
    private func fraseTemporal(_ t: tipo_periodo_meta, ano: Int, numero: Int?) -> String {
        switch t {
        case .mensal: return "em \(PeriodCalculator.nomeDoMes(numero ?? 1))"
        case .trimestral: return "no \(numero ?? 1)º trimestre"
        case .semestral: return "no \(numero ?? 1)º semestre"
        case .anual: return "este ano"
        }
    }
    private func fraseMetaCurta(_ m: Meta) -> String {
        switch m.tipo_periodo {
        case .mensal: return "de \(PeriodCalculator.nomeDoMes(m.numero_periodo ?? 1))"
        case .trimestral: return "do \(m.numero_periodo ?? 1)º trimestre"
        case .semestral: return "do \(m.numero_periodo ?? 1)º semestre"
        case .anual: return "de \(m.ano)"
        }
    }
    private func rotuloCurto(_ t: tipo_periodo_meta) -> String {
        switch t {
        case .mensal: return "Mês"; case .trimestral: return "Trimestre"
        case .semestral: return "Semestre"; case .anual: return "Ano"
        }
    }

    // Índice da cor do livro na paleta de acentos (mesmo hash de BookColor, spec 16).
    private static func indiceCorDoLivro(_ id: UUID) -> Int {
        let bytes = withUnsafeBytes(of: id.uuid) { Array($0) }
        let sum = bytes.reduce(0) { $0 &+ Int($1) }
        return sum % 6   // 0..5 = coral..pink (nunca o ink, reservado à meta)
    }

    // Renderiza a imagem em 1080×1920 (spec 8.11/16).
    private func gerarImagem() -> UIImage? {
        let card = ShareStoryCard(width: 1080, livro: livro, coverImage: coverImage,
                                  bg: accent.bg, onColor: accent.on, spineColor: spineColor, kind: kind)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1
        return renderer.uiImage
    }
}

/// Wrapper Identifiable para apresentar a folha de compartilhamento com a imagem.
private struct ShareImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
