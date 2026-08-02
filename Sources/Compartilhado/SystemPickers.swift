// SystemPickers.swift — pontes para APIs nativas de UIKit usadas em SwiftUI.
//
// Reúne os wrappers de câmera e da folha de compartilhamento, ambos com API 100%
// nativa da Apple (spec 4): `UIImagePickerController` para tirar foto na hora
// (spec 8.1) e `UIActivityViewController` para a folha de compartilhamento usada
// na exportação CSV (8.9) e no cartão (8.11) — o app nunca decide sozinho o
// destino do arquivo/imagem (spec 8.9/8.11/20).

import SwiftUI
import UIKit

/// Câmera nativa para tirar a foto da capa na hora (spec 4/8.1). A escolha da
/// galeria usa `PhotosPicker` (SwiftUI) direto na tela de cadastro.
struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Folha de compartilhamento nativa do iOS (spec 8.9/8.11). Recebe os itens a
/// compartilhar (URL do CSV ou UIImage do cartão).
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
