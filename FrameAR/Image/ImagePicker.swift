import PhotosUI
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var pickingSingleImage: Bool
    
    var itemProviders: [NSItemProvider] = []
    var images: [UIImage] = []
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        
        if pickingSingleImage {
            config.selectionLimit = 1
        }
        else {
            config.selectionLimit = 0
        }
        
        let imagePicker = PHPickerViewController(configuration: config)
        imagePicker.delegate = context.coordinator
        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        // reference to ph picker
        init(_ picker: ImagePicker) {
            self.parent = picker
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            if !results.isEmpty {
                parent.itemProviders = []
            }
            parent.itemProviders = results.map(\.itemProvider)
            
            for (n, itemProvider) in parent.itemProviders.enumerated() {
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            self.parent.images.append(image)
                            
                            if n == self.parent.itemProviders.count - 1 {
                                DispatchQueue.main.async {
                                    if self.parent.pickingSingleImage {
                                        ARManager.shared.actionStream.send(.addEntity(image: self.parent.images.first!))
                                    }
                                    else{
                                        ARManager.shared.actionStream.send(.addEntities(images: self.parent.images))
                                    }
                                    self.parent.pickingSingleImage = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
