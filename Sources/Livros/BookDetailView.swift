// BookDetailView.swift — detalhe do livro (spec seção 8.2/8.5/8.11/10/16).
//
// Mostra todos os campos do livro (design tela 3): capa grande, status, título,
// autor/editora, estrelas, anotação, datas e duração. Dá acesso a Editar (reabre
// o formulário, spec 8.2), Excluir (com confirmação, hard delete, spec 8.5) e ao
// Cartão compartilhável quando o livro é `lido` (spec 8.11).

import SwiftUI
import SwiftData

struct BookDetailView: View {
    let livro: Livro

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: StoreManager
    @Query private var todosLivros: [Livro]

    @State private var sheet: DetailSheet?
    @State private var confirmarExclusao = false

    // Uma única apresentação de sheet por vez — SwiftUI só honra um `.sheet` por
    // view, então edição e cartão compartilham este enum (spec 8.2/8.11).
    private enum DetailSheet: Identifiable {
        case editar, cartao, amigo
        var id: Int { hashValue }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Palette.screen.ignoresSafeArea()
            // Fundo colorido suave no topo, na cor do livro (spec 16).
            LinearGradient(colors: [BookColor.color(for: livro.id).opacity(0.28), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 300)
                .ignoresSafeArea(edges: .top)

            ScrollView {
                VStack(spacing: 14) {
                    capaEcabecalho
                    if let comentario = livro.comentario, !comentario.isEmpty {
                        anotacaoCard(comentario)
                    }
                    datasRow
                    if livro.status == .lido {
                        cartaoCTA
                        amigoCTA
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .padding(.top, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") { sheet = .editar }.foregroundStyle(Palette.accent)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { confirmarExclusao = true } label: {
                    Image(systemName: "trash").foregroundStyle(Palette.accent)
                }
            }
        }
        .sheet(item: $sheet) { qual in
            switch qual {
            case .editar: BookFormView(editing: livro).environmentObject(store)
            case .cartao: ShareCardView(livro: livro)
            case .amigo: ShareCardView(livro: livro, mode: .amigo)
            }
        }
        .confirmationDialog("Excluir este livro?", isPresented: $confirmarExclusao, titleVisibility: .visible) {
            Button("Excluir", role: .destructive) { excluir() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Essa ação não pode ser desfeita.")
        }
        .accessibilityLabel(AccessibilityLabels.book(livro))
    }

    // MARK: - Seções

    private var capaEcabecalho: some View {
        VStack(spacing: 8) {
            BookCoverView(livro: livro, width: 172, height: 246, cornerRadius: 12)
                .shadow(color: BookColor.color(for: livro.id).opacity(0.35), radius: 20, y: 14)

            Text(badgeStatus)
                .font(.system(size: 12, weight: .heavy)).tracking(1)
                .foregroundStyle(corStatus)
                .padding(.top, 12)

            Text(livro.titulo)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)

            if let subtitulo = autorEditora {
                Text(subtitulo)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textSecondary)
            }

            if livro.avaliacao_estrelas != nil {
                StarRatingView(rating: .constant(livro.avaliacao_estrelas), interactive: false, size: 22)
                    .padding(.top, 4)
            }
        }
    }

    private func anotacaoCard(_ texto: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SUA ANOTAÇÃO")
                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundStyle(Palette.textMuted)
            Text(texto)
                .font(.system(size: 15.5))
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estanteCard(cornerRadius: 22)
    }

    private var datasRow: some View {
        HStack(spacing: 12) {
            if let inicio = livro.data_inicio_leitura {
                dataCard(rotulo: "Comecei", valor: AppDate.curto(inicio))
            }
            if let fim = livro.data_conclusao {
                dataCard(rotulo: "Lido", valor: AppDate.curto(fim))
            }
            if let duracao = duracaoDias {
                dataCard(rotulo: "Em", valor: duracao)
            }
        }
    }

    private func dataCard(rotulo: String, valor: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rotulo.uppercased())
                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundStyle(Palette.textMuted)
            Text(valor)
                .font(.system(size: 15.5, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estanteCard(cornerRadius: 20)
    }

    private var cartaoCTA: some View {
        Button { sheet = .cartao } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.accent)
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "sparkles").foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Card de compartilhar")
                        .font(.system(size: 16.5, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Poste “livro nº \(posicaoAno) do ano” nos seus stories")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.5))
            }
            .padding(18)
            .background(Palette.ink)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    // Novo: compartilhar o livro com um amigo, no mesmo formato stories (spec 16).
    private var amigoCTA: some View {
        Button { sheet = .amigo } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "heart.fill").foregroundStyle(Palette.accent))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compartilhar com um amigo")
                        .font(.system(size: 16.5, weight: .heavy))
                        .foregroundStyle(Palette.textPrimary)
                    Text("Um card de recomendação pra mandar pra alguém")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Palette.textMuted)
            }
            .padding(18)
            .estanteCard(cornerRadius: 22)
        }
    }

    // MARK: - Derivados

    private var badgeStatus: String {
        if livro.status == .lido {
            return "● \(livro.status.displayName) · livro #\(posicaoAno)"
        }
        return "● \(livro.status.displayName)"
    }

    private var corStatus: Color {
        switch livro.status {
        // Revisão 27/09/2026: status numa cor só (destaque azul), sem arco-íris.
        case .quero_ler, .lendo, .lido: return Palette.accent
        }
    }

    private var autorEditora: String? {
        switch (livro.autor, livro.editora) {
        case let (a?, e?): return "\(a) · \(e)"
        case let (a?, nil): return a
        case let (nil, e?): return e
        default: return nil
        }
    }

    // Posição do livro no ano corrente do próprio livro (spec 11) — usado no badge/CTA.
    private var posicaoAno: Int {
        ReadingStats.posicaoNoPeriodo(livro, tipo: .anual, todos: todosLivros)
    }

    // Duração da leitura em dias, quando há início e fim (spec 16 — card "Em").
    private var duracaoDias: String? {
        guard let inicio = livro.data_inicio_leitura, let fim = livro.data_conclusao else { return nil }
        let dias = Calendar.current.dateComponents([.day], from: inicio, to: fim).day ?? 0
        guard dias >= 0 else { return nil }
        return dias == 1 ? "1 dia" : "\(dias) dias"
    }

    // Exclui o livro: apaga a foto local e remove o registro (hard delete, spec 8.5).
    // Não mexe em `metas.meta_atingida_em` — o selo de meta batida não regride (spec 11).
    private func excluir() {
        if let nome = livro.foto_arquivo { PhotoStorage.delete(named: nome) }
        context.delete(livro)
        try? context.save()
        dismiss()
    }
}
