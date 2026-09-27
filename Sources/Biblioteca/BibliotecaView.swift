// BibliotecaView.swift — todos os livros, filtráveis por status (spec seção 8.4/10/15/16).
//
// Substitui a antiga tela "Quero ler". Um segmentado no topo (Todos / Quero ler /
// Lendo / Lido, abrindo em "Todos") filtra a lista de cards. No filtro "Quero ler",
// cada card mostra quem indicou e o atalho "Comecei a ler" (spec 8.4). Um ícone de
// exportar na barra leva à tela Exportar (spec 8.9/10). "+" abre o cadastro já com
// o status do filtro ativo pré-selecionado.

import SwiftUI
import SwiftData

/// Filtro de status da Biblioteca (spec 8.4). "Todos" não tem status associado.
enum LibraryFilter: String, CaseIterable, Identifiable {
    case todos, quero_ler, lendo, lido
    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .todos: return "Todos"
        case .quero_ler: return "Quero ler"
        case .lendo: return "Lendo"
        case .lido: return "Lido"
        }
    }

    /// Status correspondente; nil em "Todos" (spec 8.4).
    var status: status_livro? {
        switch self {
        case .todos: return nil
        case .quero_ler: return .quero_ler
        case .lendo: return .lendo
        case .lido: return .lido
        }
    }
}

struct BibliotecaView: View {
    /// Filtro ativo — controlado externamente para o "Ver tudo" da Home poder abrir
    /// a Biblioteca já em "Lendo" (spec 8.8/8.4).
    @Binding var filtro: LibraryFilter

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: StoreManager
    @Query private var livros: [Livro]
    @State private var sheet: BibliotecaSheet?

    // Um único `.sheet` por view — exportar e adicionar dividem o enum (evita o
    // conflito de dois `.sheet` na mesma view).
    private enum BibliotecaSheet: Identifiable {
        case exportar, adicionar
        var id: Int { hashValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    segmentado
                    if filtrados.isEmpty {
                        estadoVazio.padding(.top, 40)
                    } else {
                        ForEach(filtrados) { livro in
                            itemCard(livro)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 120)
            }
            .background(Palette.screen.ignoresSafeArea())
            .navigationDestination(for: Livro.self) { livro in
                BookDetailView(livro: livro).environmentObject(store)
            }
        }
        .sheet(item: $sheet) { qual in
            switch qual {
            case .exportar: ExportView()
            case .adicionar: BookFormView(statusInicial: filtro.status ?? .quero_ler).environmentObject(store)
            }
        }
    }

    // MARK: - Cabeçalho e segmentado

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SUA COLEÇÃO")
                    .font(.system(size: 12, weight: .bold)).tracking(1.2)
                    .foregroundStyle(Palette.textMuted)
                Text("Biblioteca")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Palette.textPrimary)
            }
            Spacer()
            // Ícone de exportar (spec 8.4/8.9).
            Button { sheet = .exportar } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Palette.card).clipShape(Circle())
                    
            }
            .accessibilityLabel("Exportar")
            // "+" pré-selecionando o status do filtro ativo (spec 8.4).
            Button { sheet = .adicionar } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 38, height: 38).background(Palette.accent).clipShape(Circle())
            }
            .accessibilityLabel("Registrar livro")
        }
    }

    private var segmentado: some View {
        HStack(spacing: 4) {
            ForEach(LibraryFilter.allCases) { f in
                let sel = filtro == f
                Text(f.titulo)
                    .font(.system(size: 13, weight: sel ? .heavy : .semibold))
                    .foregroundStyle(sel ? Palette.textPrimary : Palette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(sel ? Palette.card : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { filtro = f } }
            }
        }
        .padding(4)
        .background(Palette.segmentTrack)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Lista

    // Livros do filtro ativo, ordenados (spec 8.4/11): "Todos" por atualizado_em
    // desc (mistura status); os demais por uma ordem natural de cada status.
    private var filtrados: [Livro] {
        let base: [Livro]
        switch filtro {
        case .todos:
            base = livros.sorted { $0.atualizado_em > $1.atualizado_em }
        case .quero_ler:
            base = livros.filter { $0.status == .quero_ler }.sorted { $0.criado_em > $1.criado_em }
        case .lendo:
            base = livros.filter { $0.status == .lendo }.sorted { $0.atualizado_em > $1.atualizado_em }
        case .lido:
            base = livros.filter { $0.status == .lido }
                .sorted { ($0.data_conclusao ?? .distantPast) > ($1.data_conclusao ?? .distantPast) }
        }
        return base
    }

    private func itemCard(_ livro: Livro) -> some View {
        HStack(spacing: 14) {
            NavigationLink(value: livro) {
                HStack(spacing: 14) {
                    BookCoverView(livro: livro, width: 46, height: 64, cornerRadius: 5)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(livro.titulo)
                            .font(.system(size: 15.5, weight: .bold))
                            .foregroundStyle(Palette.textPrimary).lineLimit(1)
                        if let autor = livro.autor {
                            Text(autor).font(.system(size: 12.5)).foregroundStyle(Palette.textSecondary).lineLimit(1)
                        }
                        // No filtro "Quero ler", mostra quem indicou (spec 8.4).
                        if filtro == .quero_ler, let indicado = livro.indicado_por, !indicado.isEmpty {
                            Text("Indicado por \(indicado)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.textSecondary).lineLimit(1)
                        }
                        // Estrelas quando avaliado; data quando lido.
                        HStack(spacing: 8) {
                            if livro.avaliacao_estrelas != nil {
                                StarRatingView(rating: .constant(livro.avaliacao_estrelas), interactive: false, size: 12)
                            }
                            if livro.status == .lido, let fim = livro.data_conclusao {
                                Text(AppDate.curto(fim)).font(.system(size: 12)).foregroundStyle(Palette.textMuted)
                            } else if livro.status == .lendo {
                                Text("Lendo agora").font(.system(size: 11, weight: .bold)).foregroundStyle(Palette.accent)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            // Atalho "Comecei a ler" só no filtro "Quero ler" (spec 8.4).
            if filtro == .quero_ler {
                Button { comecarLeitura(livro) } label: {
                    Text("Comecei a ler")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Palette.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estanteCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AccessibilityLabels.book(livro))
    }

    // Estado vazio por filtro, com as copies exatas da spec 15.
    private var estadoVazio: some View {
        VStack(spacing: 16) {
            Text(copyVazio)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.textSecondary)
            Button { sheet = .adicionar } label: {
                Text("Registrar livro")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 14)
                    .background(Palette.accent).clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private var copyVazio: String {
        switch filtro {
        case .todos:     return "Sua biblioteca está vazia. Registre o primeiro livro pra começar."
        case .quero_ler: return "Nenhum livro na sua lista de desejos ainda. Alguém te indicou algo bom recentemente?"
        case .lendo:     return "Você não está com nenhum livro em andamento agora. Bora começar um?"
        case .lido:      return "Nenhum livro marcado como lido ainda."
        }
    }

    // Atalho "Comecei a ler": muda o status para `lendo` sem abrir o formulário (spec 8.4).
    private func comecarLeitura(_ livro: Livro) {
        livro.status = .lendo
        livro.atualizado_em = Date()
        try? context.save()
    }
}
