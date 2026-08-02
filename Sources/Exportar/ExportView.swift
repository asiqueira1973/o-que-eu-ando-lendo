// ExportView.swift — exportar livros lidos por período (spec seção 8.9/10/14).
//
// Escolhe o tipo de período (mês/trimestre/semestre/ano/intervalo customizado) e o
// período específico, gera o CSV (spec 14) e abre a folha de compartilhamento
// nativa — o app nunca decide sozinho o destino do arquivo (spec 8.9). Apresentada
// a partir das Configurações.

import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var livros: [Livro]

    enum TipoExport: String, CaseIterable { case mes, trimestre, semestre, ano, intervalo
        var label: String {
            switch self {
            case .mes: return "Mês"; case .trimestre: return "Trimestre"
            case .semestre: return "Semestre"; case .ano: return "Ano"; case .intervalo: return "Intervalo"
            }
        }
    }

    @State private var tipo: TipoExport = .mes
    @State private var ano = Calendar.current.component(.year, from: Date())
    @State private var numero = Calendar.current.component(.month, from: Date())
    @State private var inicio = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var fim = Date()
    @State private var arquivoURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    tipoSelector
                    periodoSelector
                    Button { exportar() } label: {
                        Text("Exportar CSV")
                            .font(.system(size: 17, weight: .heavy)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Palette.coral)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    Text("Gera um arquivo CSV com os livros lidos no período (abre no Excel/Numbers).")
                        .font(.system(size: 12.5)).foregroundStyle(Palette.textMuted)
                }
                .padding(20)
            }
            .background(Palette.screen.ignoresSafeArea())
            .navigationTitle("Exportar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }.foregroundStyle(Palette.coral)
                }
            }
            .sheet(item: Binding(
                get: { arquivoURL.map { ExportFile(url: $0) } },
                set: { arquivoURL = $0?.url }
            )) { wrapper in
                ActivityView(items: [wrapper.url])
            }
        }
    }

    private var tipoSelector: some View {
        Picker("Tipo", selection: $tipo) {
            ForEach(TipoExport.allCases, id: \.self) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
        .onChange(of: tipo) { _, _ in ajustarNumero() }
    }

    @ViewBuilder private var periodoSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            if tipo == .intervalo {
                DatePicker("Início", selection: $inicio, displayedComponents: .date)
                DatePicker("Fim", selection: $fim, displayedComponents: .date)
            } else {
                HStack {
                    Text("Ano").foregroundStyle(Palette.textSecondary)
                    Spacer()
                    // Text(verbatim:) evita o separador de milhar do LocalizedStringKey (ex.: "2.026").
                    Stepper(value: $ano, in: 2000...2100) { Text(verbatim: String(ano)) }.fixedSize()
                }
                if let range = rangeNumero {
                    Picker(tipo.label, selection: $numero) {
                        ForEach(Array(range), id: \.self) { Text(nomeNumero($0)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estanteCard(cornerRadius: 22)
    }

    // MARK: - Lógica

    private var rangeNumero: ClosedRange<Int>? {
        switch tipo {
        case .mes: return 1...12
        case .trimestre: return 1...4
        case .semestre: return 1...2
        case .ano, .intervalo: return nil
        }
    }

    private func nomeNumero(_ n: Int) -> String {
        switch tipo {
        case .mes: return String(PeriodCalculator.nomeDoMes(n).prefix(3))
        case .trimestre, .semestre: return "\(n)º"
        default: return "\(n)"
        }
    }

    private func ajustarNumero() {
        if let range = rangeNumero, !range.contains(numero) { numero = range.lowerBound }
    }

    // Monta o escopo escolhido (spec 14) e gera o arquivo.
    private func scopeAtual() -> ExportScope {
        switch tipo {
        case .mes: return .mes(ano: ano, mes: numero)
        case .trimestre: return .trimestre(ano: ano, numero: numero)
        case .semestre: return .semestre(ano: ano, numero: numero)
        case .ano: return .ano(ano)
        case .intervalo: return .intervalo(inicio: inicio, fim: fim)
        }
    }

    private func exportar() {
        arquivoURL = ExportViewModel.gerarArquivo(scope: scopeAtual(), livros: livros)
    }
}

/// Wrapper Identifiable para apresentar a folha de compartilhamento com o arquivo.
private struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}
