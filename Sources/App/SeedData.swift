// SeedData.swift — dados de exemplo para teste manual (spec seção 18/22).
//
// SÓ EM DEBUG. Popula a estante com livros e metas de exemplo para validar
// visualmente o feed, o Top 3, os indicadores, as metas e o cartão com volume de
// dados (spec 18). Não faz parte do build de release e nunca roda em produção.

#if DEBUG
import Foundation
import SwiftData

enum SeedData {

    // Insere livros e metas de exemplo no contexto (spec 18). Datas em 2026 para
    // casar com o "hoje" de teste (agosto/2026).
    static func popular(context: ModelContext) {
        func data(_ ano: Int, _ mes: Int, _ dia: Int) -> Date {
            Calendar.current.date(from: DateComponents(year: ano, month: mes, day: dia)) ?? Date()
        }

        // Livros LIDOS espalhados por 2026 (indicadores/Top 3/feed) --------------
        let lidos: [(String, String, Int?, Date)] = [
            ("A Hora da Estrela", "Clarice Lispector", 5, data(2026, 6, 9)),
            ("Cem Anos de Solidão", "Gabriel García Márquez", 5, data(2026, 6, 30)),
            ("O Avesso da Pele", "Jeferson Tenório", 4, data(2026, 7, 28)),
            ("Klara e o Sol", "Kazuo Ishiguro", 4, data(2026, 7, 14)),
            ("Pachinko", "Min Jin Lee", 5, data(2026, 5, 20)),
            ("Vidas Secas", "Graciliano Ramos", 4, data(2026, 4, 11)),
            ("A Metamorfose", "Franz Kafka", 3, data(2026, 3, 8)),
            ("O Conto da Aia", "Margaret Atwood", 5, data(2026, 2, 2)),
            ("Torto Arado", "Itamar Vieira Junior", 5, data(2026, 8, 1)),
            ("Quarto de Despejo", "Carolina Maria de Jesus", nil, data(2026, 8, 5)),
            ("Sejamos Todos Feministas", "Chimamanda Adichie", 4, data(2026, 8, 12))
        ]
        for (titulo, autor, estrelas, fim) in lidos {
            let livro = Livro(titulo: titulo, autor: autor, status: .lido,
                              avaliacao_estrelas: estrelas,
                              data_inicio_leitura: Calendar.current.date(byAdding: .day, value: -9, to: fim),
                              data_conclusao: fim)
            context.insert(livro)
        }

        // Livros LENDO (destaque na Home) ----------------------------------------
        for (titulo, autor) in [("Grande Sertão: Veredas", "Guimarães Rosa"), ("Middlemarch", "George Eliot")] {
            context.insert(Livro(titulo: titulo, autor: autor, status: .lendo,
                                 data_inicio_leitura: data(2026, 8, 10)))
        }

        // Livros QUERO LER (com indicação) ---------------------------------------
        context.insert(Livro(titulo: "O Som e a Fúria", autor: "William Faulkner",
                             status: .quero_ler, indicado_por: "Marina"))
        context.insert(Livro(titulo: "Beloved", autor: "Toni Morrison",
                             status: .quero_ler, indicado_por: "Rafael"))

        // METAS (uma mensal já batida, para mostrar o selo) ----------------------
        let mensal = Meta(tipo_periodo: .mensal, ano: 2026, numero_periodo: 8, quantidade_alvo: 3)
        mensal.meta_atingida_em = Date()
        context.insert(mensal)
        context.insert(Meta(tipo_periodo: .trimestral, ano: 2026, numero_periodo: 3, quantidade_alvo: 9))
        context.insert(Meta(tipo_periodo: .semestral, ano: 2026, numero_periodo: 2, quantidade_alvo: 18))
        context.insert(Meta(tipo_periodo: .anual, ano: 2026, numero_periodo: nil, quantidade_alvo: 33))

        try? context.save()
    }

    // Apaga todos os livros e metas (limpar entre testes).
    static func limpar(context: ModelContext) {
        try? context.delete(model: Livro.self)
        try? context.delete(model: Meta.self)
        try? context.save()
    }
}
#endif
