// BookFormViewModel.swift — estado e regras do cadastro/edição de livro (spec 8.1/8.2/8.3).
//
// Concentra os campos editáveis do formulário e a rotina de salvamento, que aplica
// as regras de negócio da spec 11 (preenchimento/limpeza de data de conclusão),
// o portão do trial (spec 8.10) e a verificação de meta batida (spec 8.7). Mantém
// a lógica fora da View para ficar testável e legível (spec 18).

import SwiftUI
import SwiftData

@MainActor
final class BookFormViewModel: ObservableObject {

    // Resultado de uma tentativa de salvar (spec 8.1/8.7/8.10).
    enum SaveOutcome {
        case needsPaywall                            // 6º livro sem compra → Paywall (8.10)
        case saved(livro: Livro, reached: [Meta])    // salvo; metas recém-batidas (8.7)
    }

    // O livro sendo editado; nil quando é um cadastro novo (spec 8.2).
    let editing: Livro?

    // Instância do livro (existente ou nova, ainda não inserida) — mantida desde o
    // início para o preview da lombada já mostrar a cor definitiva do livro (spec 16).
    let livro: Livro

    // Campos do formulário -------------------------------------------------
    @Published var titulo: String
    @Published var autor: String
    @Published var editora: String
    @Published var status: status_livro
    @Published var avaliacao: Int?
    @Published var comentario: String
    @Published var indicadoPor: String
    @Published var dataInicio: Date?
    @Published var dataConclusao: Date?

    // Foto: imagem escolhida ainda não salva, nome já salvo, e pedido de remoção.
    @Published var novaFoto: UIImage?
    @Published var fotoArquivoExistente: String?
    @Published var removerFoto = false

    /// Aviso não-bloqueante para a UI (ex.: falha ao salvar a foto — spec 12).
    @Published var aviso: String?

    // Prepara o formulário para um livro existente (edição) ou novo com um status
    // inicial pré-selecionado (spec 8.1/8.4 — "quero ler" na lista de desejos).
    init(editing livro: Livro? = nil, statusInicial: status_livro = .quero_ler) {
        self.editing = livro
        self.livro = livro ?? Livro()
        self.titulo = livro?.titulo ?? ""
        self.autor = livro?.autor ?? ""
        self.editora = livro?.editora ?? ""
        self.status = livro?.status ?? statusInicial
        self.avaliacao = livro?.avaliacao_estrelas
        self.comentario = livro?.comentario ?? ""
        self.indicadoPor = livro?.indicado_por ?? ""
        self.dataInicio = livro?.data_inicio_leitura
        self.dataConclusao = livro?.data_conclusao
        self.fotoArquivoExistente = livro?.foto_arquivo
    }

    /// Só o título é obrigatório para salvar (spec 8.1).
    var podeSalvar: Bool {
        !titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Reage à troca de status no formulário aplicando a regra da spec 11:
    // ao virar `lido` sem data de conclusão, preenche com hoje (editável em
    // seguida); ao sair de `lido`, limpa a data de conclusão.
    func statusMudou(para novo: status_livro) {
        status = novo
        if novo == .lido {
            if dataConclusao == nil { dataConclusao = Date() }
        } else {
            dataConclusao = nil
        }
    }

    // Salva o livro (cadastro ou edição), aplicando trial, regras de data e a
    // verificação de meta batida (spec 8.1/8.2/8.7/8.10/11). `todosLivros` e
    // `todasMetas` vêm do @Query da View. Devolve o desfecho para a View decidir
    // entre Paywall, celebração ou simplesmente fechar.
    func salvar(context: ModelContext,
                compraDesbloqueada: Bool,
                todosLivros: [Livro],
                todasMetas: [Meta]) -> SaveOutcome {

        // Portão do trial só vale para livro NOVO — editar nunca conta (spec 8.2/8.10).
        if editing == nil {
            let total = todosLivros.count
            if TrialGate.precisaComprar(totalLivros: total, compraDesbloqueada: compraDesbloqueada) {
                return .needsPaywall
            }
        }

        let livro = self.livro

        // Aplica os campos de texto (nil quando vazio, spec 7.2).
        livro.titulo = titulo.trimmingCharacters(in: .whitespacesAndNewlines)
        livro.autor = vazioParaNil(autor)
        livro.editora = vazioParaNil(editora)
        livro.status = status
        livro.avaliacao_estrelas = avaliacao
        livro.comentario = vazioParaNil(comentario)
        livro.indicado_por = vazioParaNil(indicadoPor)
        livro.data_inicio_leitura = dataInicio

        // Regra da data de conclusão coerente com o status final (spec 11):
        // `lido` sem data → hoje; fora de `lido` → nil.
        if status == .lido {
            livro.data_conclusao = dataConclusao ?? Date()
        } else {
            livro.data_conclusao = nil
        }

        aplicarFoto(em: livro)
        livro.atualizado_em = Date()

        if editing == nil {
            context.insert(livro)
        }
        try? context.save()

        // Verificação de meta batida só faz sentido para livro `lido` (spec 8.7).
        var reached: [Meta] = []
        if livro.status == .lido, let data = livro.data_conclusao {
            let livrosAtuais = todosLivros.contains(where: { $0.id == livro.id }) ? todosLivros : todosLivros + [livro]
            reached = GoalEvaluator.metasBatidas(aoConcluir: data, metas: todasMetas, livros: livrosAtuais)
            for meta in reached {
                meta.meta_atingida_em = Date()   // marca a 1ª vez; não regride (spec 11)
                meta.atualizado_em = Date()
            }
            if !reached.isEmpty { try? context.save() }
        }

        return .saved(livro: livro, reached: reached)
    }

    // Aplica a mudança de foto ao livro (spec 8.1). Salva a nova imagem no disco,
    // remove a antiga quando trocada/removida, e em falha de disco mantém o livro
    // sem foto com um aviso não-bloqueante (spec 12).
    private func aplicarFoto(em livro: Livro) {
        if let nova = novaFoto {
            if let antiga = livro.foto_arquivo { PhotoStorage.delete(named: antiga) }
            do {
                livro.foto_arquivo = try PhotoStorage.save(nova)
            } catch {
                livro.foto_arquivo = nil
                aviso = "Não foi possível salvar a foto agora. O livro foi salvo sem foto."
            }
        } else if removerFoto {
            if let antiga = livro.foto_arquivo { PhotoStorage.delete(named: antiga) }
            livro.foto_arquivo = nil
        }
    }

    private func vazioParaNil(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
