// BackupRestoreTests.swift — testes da sobrescrita do banco na importação (spec 14/22).

import XCTest
import SwiftData
@testable import Estante

final class BackupRestoreTests: XCTestCase {

    // A importação substitui TODO o banco: apaga livros e metas atuais e recria só
    // os livros do backup, todos como `lido` (spec 14).
    @MainActor
    func testSobrescreveTudo() throws {
        let container = try ContainerModelo.criar(emMemoria: true)
        let ctx = container.mainContext

        // Estado inicial: livros variados + uma meta.
        ctx.insert(Livro(titulo: "Antigo lendo", status: .lendo))
        ctx.insert(Livro(titulo: "Antigo lido", status: .lido, data_conclusao: Date()))
        ctx.insert(Meta(tipo_periodo: .anual, ano: 2026, numero_periodo: nil, quantidade_alvo: 20))
        try? ctx.save()

        // Importa dois livros de backup.
        let importados = [
            ImportedBook(titulo: "Backup A", autor: "Autor A", estrelas: 5,
                         comentario: nil, indicadoPor: nil, dataConclusao: Date()),
            ImportedBook(titulo: "Backup B", autor: nil, estrelas: nil,
                         comentario: nil, indicadoPor: nil, dataConclusao: nil)
        ]
        BackupRestore.sobrescrever(context: ctx, com: importados)

        let livros = try ctx.fetch(FetchDescriptor<Livro>())
        let metas = try ctx.fetch(FetchDescriptor<Meta>())

        // Sobrou só o que veio do backup; metas foram apagadas.
        XCTAssertEqual(livros.count, 2)
        XCTAssertEqual(metas.count, 0)
        XCTAssertTrue(livros.allSatisfy { $0.status == .lido })
        XCTAssertEqual(Set(livros.map(\.titulo)), ["Backup A", "Backup B"])
    }
}
