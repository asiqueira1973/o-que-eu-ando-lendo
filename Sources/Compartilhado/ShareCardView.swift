// ShareCardView.swift — tela do cartão compartilhável (spec seção 8.11/10/16).
//
// A partir de um livro `lido`, deixa escolher o tipo de período (mês/trimestre/
// semestre/ano), calcula a posição do livro no período (X, spec 11) e monta o
// cartão: "X/Y" quando existe meta do mesmo tipo+período, ou só "X" quando não
// existe (spec 8.11/11). Gera a imagem 1080×1080 com `ImageRenderer` e abre a
// folha de compartilhamento nativa. Não grava nada no banco (spec 8.11).

import SwiftUI
import SwiftData

struct ShareCardView: View {
    let livro: Livro
    /// Período inicial (ex.: vindo do atalho da meta batida) — default anual.
    var periodoInicial: tipo_periodo_meta = .anual

    @Environment(\.dismiss) private var dismiss
    @Query private var todosLivros: [Livro]
    @Query private var todasMetas: [Meta]

    @State private var tipo: tipo_periodo_meta
    @State private var bgColor: Color
    @State private var shareImage: UIImage?

    init(livro: Livro, periodoInicial: tipo_periodo_meta = .anual) {
        self.livro = livro
        self.periodoInicial = periodoInicial
        _tipo = State(initialValue: periodoInicial)
        _bgColor = State(initialValue: BookColor.color(for: livro.id))
    }

    // Foto carregada de forma síncrona — o ImageRenderer é síncrono e não roda
    // .task assíncrono (spec 8.11). Nil → o cartão mostra a lombada colorida.
    private var coverImage: UIImage? {
        livro.foto_arquivo.flatMap { PhotoStorage.loadImage(named: $0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            periodoSelector
                .padding(.horizontal, 20)
                .padding(.top, 6)

            ScrollView {
                cartaoPreview
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                corSelector
                    .padding(.top, 16)
            }

            Button {
                shareImage = gerarImagem()
            } label: {
                Text("Compartilhar")
                    .font(.system(size: 17.5, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Palette.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.horizontal, 20)

            Text("Salva em 1080×1080 — pronto para o seu feed.")
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.textMuted)
                .padding(.top, 10)
                .padding(.bottom, 24)
        }
        .background(Palette.screen.ignoresSafeArea())
        .sheet(item: Binding(
            get: { shareImage.map { ShareImage(image: $0) } },
            set: { shareImage = $0?.image }
        )) { wrapper in
            ActivityView(items: [wrapper.image])
        }
    }

    // Cabeçalho: Fechar / título (spec 16 — o design tem "Estilo", que aqui vira a
    // fileira de cores abaixo, mantendo um layout só, spec 28).
    private var header: some View {
        HStack {
            Button("Fechar") { dismiss() }
                .foregroundStyle(Palette.coral)
            Spacer()
            Text("Cartão de compartilhar")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            Text("Fechar").foregroundStyle(.clear) // equilíbrio visual do título central
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // Segmented de tipo de período (spec 8.11/16).
    private var periodoSelector: some View {
        HStack(spacing: 4) {
            ForEach(tipo_periodo_meta.allCases, id: \.self) { t in
                let selected = t == tipo
                Text(rotuloCurto(t))
                    .font(.system(size: 13, weight: selected ? .heavy : .semibold))
                    .foregroundStyle(selected ? Palette.textPrimary : Palette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selected ? Palette.card : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .onTapGesture { tipo = t }
            }
        }
        .padding(4)
        .background(Palette.segmentTrack)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var cartaoPreview: some View {
        GeometryReader { geo in
            ShareCard(
                side: geo.size.width,
                titulo: livro.titulo,
                autor: livro.autor,
                spineColor: BookColor.color(for: livro.id),
                coverImage: coverImage,
                bgColor: bgColor,
                numeradorX: numeradorX,
                denominadorY: denominadorY,
                legenda: legenda
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // Escolha da cor de fundo do cartão dentro da paleta (um layout só, spec 28).
    private var corSelector: some View {
        HStack(spacing: 8) {
            ForEach(Array(coresDisponiveis.enumerated()), id: \.offset) { _, cor in
                Circle()
                    .fill(cor)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle().stroke(Palette.screen, lineWidth: cor == bgColor ? 2.5 : 0)
                    )
                    .overlay(
                        Circle().stroke(cor, lineWidth: cor == bgColor ? 2 : 0).padding(-4)
                    )
                    .onTapGesture { bgColor = cor }
            }
        }
    }

    private var coresDisponiveis: [Color] {
        [Palette.coral, Palette.mustard, Palette.mint, Palette.sky, Palette.lavender, Palette.pink, Palette.ink]
    }

    // MARK: - Cálculo do cartão (spec 11)

    // Período concreto que contém a data de conclusão do livro para o tipo escolhido.
    private var periodoDoLivro: ReadingPeriod? {
        ReadingStats.periodo(de: livro, tipo: tipo)
    }

    // X = posição do livro no período (spec 11).
    private var numeradorX: Int {
        ReadingStats.posicaoNoPeriodo(livro, tipo: tipo, todos: todosLivros)
    }

    // Meta do mesmo tipo+período do livro, se existir (spec 8.11/11).
    private var metaDoPeriodo: Meta? {
        guard let p = periodoDoLivro else { return nil }
        return todasMetas.first {
            $0.tipo_periodo == tipo && $0.ano == p.ano && $0.numero_periodo == p.numero
        }
    }

    // Y = alvo da meta quando existe; nil mostra só "X" (spec 11).
    private var denominadorY: Int? { metaDoPeriodo?.quantidade_alvo }

    // Legenda do cartão, copy da spec 15 (com/sem meta).
    private var legenda: String {
        guard let p = periodoDoLivro else { return "" }
        if metaDoPeriodo != nil {
            return "livro \(numeradorX) de \(denominadorY ?? 0) da minha meta de \(p.shortLabel())"
        }
        return "livro nº \(numeradorX) que li \(fraseTemporal(p))"
    }

    private func fraseTemporal(_ p: ReadingPeriod) -> String {
        switch p.tipo {
        case .mensal:     return "em \(PeriodCalculator.nomeDoMes(p.numero ?? 1)) de \(p.ano)"
        case .trimestral: return "no \(p.numero ?? 1)º trimestre de \(p.ano)"
        case .semestral:  return "no \(p.numero ?? 1)º semestre de \(p.ano)"
        case .anual:      return "em \(p.ano)"
        }
    }

    private func rotuloCurto(_ t: tipo_periodo_meta) -> String {
        switch t {
        case .mensal: return "Mês"
        case .trimestral: return "Trimestre"
        case .semestral: return "Semestre"
        case .anual: return "Ano"
        }
    }

    // Renderiza o cartão em 1080×1080 (spec 8.11) para compartilhar.
    private func gerarImagem() -> UIImage? {
        let card = ShareCard(
            side: 1080,
            titulo: livro.titulo,
            autor: livro.autor,
            spineColor: BookColor.color(for: livro.id),
            coverImage: coverImage,
            bgColor: bgColor,
            numeradorX: numeradorX,
            denominadorY: denominadorY,
            legenda: legenda
        )
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
