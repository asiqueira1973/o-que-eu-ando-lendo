// BookCoverView.swift — lombada colorida e capa do livro (spec seção 16).
//
// Todo livro sem foto ganha uma "lombada" colorida com a inicial do título, numa
// cor determinística pelo `id` (sempre a mesma cor entre sessões, spec 24). Quando
// há foto (`livros.foto_arquivo`), mostra a foto no lugar. Componente reutilizado
// no feed, listas, detalhe e cartão compartilhável (spec 16).

import SwiftUI

/// A "lombada" ilustrada de um livro sem foto (spec 16): retângulo colorido, faixa
/// escura vertical à esquerda e a inicial do título em branco.
struct BookSpineView: View {
    let title: String
    let id: UUID
    var width: CGFloat
    var height: CGFloat

    // Primeira letra do título, maiúscula, para estampar na lombada (spec 16).
    private var initial: String {
        let letra = title.trimmingCharacters(in: .whitespacesAndNewlines).first
        return letra.map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
        let color = BookColor.color(for: id)
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: max(4, width * 0.1), style: .continuous)
                .fill(color)
            // Faixa escura da "lombada" (spec 16).
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.black.opacity(0.16))
                .frame(width: max(3, width * 0.07))
                .padding(.vertical, height * 0.09)
                .padding(.leading, width * 0.11)
            // Inicial do título (spec 16).
            Text(initial)
                .font(.system(size: height * 0.42, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.leading, width * 0.14)
        }
        .frame(width: width, height: height)
    }
}

/// Capa do livro: mostra a foto salva localmente ou cai para a lombada colorida
/// (spec 16). Carrega a imagem do disco de forma assíncrona (spec 17 — Home rápida).
struct BookCoverView: View {
    let livro: Livro
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat = 6

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                BookSpineView(title: livro.titulo, id: livro.id, width: width, height: height)
            }
        }
        .task(id: livro.foto_arquivo) {
            // Carrega a foto pelo nome guardado no livro; se não houver, fica a lombada.
            if let nome = livro.foto_arquivo {
                image = PhotoStorage.loadImage(named: nome)
            } else {
                image = nil
            }
        }
    }
}

/// Capa de largura flexível (preenche a coluna disponível) — usada no grid do
/// Top 3 da Home, onde a largura vem do layout, não de um valor fixo (spec 8.8/16).
struct FlexibleBookCover: View {
    let livro: Livro
    var height: CGFloat
    var cornerRadius: CGFloat = 10

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: geo.size.width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                } else {
                    BookSpineView(title: livro.titulo, id: livro.id, width: geo.size.width, height: height)
                }
            }
        }
        .frame(height: height)
        .task(id: livro.foto_arquivo) {
            if let nome = livro.foto_arquivo {
                image = PhotoStorage.loadImage(named: nome)
            } else {
                image = nil
            }
        }
    }
}
