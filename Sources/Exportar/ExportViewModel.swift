// ExportViewModel.swift — geração do arquivo CSV de exportação (spec seção 8.9/14).
//
// Filtra os livros `lido` cuja `data_conclusao` cai no período escolhido, gera o
// CSV (formato exato da spec 14, via CSVExporter) e grava num arquivo temporário
// para a folha de compartilhamento. Período sem livros gera um CSV só com o
// cabeçalho — não é erro (spec 8.9/14).

import Foundation

enum ExportViewModel {

    // Gera o arquivo CSV do período e devolve a URL temporária para compartilhar
    // (spec 8.9). A ordenação por data crescente é feita dentro do CSVExporter.
    static func gerarArquivo(scope: ExportScope, livros: [Livro], calendar: Calendar = .current) -> URL? {
        let interval = scope.dateInterval(calendar: calendar)
        let doPeriodo = livros.filter { livro in
            guard livro.status == .lido, let d = livro.data_conclusao else { return false }
            return d >= interval.start && d < interval.end
        }
        let data = CSVExporter.makeCSV(from: doPeriodo, calendar: calendar)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(scope.fileName)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
