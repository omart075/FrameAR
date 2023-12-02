//import RealityFoundation
//
//class CustomARSystem : System {
//    required init(scene: Scene) { }
//
//    func update(context: SceneUpdateContext) {
//        let entity = context.scene.findEntity(named: Settings.shared.selectedEntityName)
//        
//        if entity != nil {
//            if case let AnchoringComponent.Target.world(transform) = entity!.anchor!.anchoring.target {
//                let distance = distance(transform.columns.3, Settings.shared.cameraTransform!.matrix.columns.3)
//                
//                if distance < 0.4 {
//                    let newEntity = entity! as! ModelEntity
//                    let material = SimpleMaterial(color: .green, isMetallic: false)
//                    newEntity.model?.materials = [material]
//                }
//             }
//        }
//    }
//}
