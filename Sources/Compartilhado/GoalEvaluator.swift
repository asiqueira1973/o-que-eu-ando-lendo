// GoalEvaluator.swift — verificação de "meta batida" (spec seção 8.7/11).
//
// Lógica pura e testável (spec 22). Ao salvar um livro como `lido`, decide quais
// metas foram atingidas PELA PRIMEIRA VEZ. Regras da spec 11:
//   - só conta meta com `meta_atingida_em` ainda nulo (não repete nem regride);
//   - o livro salvo precisa ter `data_conclusao` dentro do período da meta;
//   - a contagem de livros `lido` no período precisa alcançar/ultrapassar o alvo.
// A edição retroativa de um livro para um período cuja meta JÁ estava batida não
// dispara de novo — garantido pelo filtro de `meta_atingida_em == nil` (spec 8.7).

import Foundation

enum GoalEvaluator {

    // Avalia, depois de o livro ter sido salvo como `lido`, quais metas foram
    // batidas pela primeira vez (spec 8.7/11). `dataConclusao` é a data do livro
    // recém-salvo; `livros` é o estado atual completo (já incluindo o salvo);
    // `metas` são todas as metas. Devolve as metas recém-batidas, na ordem em que
    // devem ser celebradas (spec 8.7 — uma mensagem por meta, em sequência).
    static func metasBatidas(aoConcluir dataConclusao: Date,
                             metas: [Meta],
                             livros: [Livro],
                             calendar: Calendar = .current) -> [Meta] {
        metas.filter { meta in
            guard meta.meta_atingida_em == nil else { return false }
            let period = ReadingPeriod(tipo: meta.tipo_periodo, ano: meta.ano, numero: meta.numero_periodo)
            guard period.contains(dataConclusao, calendar: calendar) else { return false }
            let count = PeriodCalculator.countLidos(livros, in: period, calendar: calendar)
            return count >= meta.quantidade_alvo
        }
        // Ordena por granularidade (mensal → anual) só para uma sequência de
        // celebração previsível quando um livro bate várias metas de uma vez.
        .sorted { ordem($0.tipo_periodo) < ordem($1.tipo_periodo) }
    }

    // Progresso atual de uma meta: contagem de livros `lido` no período (spec 8.6).
    static func progresso(da meta: Meta, livros: [Livro], calendar: Calendar = .current) -> Int {
        let period = ReadingPeriod(tipo: meta.tipo_periodo, ano: meta.ano, numero: meta.numero_periodo)
        return PeriodCalculator.countLidos(livros, in: period, calendar: calendar)
    }

    private static func ordem(_ tipo: tipo_periodo_meta) -> Int {
        switch tipo {
        case .mensal: return 0
        case .trimestral: return 1
        case .semestral: return 2
        case .anual: return 3
        }
    }
}
