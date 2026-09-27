// GoalsView.swift — lista de metas de leitura (spec seção 8.6/10/16).
//
// Lista todas as metas ativas com progresso "X de Y livros" calculado em tempo real
// a partir de `livros` (sem FK, spec 11), e um selo "BATIDA" quando `meta_atingida_em`
// está preenchido (spec 8.7/11). Metas são opcionais — a tela funciona vazia (spec 8.6).

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Query private var metas: [Meta]
    @Query private var livros: [Livro]
    @State private var novaMeta = false

    private var metasOrdenadas: [Meta] {
        metas.sorted { ($0.ano, ordem($0.tipo_periodo)) < ($1.ano, ordem($1.tipo_periodo)) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    ForEach(metasOrdenadas) { meta in
                        metaCard(meta)
                    }
                    novaMetaButton
                }
                .padding(20)
                .padding(.bottom, 120)
            }
            .background(Palette.screen.ignoresSafeArea())
        }
        .sheet(isPresented: $novaMeta) { GoalFormView() }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(metas.count) \(metas.count == 1 ? "meta ativa" : "metas ativas")".uppercased())
                    .font(.system(size: 12, weight: .bold)).tracking(1.2).foregroundStyle(Palette.textMuted)
                Text("Metas")
                    .font(.system(size: 32, weight: .heavy)).foregroundStyle(Palette.textPrimary)
            }
            Spacer()
            Button { novaMeta = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 38, height: 38).background(Palette.accent).clipShape(Circle())
            }
        }
    }

    private func metaCard(_ meta: Meta) -> some View {
        let progresso = GoalsViewModel.progresso(da: meta, livros: livros)
        let cor = cor(meta.tipo_periodo)
        let fracao = min(1, Double(progresso) / Double(max(1, meta.quantidade_alvo)))
        let batida = meta.meta_atingida_em != nil

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(rotuloPeriodo(meta).uppercased())
                    .font(.system(size: 12, weight: .heavy)).tracking(1)
                    .foregroundStyle(Palette.textMuted)
                Spacer()
                if batida {
                    Text("BATIDA ✦")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(cor)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(cor.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text("\(progresso) / \(meta.quantidade_alvo)")
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.textSecondary)
                }
            }
            Text("\(progresso) de \(meta.quantidade_alvo) livros")
                .font(.system(size: 30, weight: .heavy)).foregroundStyle(Palette.textPrimary)
            ProgressBar(fraction: fracao, cor: cor)
                .frame(height: 10)
                .padding(.top, 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Revisão 27/09/2026: card branco com só a barra no azul de destaque, em vez
        // do card inteiro colorido — mais discreto, padrão iOS.
        .estanteCard(cornerRadius: 24)
        .contextMenu {
            Button(role: .destructive) { excluir(meta) } label: { Label("Excluir meta", systemImage: "trash") }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Meta \(rotuloPeriodo(meta)): \(progresso) de \(meta.quantidade_alvo) livros\(batida ? ", batida" : "")")
    }

    private var novaMetaButton: some View {
        Button { novaMeta = true } label: {
            VStack(spacing: 4) {
                Text("+ Nova meta").font(.system(size: 16, weight: .heavy)).foregroundStyle(Palette.textSecondary)
                Text("Escolha um período e um número. É só isso.")
                    .font(.system(size: 12.5)).foregroundStyle(Palette.textMuted)
            }
            .frame(maxWidth: .infinity).padding(20)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .foregroundStyle(Palette.dashedBorder)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func cor(_ tipo: tipo_periodo_meta) -> Color {
        switch tipo {
        // Revisão 27/09/2026: todas as metas no azul de destaque, sem cor por período.
        case .mensal, .trimestral, .semestral, .anual: return Palette.accent
        }
    }

    private func rotuloPeriodo(_ meta: Meta) -> String {
        switch meta.tipo_periodo {
        case .mensal:     return "Este mês · \(PeriodCalculator.nomeDoMes(meta.numero_periodo ?? 1))"
        case .trimestral: return "Trimestre · \(meta.numero_periodo ?? 1)º"
        case .semestral:  return "Semestre · \(meta.numero_periodo ?? 1)º"
        case .anual:      return "Este ano · \(meta.ano)"
        }
    }

    private func ordem(_ tipo: tipo_periodo_meta) -> Int {
        switch tipo {
        case .mensal: return 0
        case .trimestral: return 1
        case .semestral: return 2
        case .anual: return 3
        }
    }

    // Exclui uma meta (hard delete, spec 7.3). Não afeta os livros registrados.
    private func excluir(_ meta: Meta) {
        context.delete(meta)
        try? context.save()
    }
}

/// Barra de progresso branca sobre o card colorido da meta (spec 8.6/16).
private struct ProgressBar: View {
    let fraction: Double
    let cor: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6).fill(Palette.segmentTrack)
                RoundedRectangle(cornerRadius: 6).fill(cor)
                    .frame(width: geo.size.width * fraction)
            }
        }
    }
}
