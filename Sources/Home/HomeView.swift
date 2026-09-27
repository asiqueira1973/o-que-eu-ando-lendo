// HomeView.swift — tela inicial "Sua estante" (spec seção 8.8/10/15/16).
//
// Três blocos, nesta ordem (spec 8.8): indicadores de período no topo, Top 3 do
// ano e feed cronológico de lidos. Livros em `lendo` aparecem destacados antes do
// feed. Estado vazio com a copy da spec 15 e atalho para cadastrar o primeiro livro.

import SwiftUI
import SwiftData

struct HomeView: View {
    /// Ação do "Ver tudo" da seção "Lendo agora" — abre a Biblioteca em "Lendo" (spec 8.8).
    var onVerTudoLendo: () -> Void = {}

    @Query private var livros: [Livro]
    @EnvironmentObject private var store: StoreManager
    @State private var adicionar = false

    private var vm: HomeViewModel { HomeViewModel(livros: livros) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    indicadores.padding(.top, 16)

                    if !vm.lendoAgora.isEmpty {
                        secaoLendo.padding(.top, 24)
                        lendoAgora
                    }

                    if vm.temAlgumLido {
                        if !vm.top3.isEmpty {
                            secao("Top 3 do ano", detalhe: "suas melhores leituras").padding(.top, 26)
                            top3Grid
                        }
                        secao("Lidos recentemente").padding(.top, 26)
                        feed
                    } else {
                        estadoVazio.padding(.top, 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .background(Palette.screen.ignoresSafeArea())
            .navigationDestination(for: Livro.self) { livro in
                BookDetailView(livro: livro).environmentObject(store)
            }
        }
        .sheet(isPresented: $adicionar) {
            BookFormView().environmentObject(store)
        }
    }

    // MARK: - Cabeçalho e indicadores

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(mesAnoCorrente.uppercased())
                .font(.system(size: 12, weight: .bold)).tracking(1.2)
                .foregroundStyle(Palette.textMuted)
            Text("Sua estante")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(Palette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    // Indicadores: só mês e ano correntes, para a Home ficar mais limpa (spec 8.8).
    // Revisão 27/09/2026: blocos neutros iguais (cinza, número escuro) no lugar de
    // um bloco coral e outro azul — uma cor de destaque só no app, padrão iOS.
    private var indicadores: some View {
        let i = vm.indicadores
        return HStack(spacing: 12) {
            statPill(i.mes, "Este mês")
            statPill(i.ano, "Este ano")
        }
    }

    private func statPill(_ valor: Int, _ rotulo: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(valor)")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(Palette.textPrimary)
            Text(rotulo)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(Palette.tile)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(valor) livros lidos — \(rotulo)")
    }

    // MARK: - Lendo agora

    // Cabeçalho da seção "Lendo agora" com "Ver tudo" quando há mais de 2 (spec 8.8).
    private var secaoLendo: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Lendo agora")
                .font(.system(size: 19, weight: .heavy))
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            if vm.lendoAgora.count > 2 {
                Button(action: onVerTudoLendo) {
                    Text("Ver tudo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 10)
    }

    private var lendoAgora: some View {
        // Mostra só os 2 mais recentes; o restante fica atrás do "Ver tudo" (spec 8.8).
        VStack(spacing: 10) {
            ForEach(vm.lendoAgora.prefix(2)) { livro in
                NavigationLink(value: livro) {
                    HStack(spacing: 12) {
                        BookCoverView(livro: livro, width: 46, height: 64, cornerRadius: 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(livro.titulo)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Palette.textPrimary).lineLimit(1)
                            if let autor = livro.autor {
                                Text(autor).font(.system(size: 12)).foregroundStyle(Palette.textSecondary).lineLimit(1)
                            }
                            Text("Lendo agora")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Palette.accent)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .estanteCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Top 3

    private var top3Grid: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(Array(vm.top3.enumerated()), id: \.element.id) { idx, livro in
                NavigationLink(value: livro) {
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack(alignment: .topTrailing) {
                            FlexibleBookCover(livro: livro, height: 120, cornerRadius: 10)
                            Text("\(idx + 1)")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Palette.ink).clipShape(Circle())
                                .padding(8)
                        }
                        Text(livro.titulo)
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(Palette.textPrimary).lineLimit(2)
                        if livro.avaliacao_estrelas != nil {
                            StarRatingView(rating: .constant(livro.avaliacao_estrelas), interactive: false, size: 11)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .estanteCard()
                }
                .buttonStyle(.plain)
            }
            // Preenche colunas vazias para manter o grid alinhado quando há < 3.
            ForEach(0..<(3 - vm.top3.count), id: \.self) { _ in
                Color.clear.frame(maxWidth: .infinity, minHeight: 1)
            }
        }
    }

    // MARK: - Feed

    private var feed: some View {
        let posicoes = vm.posicoesNoAno
        return VStack(spacing: 10) {
            ForEach(vm.feed) { livro in
                NavigationLink(value: livro) {
                    FeedBookCard(livro: livro, posicaoAno: posicoes[livro.id])
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Estado vazio (spec 15)

    private var estadoVazio: some View {
        VStack(spacing: 16) {
            Text("Sua estante está esperando o primeiro livro. Bora começar? 📚")
                .font(.system(size: 17, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.textSecondary)
            Button { adicionar = true } label: {
                Text("Registrar livro")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 14)
                    .background(Palette.accent)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Helpers

    private func secao(_ titulo: String, detalhe: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(titulo)
                .font(.system(size: 19, weight: .heavy))
                .foregroundStyle(Palette.textPrimary)
            if let detalhe {
                Text(detalhe).font(.system(size: 13)).foregroundStyle(Palette.textMuted)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 10)
    }

    private var mesAnoCorrente: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "MMMM 'de' yyyy"
        return f.string(from: Date())
    }
}

/// Card do feed de livros lidos (spec 8.8/16) — reutilizado na Home.
struct FeedBookCard: View {
    let livro: Livro
    var posicaoAno: Int?

    var body: some View {
        HStack(spacing: 14) {
            BookCoverView(livro: livro, width: 52, height: 74, cornerRadius: 6)
            VStack(alignment: .leading, spacing: 2) {
                if let posicaoAno {
                    HStack(spacing: 6) {
                        Text("#\(posicaoAno)")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(BookColor.ink(for: livro.id))
                        Text("no ano").font(.system(size: 11)).foregroundStyle(Palette.textMuted)
                    }
                }
                Text(livro.titulo)
                    .font(.system(size: 15.5, weight: .bold))
                    .foregroundStyle(Palette.textPrimary).lineLimit(1)
                if let autor = livro.autor {
                    Text(autor).font(.system(size: 12.5)).foregroundStyle(Palette.textSecondary).lineLimit(1)
                }
                HStack(spacing: 8) {
                    if livro.avaliacao_estrelas != nil {
                        StarRatingView(rating: .constant(livro.avaliacao_estrelas), interactive: false, size: 13)
                    }
                    if let fim = livro.data_conclusao {
                        Text(AppDate.curto(fim)).font(.system(size: 12)).foregroundStyle(Palette.textMuted)
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estanteCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessibilityLabels.book(livro))
    }
}
