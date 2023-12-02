import SwiftUI
import FocusEntity

//extend UIViewRepresentable so that it can be used in SwiftUI View body
struct CustomARViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> CustomARView {
//        CustomARSystem.registerSystem()
        
        let arView = CustomARView()
        _ = FocusEntity(on: arView, focus: .classic)
        
        arView.setupGestures()
        arView.session.delegate = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: CustomARView, context: Context) { }
}
