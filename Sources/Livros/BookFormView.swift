// BookFormView.swift — cadastro e edição de livro (spec seção 8.1/8.2/8.3/10/16).
//
// Formulário do design (tela 2): foto com preview da lombada, título (obrigatório),
// autor/editora, status segmentado, estrelas, comentário, indicado por e datas.
// Título é o único campo obrigatório; o resto é opcional/preenchível depois
// (spec 0.2/8.1). Ao salvar, o BookFormViewModel aplica trial (8.10), regras de
// data (11) e meta batida (8.7); esta View reage ao desfecho (Paywall/celebração).

import SwiftUI
import SwiftData
import PhotosUI

struct BookFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: StoreManager
    @Query private var todosLivros: [Livro]
    @Query private var todasMetas: [Meta]

    @StateObject private var vm: BookFormViewModel

    @State private var photoItem: PhotosPickerItem?
    @State private var formSheet: FormSheet?
    @State private var filaCelebracao: [Meta] = []

    // Um único `.sheet` por view (SwiftUI só honra um) — câmera e Paywall dividem
    // este enum (spec 8.1/8.10).
    private enum FormSheet: Identifiable {
        case camera, paywall
        var id: Int { hashValue }
    }
    @State private var metaCelebrando: Meta?
    @State private var livroSalvo: Livro?

    private let ehEdicao: Bool

    // Cria o formulário para um livro novo (com status inicial) ou para editar um
    // existente (spec 8.1/8.2/8.4).
    init(editing livro: Livro? = nil, statusInicial: status_livro = .quero_ler) {
        _vm = StateObject(wrappedValue: BookFormViewModel(editing: livro, statusInicial: statusInicial))
        self.ehEdicao = livro != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    photoCard
                    textFieldsCard
                    statusSegmented
                    ratingCard
                    commentCard
                    indicadoPorRow
                    datesRow
                    if vm.status == .lido {
                        Text("Esse vai ser o livro #\(numeroPreview) do seu ano 🎉")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Palette.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
            }
            .background(Palette.screen.ignoresSafeArea())
            .navigationTitle(ehEdicao ? "Editar livro" : "Adicionar livro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }.foregroundStyle(Palette.coral)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { salvar() }
                        .fontWeight(.bold)
                        .foregroundStyle(vm.podeSalvar ? Palette.coral : Palette.textMuted)
                        .disabled(!vm.podeSalvar)
                }
            }
        }
        .onChange(of: photoItem) { _, novo in carregarFoto(novo) }
        .sheet(item: $formSheet) { qual in
            switch qual {
            case .camera:
                CameraPicker { img in vm.novaFoto = img; vm.removerFoto = false }
                    .ignoresSafeArea()
            case .paywall:
                PaywallView(onDesbloqueado: { salvar() })
                    .environmentObject(store)
            }
        }
        // Celebração de meta batida, uma tela por meta em sequência (spec 8.7).
        .fullScreenCover(item: $metaCelebrando, onDismiss: proximaCelebracao) { meta in
            if let livroSalvo {
                GoalReachedView(meta: meta, livro: livroSalvo)
            }
        }
        .alert("Aviso", isPresented: Binding(
            get: { vm.aviso != nil }, set: { if !$0 { vm.aviso = nil } }
        )) {
            Button("OK", role: .cancel) { vm.aviso = nil }
        } message: { Text(vm.aviso ?? "") }
    }

    // MARK: - Seções da tela

    private var photoCard: some View {
        HStack(spacing: 16) {
            preview
                .frame(width: 88, height: 126)
            VStack(alignment: .leading, spacing: 8) {
                Text("Sem foto? Seu livro fica com essa cor para sempre.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary)
                Button { formSheet = .camera } label: {
                    botaoFoto("Tirar foto")
                }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    botaoFoto("Escolher da galeria")
                }
            }
        }
        .padding(16)
        .estanteCard(cornerRadius: 22)
    }

    // Preview: foto nova, foto existente ou a lombada colorida (spec 16).
    @ViewBuilder private var preview: some View {
        if let img = vm.novaFoto {
            Image(uiImage: img).resizable().scaledToFill()
                .frame(width: 88, height: 126)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else if let nome = vm.fotoArquivoExistente, !vm.removerFoto,
                  let img = PhotoStorage.loadImage(named: nome) {
            Image(uiImage: img).resizable().scaledToFill()
                .frame(width: 88, height: 126)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            BookSpineView(title: vm.titulo.isEmpty ? "?" : vm.titulo, id: vm.livro.id, width: 88, height: 126)
        }
    }

    private func botaoFoto(_ titulo: String) -> some View {
        Text(titulo)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Palette.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Palette.fieldInset)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.fieldBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var textFieldsCard: some View {
        VStack(spacing: 0) {
            campoTexto(rotulo: "Título *", placeholder: "Nome do livro", texto: $vm.titulo)
            Divider().background(Palette.hairline)
            campoTexto(rotulo: "Autor", placeholder: "Opcional", texto: $vm.autor)
            Divider().background(Palette.hairline)
            campoTexto(rotulo: "Editora", placeholder: "Opcional", texto: $vm.editora)
        }
        .estanteCard(cornerRadius: 22)
    }

    private func campoTexto(rotulo: String, placeholder: String, texto: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(rotulo.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Palette.textMuted)
            TextField(placeholder, text: texto)
                .font(.system(size: 16.5))
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // Segmented de status (spec 8.1/12) — troca aplica a regra de data (spec 11).
    private var statusSegmented: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STATUS")
                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundStyle(Palette.textMuted)
            HStack(spacing: 6) {
                ForEach(status_livro.allCases, id: \.self) { s in
                    let selecionado = vm.status == s
                    Text(s.displayName)
                        .font(.system(size: 13.5, weight: selecionado ? .heavy : .semibold))
                        .foregroundStyle(selecionado ? .white : corStatus(s))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selecionado ? corStatus(s) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { vm.statusMudou(para: s) } }
                }
            }
            .padding(4)
            .background(Palette.segmentTrack)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func corStatus(_ s: status_livro) -> Color {
        switch s {
        case .quero_ler: return Palette.lavender
        case .lendo: return Palette.sky
        case .lido: return Palette.mint
        }
    }

    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SUA NOTA")
                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundStyle(Palette.textMuted)
            HStack {
                StarRatingView(rating: $vm.avaliacao, interactive: true, size: 34)
                Spacer()
                Text(vm.avaliacao.map { "\($0) de 5" } ?? "Opcional")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estanteCard(cornerRadius: 22)
    }

    private var commentCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("O QUE VOCÊ ACHOU DESSE LIVRO?")
                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundStyle(Palette.textMuted)
            TextField("O que você achou desse livro?", text: $vm.comentario, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(3...8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estanteCard(cornerRadius: 22)
    }

    private var indicadoPorRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("INDICADO POR")
                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundStyle(Palette.textMuted)
            TextField("Quem te falou dele?", text: $vm.indicadoPor)
                .font(.system(size: 16))
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estanteCard(cornerRadius: 22)
    }

    // Datas: "Comecei" opcional; "Terminei" só aparece com status `lido` (spec 11).
    private var datesRow: some View {
        HStack(spacing: 12) {
            OptionalDateField(titulo: "Comecei", data: $vm.dataInicio, cor: Palette.textMuted)
            if vm.status == .lido {
                OptionalDateField(titulo: "Terminei", data: $vm.dataConclusao, cor: Palette.mint)
            }
        }
    }

    // MARK: - Ações

    // Número que o livro ocupará no ano ao ser salvo como lido (spec 8.1 — footer).
    private var numeroPreview: Int {
        let ano = Calendar.current.component(.year, from: vm.dataConclusao ?? Date())
        let period = ReadingPeriod(tipo: .anual, ano: ano, numero: nil)
        let outros = todosLivros.filter {
            $0.id != vm.livro.id && $0.status == .lido
                && ($0.data_conclusao.map { period.contains($0) } ?? false)
        }
        return outros.count + 1
    }

    // Carrega a imagem escolhida na galeria para o formulário (spec 8.1).
    private func carregarFoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                await MainActor.run { vm.novaFoto = img; vm.removerFoto = false }
            }
        }
    }

    // Salva e reage ao desfecho: Paywall, celebração de meta(s) ou fechar (spec 8.1/8.7/8.10).
    private func salvar() {
        let outcome = vm.salvar(
            context: context,
            compraDesbloqueada: store.compraDesbloqueada,
            todosLivros: todosLivros,
            todasMetas: todasMetas
        )
        switch outcome {
        case .needsPaywall:
            formSheet = .paywall
        case let .saved(livro, reached):
            livroSalvo = livro
            if reached.isEmpty {
                dismiss()
            } else {
                filaCelebracao = reached
                proximaCelebracao()
            }
        }
    }

    // Avança para a próxima meta a celebrar; quando acabam, fecha o formulário (spec 8.7).
    private func proximaCelebracao() {
        if filaCelebracao.isEmpty {
            if metaCelebrando == nil && livroSalvo != nil { dismiss() }
            return
        }
        metaCelebrando = filaCelebracao.removeFirst()
    }
}

/// Campo de data opcional reutilizável (spec 8.1). Sem data mostra "Definir";
/// com data mostra o DatePicker compacto e permite limpar.
private struct OptionalDateField: View {
    let titulo: String
    @Binding var data: Date?
    var cor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo.uppercased())
                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundStyle(cor)
            if let atual = data {
                HStack {
                    DatePicker("", selection: Binding(get: { atual }, set: { data = $0 }),
                               displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    Button {
                        data = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.textMuted)
                    }
                }
            } else {
                Button("Definir") { data = Date() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.coral)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estanteCard(cornerRadius: 20)
    }
}
