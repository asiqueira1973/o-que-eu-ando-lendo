// BackupRestore.swift — restauração de backup por CSV (spec seção 14).
//
// Caso de uso: a pessoa exportou o CSV, reinstalou o app e quer restaurar. A
// importação **sobrescreve todo o banco** (spec 14): apaga os livros e as metas
// atuais (e as fotos órfãs no disco) e recria os livros a partir do arquivo, todos
// com status `lido` (a exportação só contém lidos). Ação destrutiva — a UI pede
// confirmação explícita (spec 12/8.9).

import Foundation
import SwiftData

enum BackupRestore {

    // Lê o CSV e sobrescreve o banco (spec 14). Devolve quantos livros foram
    // importados, para a UI confirmar o resultado.
    @discardableResult
    static func restaurar(context: ModelContext, de data: Data) -> Int {
        let importados = CSVImporter.parse(data)
        sobrescrever(context: context, com: importados)
        return importados.count
    }

    // Substitui todo o conteúdo do banco pelos livros importados (spec 14).
    static func sobrescrever(context: ModelContext, com importados: [ImportedBook]) {
        // Apaga as fotos dos livros atuais para não deixar arquivos órfãos no disco.
        if let existentes = try? context.fetch(FetchDescriptor<Livro>()) {
            for livro in existentes {
                if let nome = livro.foto_arquivo { PhotoStorage.delete(named: nome) }
            }
        }
        // Limpa livros e metas (sobrescrita total, spec 14).
        try? context.delete(model: Livro.self)
        try? context.delete(model: Meta.self)

        // Recria os livros do backup, todos como `lido` (spec 14).
        for b in importados {
            let livro = Livro(
                titulo: b.titulo,
                autor: b.autor,
                status: .lido,
                avaliacao_estrelas: b.estrelas,
                comentario: b.comentario,
                indicado_por: b.indicadoPor,
                data_conclusao: b.dataConclusao
            )
            context.insert(livro)
        }
        try? context.save()
    }
}
