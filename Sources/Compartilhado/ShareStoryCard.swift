// ShareStoryCard.swift — arte 9:16 dos cards de compartilhar (spec seção 8.7/8.11/16).
//
// Formato stories (1080×1920 no export), no espírito "Wrapped": fundo colorido da
// paleta do app, formas divertidas e tipografia grande arredondada. Três variantes
// (spec 16): livro lido (posição no período), meta batida (celebração) e
// compartilhar com um amigo (recomendação). Tudo dimensionado a partir de `width`
// (base de design 432pt → escala p()), para servir ao preview e ao ImageRenderer.

import SwiftUI

struct ShareStoryCard: View {

    /// Conteúdo central de cada variante (spec 8.7/8.11).
    enum Kind {
        case lido(numero: Int, denominador: Int?, kicker: String, legenda: String)
        case meta(progresso: Int, alvo: Int, kicker: String, titulo: String, subtitulo: String)
        case amigo(kicker: String, chip: String, rodape: String)
    }

    let width: CGFloat
    let livro: Livro
    /// Foto já carregada (sync) ou nil → lombada desenhada (spec 8.11/16).
    let coverImage: UIImage?
    let bg: Color
    let onColor: Color
    /// Cor da lombada desenhada — escolhida para contrastar com `bg` (spec 16).
    let spineColor: Color
    let kind: Kind

    private var height: CGFloat { width * 16.0 / 9.0 }
    // Escala do design (base 432pt de largura) para os tamanhos em px do render.
    private func p(_ v: CGFloat) -> CGFloat { v * width / 432.0 }

    var body: some View {
        ZStack {
            bg
            formas
            VStack(alignment: .leading, spacing: 0) {
                marca
                Spacer(minLength: 0)
                miolo
                Spacer(minLength: 0)
                Text(rodape)
                    .font(.system(size: p(12), weight: .medium))
                    .foregroundStyle(onColor.opacity(0.8))
            }
            .padding(.horizontal, p(40))
            .padding(.vertical, p(44))
            .frame(width: width, height: height, alignment: .topLeading)
        }
        .frame(width: width, height: height)
        .clipped()
    }

    // MARK: - Marca (topo)

    private var marca: some View {
        HStack(spacing: p(8)) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: p(16), weight: .bold))
            Text("O QUE EU ANDO LENDO")
                .font(.system(size: p(12), weight: .bold, design: .rounded))
                .tracking(p(1.6))
        }
        .foregroundStyle(onColor.opacity(kindIsMeta ? 0.55 : 0.95))
    }

    // MARK: - Miolo por variante

    @ViewBuilder private var miolo: some View {
        switch kind {
        case let .lido(numero, denominador, kicker, legenda):
            VStack(alignment: .leading, spacing: p(8)) {
                Text(kicker.uppercased())
                    .font(.system(size: p(15), weight: .bold, design: .rounded))
                    .tracking(p(2)).foregroundStyle(onColor.opacity(0.92))
                HStack(alignment: .firstTextBaseline, spacing: p(6)) {
                    Text("Nº \(numero)")
                        .font(.system(size: p(150), weight: .heavy, design: .rounded))
                        .foregroundStyle(onColor)
                    if let denominador {
                        Text("/\(denominador)")
                            .font(.system(size: p(64), weight: .heavy, design: .rounded))
                            .foregroundStyle(onColor.opacity(0.55))
                    }
                }
                .lineLimit(1).minimumScaleFactor(0.5)
                Text(legenda)
                    .font(.system(size: p(26), weight: .bold, design: .rounded))
                    .foregroundStyle(onColor)
                bookRow.padding(.top, p(30))
            }

        case let .meta(progresso, alvo, kicker, titulo, subtitulo):
            VStack(alignment: .leading, spacing: p(8)) {
                HStack(spacing: p(8)) {
                    Image(systemName: "sparkles").font(.system(size: p(18), weight: .bold))
                    Text(kicker.uppercased())
                        .font(.system(size: p(15), weight: .bold, design: .rounded)).tracking(p(2))
                }
                .foregroundStyle(Palette.mustard)
                Text("\(progresso)/\(alvo)")
                    .font(.system(size: p(168), weight: .heavy, design: .rounded))
                    .foregroundStyle(onColor).lineLimit(1).minimumScaleFactor(0.5)
                Text(titulo)
                    .font(.system(size: p(30), weight: .heavy, design: .rounded))
                    .foregroundStyle(onColor).padding(.top, p(6))
                Text(subtitulo)
                    .font(.system(size: p(16), weight: .medium))
                    .foregroundStyle(onColor.opacity(0.72)).padding(.top, p(4))
                HStack(spacing: p(8)) {
                    ForEach([Palette.coral, Palette.mint, Palette.lavender], id: \.self) { c in
                        RoundedRectangle(cornerRadius: p(6)).fill(c)
                            .frame(width: p(44), height: p(62))
                    }
                }
                .padding(.top, p(28))
            }

        case let .amigo(kicker, chip, rodape):
            VStack(spacing: p(14)) {
                Text(kicker.uppercased())
                    .font(.system(size: p(16), weight: .bold, design: .rounded))
                    .tracking(p(2)).foregroundStyle(onColor)
                bookLarge
                Text(livro.titulo)
                    .font(.system(size: p(30), weight: .heavy, design: .rounded))
                    .foregroundStyle(onColor).multilineTextAlignment(.center).lineLimit(2)
                if let autor = livro.autor, !autor.isEmpty {
                    Text(autor).font(.system(size: p(16), weight: .medium))
                        .foregroundStyle(onColor.opacity(0.85))
                }
                if livro.avaliacao_estrelas != nil { estrelas(size: p(24)) }
                HStack(spacing: p(8)) {
                    Image(systemName: "heart.fill").font(.system(size: p(16))).foregroundStyle(Palette.pink)
                    Text(chip).font(.system(size: p(15), weight: .bold))
                }
                .padding(.horizontal, p(20)).padding(.vertical, p(12))
                .background(Palette.ink).foregroundStyle(Color(hex: 0xFDF6EC))
                .clipShape(Capsule())
                .padding(.top, p(4))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // Livro (lombada ou foto) + título/autor/estrelas — usado no card de lido.
    private var bookRow: some View {
        HStack(alignment: .bottom, spacing: p(18)) {
            bookView(w: p(120), h: p(170)).rotationEffect(.degrees(-5))
                .shadow(color: .black.opacity(0.28), radius: p(22), y: p(14))
            VStack(alignment: .leading, spacing: p(3)) {
                Text(livro.titulo)
                    .font(.system(size: p(22), weight: .heavy, design: .rounded))
                    .foregroundStyle(onColor).lineLimit(2)
                if let autor = livro.autor, !autor.isEmpty {
                    Text(autor).font(.system(size: p(15), weight: .medium))
                        .foregroundStyle(onColor.opacity(0.9)).lineLimit(1)
                }
                if livro.avaliacao_estrelas != nil { estrelas(size: p(19)).padding(.top, p(8)) }
            }
            .padding(.bottom, p(6))
            Spacer(minLength: 0)
        }
    }

    private var bookLarge: some View {
        bookView(w: p(190), h: p(270)).rotationEffect(.degrees(3))
            .shadow(color: .black.opacity(0.32), radius: p(26), y: p(16))
    }

    // Capa: foto ou lombada colorida com a inicial (spec 16).
    private func bookView(w: CGFloat, h: CGFloat) -> some View {
        Group {
            if let coverImage {
                Image(uiImage: coverImage).resizable().scaledToFill()
                    .frame(width: w, height: h)
                    .clipShape(RoundedRectangle(cornerRadius: p(12), style: .continuous))
            } else {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: p(12), style: .continuous)
                        .fill(spineColor)
                    RoundedRectangle(cornerRadius: p(3), style: .continuous)
                        .fill(Color.black.opacity(0.18))
                        .frame(width: p(5)).padding(.vertical, p(11)).padding(.leading, p(11))
                    Text(inicial)
                        .font(.system(size: h * 0.42, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.leading, p(12))
                }
                .frame(width: w, height: h)
            }
        }
    }

    private func estrelas(size: CGFloat) -> some View {
        HStack(spacing: size * 0.16) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: (livro.avaliacao_estrelas ?? 0) >= i ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle((livro.avaliacao_estrelas ?? 0) >= i ? onColor : onColor.opacity(0.35))
            }
        }
    }

    // MARK: - Formas decorativas por variante

    @ViewBuilder private var formas: some View {
        switch kind {
        case .lido:
            circle(Palette.mustard, d: p(220)).position(x: p(400), y: p(46))
            circle(Palette.mint, d: p(250)).position(x: p(28), y: p(724))
            circle(Palette.pink, d: p(24)).position(x: p(48), y: p(144))
            ring(Palette.lavender, d: p(42), line: p(6)).position(x: p(402), y: p(320))
        case .meta:
            confete
        case .amigo:
            circle(Palette.mustard, d: p(210)).position(x: p(30), y: p(36))
            circle(Palette.sky, d: p(230)).position(x: p(404), y: p(724))
            circle(Palette.coral, d: p(22)).position(x: p(392), y: p(150))
        }
    }

    private var confete: some View {
        let cores: [Color] = [Palette.coral, Palette.mint, Palette.mustard, Palette.sky, Palette.pink, Palette.lavender]
        // Espalhado longe do canto superior esquerdo (onde fica a marca).
        let pts: [(CGFloat, CGFloat, Bool)] = [
            (360, 70, false), (300, 132, true), (250, 150, false), (388, 250, false),
            (80, 200, true), (180, 330, false), (360, 410, true), (60, 320, false)
        ]
        return ForEach(Array(pts.enumerated()), id: \.offset) { i, t in
            let round = t.2
            (round ? AnyView(Circle().fill(cores[i % cores.count]))
                   : AnyView(RoundedRectangle(cornerRadius: p(3)).fill(cores[i % cores.count]).rotationEffect(.degrees(Double((i * 37) % 40 - 20)))))
                .frame(width: p(round ? 15 : 11), height: p(round ? 15 : 24))
                .position(x: p(t.0), y: p(t.1))
        }
    }

    private func circle(_ c: Color, d: CGFloat) -> some View {
        Circle().fill(c).frame(width: d, height: d)
    }
    private func ring(_ c: Color, d: CGFloat, line: CGFloat) -> some View {
        Circle().stroke(c, lineWidth: line).frame(width: d, height: d)
    }

    private var inicial: String {
        livro.titulo.trimmingCharacters(in: .whitespacesAndNewlines).first.map { String($0).uppercased() } ?? "?"
    }
    private var kindIsMeta: Bool { if case .meta = kind { return true }; return false }
    private var rodape: String {
        switch kind {
        case .lido, .meta: return "compartilhado da minha estante"
        case let .amigo(_, _, r): return r
        }
    }
}
