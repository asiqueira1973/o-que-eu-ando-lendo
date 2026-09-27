// GoalFormView.swift — criação de uma meta de leitura (spec seção 8.6/10/12).
//
// Escolhe o tipo de período (mês/trimestre/semestre/ano), o período específico e a
// quantidade-alvo. Valida via GoalsViewModel: bloqueia duplicata e alvo <= 0, com
// aviso claro (spec 8.6/12). Metas são inteiramente opcionais (spec 8.6).

import SwiftUI
import SwiftData

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var metas: [Meta]

    @State private var tipo: tipo_periodo_meta = .anual
    @State private var ano: Int = Calendar.current.component(.year, from: Date())
    @State private var numero: Int = Calendar.current.component(.month, from: Date())
    @State private var alvo: Int = 12
    @State private var erro: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    tipoSelector
                    periodoSelector
                    alvoStepper
                }
                .padding(20)
            }
            .background(Palette.screen.ignoresSafeArea())
            .navigationTitle("Nova meta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }.foregroundStyle(Palette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { salvar() }.fontWeight(.bold).foregroundStyle(Palette.accent)
                }
            }
            .alert("Não deu para salvar", isPresented: Binding(
                get: { erro != nil }, set: { if !$0 { erro = nil } }
            )) {
                Button("OK", role: .cancel) { erro = nil }
            } message: { Text(erro ?? "") }
        }
    }

    private var tipoSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TIPO DE PERÍODO")
                .font(.system(size: 11, weight: .bold)).tracking(0.8).foregroundStyle(Palette.textMuted)
            HStack(spacing: 6) {
                ForEach(tipo_periodo_meta.allCases, id: \.self) { t in
                    let sel = tipo == t
                    Text(t.displayName)
                        .font(.system(size: 13, weight: sel ? .heavy : .semibold))
                        .foregroundStyle(sel ? .white : Palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(sel ? Palette.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .onTapGesture { tipo = t; ajustarNumero() }
                }
            }
            .padding(4).background(Palette.segmentTrack)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // Seleção do período específico conforme o tipo (spec 7.3): ano sempre; mês/
    // trimestre/semestre quando aplicável.
    @ViewBuilder private var periodoSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ANO").font(.system(size: 11, weight: .bold)).tracking(0.8).foregroundStyle(Palette.textMuted)
                Spacer()
                // Text(verbatim:) evita o separador de milhar (ex.: "2.026").
                Stepper(value: $ano, in: 2000...2100) { Text(verbatim: String(ano)) }.fixedSize()
            }
            if let range = tipo.numeroPeriodoRange {
                Picker(rotuloNumero, selection: $numero) {
                    ForEach(Array(range), id: \.self) { n in
                        Text(nomeNumero(n)).tag(n)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estanteCard(cornerRadius: 22)
    }

    private var alvoStepper: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("QUANTIDADE-ALVO")
                    .font(.system(size: 11, weight: .bold)).tracking(0.8).foregroundStyle(Palette.textMuted)
                Text("\(alvo) livros")
                    .font(.system(size: 22, weight: .heavy)).foregroundStyle(Palette.textPrimary)
            }
            Spacer()
            Stepper("", value: $alvo, in: 1...999).labelsHidden()
        }
        .padding(16)
        .estanteCard(cornerRadius: 22)
    }

    // MARK: - Lógica

    private var rotuloNumero: String {
        switch tipo {
        case .mensal: return "Mês"
        case .trimestral: return "Trimestre"
        case .semestral: return "Semestre"
        case .anual: return ""
        }
    }

    private func nomeNumero(_ n: Int) -> String {
        switch tipo {
        case .mensal: return String(PeriodCalculator.nomeDoMes(n).prefix(3))
        case .trimestral: return "\(n)º"
        case .semestral: return "\(n)º"
        case .anual: return ""
        }
    }

    // Ajusta o número ao trocar de tipo para caber na faixa válida (spec 7.3).
    private func ajustarNumero() {
        guard let range = tipo.numeroPeriodoRange else { return }
        if !range.contains(numero) { numero = range.lowerBound }
    }

    // Valida e salva a meta (spec 8.6). Anual não usa numero_periodo (nil, spec 7.3).
    private func salvar() {
        let numeroFinal: Int? = tipo.numeroPeriodoRange == nil ? nil : numero
        if let e = GoalsViewModel.validar(tipo: tipo, ano: ano, numero: numeroFinal, alvo: alvo, existentes: metas) {
            erro = e.mensagem
            return
        }
        let meta = Meta(tipo_periodo: tipo, ano: ano, numero_periodo: numeroFinal, quantidade_alvo: alvo)
        context.insert(meta)
        try? context.save()
        dismiss()
    }
}
