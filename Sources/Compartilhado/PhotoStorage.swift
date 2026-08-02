// PhotoStorage.swift — armazenamento local das fotos de capa (spec seção 4/20).
//
// As fotos ficam no sandbox do app, em `Application Support/Fotos/`, e nunca saem
// do aparelho (spec 20). Antes de salvar, a imagem é redimensionada para no máximo
// 1200px no lado maior e comprimida em JPEG (~0.7), para manter o tamanho dos
// dados sob controle mesmo com muitas fotos (spec 4). O registro do livro guarda
// só o nome do arquivo (`livros.foto_arquivo`, spec 7.2).

import UIKit

enum PhotoStorage {

    /// Erro de escrita da foto — tratado na UI com a mensagem da spec 12.
    enum PhotoError: Error { case failedToWrite }

    private static let maxDimension: CGFloat = 1200      // lado maior máximo (spec 4)
    private static let jpegQuality: CGFloat = 0.7        // compressão JPEG (spec 4)

    // Diretório de fotos, criado sob demanda (spec 4). Devolve a URL da pasta.
    static func fotosDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        let dir = base.appendingPathComponent(AppConstants.fotosDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// URL de um arquivo de foto a partir do nome guardado em `livros.foto_arquivo`.
    static func url(forFileName name: String) -> URL? {
        (try? fotosDirectory())?.appendingPathComponent(name)
    }

    // Salva uma imagem: redimensiona (≤1200px), comprime em JPEG (~0.7) e grava
    // com um nome novo (UUID). Devolve o nome do arquivo para guardar no livro
    // (spec 4/7.2). Lança PhotoError.failedToWrite em falha de disco (spec 12).
    static func save(_ image: UIImage) throws -> String {
        let resized = resize(image, maxDimension: maxDimension)
        guard let data = resized.jpegData(compressionQuality: jpegQuality) else {
            throw PhotoError.failedToWrite
        }
        let name = "\(UUID().uuidString).jpg"
        let dir = try fotosDirectory()
        let fileURL = dir.appendingPathComponent(name)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw PhotoError.failedToWrite
        }
        return name
    }

    /// Carrega a imagem de uma foto pelo nome do arquivo; nil se não existir.
    static func loadImage(named name: String) -> UIImage? {
        guard let fileURL = url(forFileName: name),
              let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    // Apaga o arquivo de foto ao excluir/alterar um livro (spec 8.5). Silencioso:
    // se o arquivo já não existe, não é erro.
    static func delete(named name: String) {
        guard let fileURL = url(forFileName: name) else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }

    // Redimensiona mantendo proporção para o lado maior caber em `maxDimension`
    // (spec 4). Imagens já menores não são ampliadas.
    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return image }
        let scale = maxDimension / largest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
