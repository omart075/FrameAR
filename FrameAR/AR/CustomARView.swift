import ARKit
import RealityKit
import SwiftUI
import Combine
import UIKit
import PhotosUI

class CustomARView: ARView, ARSessionDelegate{
    private let imageHandler = ImageHandler()
    private var entities: [ModelEntity] = []
    
    // TODO: create custom Entity class to store these values per object
    private var entityImages: [String: URL] = [:]
    private var isTapped: Bool = false
    private var isSwitching: Bool = false
    private var selectedEntity: ModelEntity? = nil
    private var entityInfo: [String: [String: Double]] = [:]

    required init(frame frameRect: CGRect){
        super.init(frame: frameRect)
    }
    
    dynamic required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }
    
    convenience init() {
        self.init(frame: UIScreen.main.bounds)
        
        subscribeToActionStream()
    }
    
    private var cancellables: Set<AnyCancellable> = []
    private var subscriptions: Set<AnyCancellable> = []
    
    func subscribeToActionStream() {
        ARManager.shared
            .actionStream
            .sink { [weak self] action in
                switch action {
                    case .addEntity(let image):
                        // center of screen measured in points not pixels
                        let screenPoints = (UIScreen.main.bounds.width / 2, UIScreen.main.bounds.height / 2)
                        let pinLocation: CGPoint = CGPoint(x: screenPoints.0, y: screenPoints.1)
                        self?.addEntity(image: image, pinLocation: pinLocation)
                    case .addEntities(let images):
                        self?.addEntities(images: images)
                    case .removeAllAnchors:
                        self?.scene.anchors.removeAll()
                    case .convertImageToWorldSpace:
                        self?.convertImageToWorldSpace()
                    case .deselectEntity:
                        self?.deselectEntity()
                    case .scaleEntity(let scale):
                        self?.scaleEntity(scale: scale)
                    case .rotateEntity(let angle):
                        self?.rotateEntity(angle: angle)
                    case .hangFrames:
                        self?.hangFrames()
                }
            }
            .store(in: &cancellables)
    }
    
    func configuration () {
        let config = ARWorldTrackingConfiguration()
        session.run(config)
    }
    
    func addEntity(image: UIImage, pinLocation: CGPoint) {
        let results = raycast(from: pinLocation, allowing: .estimatedPlane, alignment: .vertical)
        
        if let firstResult = results.first {
            let (width, height) = pixelsToMeters(x: Float(image.size.width * image.scale), y: Float(image.size.height * image.scale))
            
            let filePath = imageHandler.saveImage(image: image, name: UUID().uuidString)
            if filePath != nil{
                anchorEntity(entity: createPlane(filePath: filePath!, width: width, height: height), worldPos: firstResult)
            }
        }
        else { return }
    }
    
    func addEntities(images: [UIImage]) {
        var scaledFrames: [[String: Float]] = []
        let imageWidth = Float(1072.0)
        let imageHeight = Float(1072.0)
        let frames: [[String: Float]] = [
            [
                "x": 220.0,
                "y": 260.0,
                "width": 120.0,
                "height": 140.0
            ],
            [
                "x": 480.0,
                "y": 130.0,
                "width": 150.0,
                "height": 200.0
            ],
            [
                "x": 480.0,
                "y": 350.0,
                "width": 150.0,
                "height": 200.0
            ],
            [
                "x": 780.0,
                "y": 250.0,
                "width": 120.0,
                "height": 140.0
            ]
        ]
        
        for (n, image) in images.enumerated() {
            let screenPoints: [String: Float] = ImageHandler().convertPixelToPoint(frame: frames[n], imageWidth: imageWidth, imageHeight: imageHeight)
            scaledFrames.append(screenPoints)
            
            // pin frame based on its center
            let pinLocation: CGPoint = CGPoint(x: Double(screenPoints["x"]! + (screenPoints["width"]!/2)), y: Double(screenPoints["y"]! + (screenPoints["height"]!/2)))
            addEntity(image: image, pinLocation: pinLocation)
        }
    }
    
    // creat world anchor and add 3d object to anchor
    func anchorEntity(entity: ModelEntity, worldPos: ARRaycastResult){
        let coordinateAnchor = AnchorEntity(raycastResult: worldPos)
        
        coordinateAnchor.addChild(entity)
        scene.addAnchor(coordinateAnchor)
    }
        
    func createPlane(filePath: URL, width: Float, height: Float) -> ModelEntity {
        let mesh = MeshResource.generatePlane(width: width, depth: height)
        let texture = try? TextureResource.load(contentsOf: filePath)
        var material = SimpleMaterial()
        
        if texture != nil {
            material.color = .init(tint: .white, texture: .init(texture!))
        }
        else{
            material.color = .init(tint: .black)
        }
        material.roughness = .float(0.0)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        entity.generateCollisionShapes(recursive: true)
        entity.name = UUID().uuidString
        
        installGestures(.translation, for: entity)
        
        entities.append(entity)
        entityImages[entity.name] = filePath
        
        return entity
    }
    
    // convert pixels to meters
    // meters = (pixels * (cm in an inch / ppi))/100
    // where pixels = points * scale
    func pixelsToMeters(x: Float, y: Float) -> (Float, Float){
        let dpi = 300.0// dpi used to print photos
        let cm = 2.54 // in -> cm
        
        let xInMeters = (x * Float(cm/dpi)) / 100
        let yInMeters = (y * Float(cm/dpi)) / 100
        
        return (xInMeters, yInMeters)
    }
    
    func deselectEntity() {
        let entity = scene.findEntity(named: Settings.shared.selectedEntityName)
        if entity != nil {
            Settings.shared.showEntityModal = false
            isTapped = false

            entityInfo[selectedEntity!.name]!["newTranslateY"] = entityInfo[selectedEntity!.name]!["origTranslateY"]
            // if entity was translated while selected
            entityInfo[selectedEntity!.name]!["newTranslateX"] = Double(entity!.position.x)
            entityInfo[selectedEntity!.name]!["newTranslateZ"] = Double(entity!.position.z)
            
            selectedEntity!.move(to: Transform(scale: .init(x: Float(entityInfo[selectedEntity!.name]!["newScaleX"]!),
                                                            y: Float(entityInfo[selectedEntity!.name]!["newScaleY"]!),
                                                            z: Float(entityInfo[selectedEntity!.name]!["newScaleZ"]!)),
                                               rotation: simd_quatf(angle: Float(entityInfo[selectedEntity!.name]!["newAngle"]!),
                                                                    axis: [0,1,0]),
                                               translation: .init(x: Float(entityInfo[selectedEntity!.name]!["newTranslateX"]!),
                                                                  y: Float(entityInfo[selectedEntity!.name]!["newTranslateY"]!),
                                                                  z: Float(entityInfo[selectedEntity!.name]!["newTranslateZ"]!))),
                                 relativeTo: selectedEntity!.parent,
                                 duration: 0.5,
                                 timingFunction: .easeInOut)
        }
    }
    
    func scaleEntity(scale: Double) {
        if !isSwitching && selectedEntity != nil {
            // calculate new scaled values
            let x = entityInfo[selectedEntity!.name]!["origScaleX"]! * scale
            let y = entityInfo[selectedEntity!.name]!["origScaleY"]! * scale
            let z = entityInfo[selectedEntity!.name]!["origScaleZ"]! * scale
            
            // TODO: apply scale temporarily?
            selectedEntity!.scale.x = Float(x)
            selectedEntity!.scale.y = Float(y)
            selectedEntity!.scale.z = Float(z)
            
            // save new values
            entityInfo[selectedEntity!.name]!["scale"] = scale
            entityInfo[selectedEntity!.name]!["newScaleX"] = x
            entityInfo[selectedEntity!.name]!["newScaleY"] = y
            entityInfo[selectedEntity!.name]!["newScaleZ"] = z
        }
    }
    
    func rotateEntity(angle: Double) {
        if !isSwitching && selectedEntity != nil {
            // convert degrees to radians, multiply by -1 to flip direction (more user friendly)
            let newAngle = (-1 * angle * .pi) / 180
            
            // TODO: apply rotation temporarily?
            selectedEntity!.orientation = simd_quatf(angle: Float(newAngle), axis: SIMD3<Float>(0,1,0))
            
            entityInfo[selectedEntity!.name]!["newAngle"] = newAngle
        }
    }
    
    func hangFrames() {
        var material = SimpleMaterial()
        
        if Settings.shared.isHanging {
            entities.forEach { entity in
                let texture = try? TextureResource.load(contentsOf: entityImages[entity.name]!)
                material.color = .init(tint: .white.withAlphaComponent(0.5), texture: .init(texture!))
                
                entity.model?.materials = [material]
            }
        }
        else {
            entities.forEach { entity in
                let texture = try? TextureResource.load(contentsOf: entityImages[entity.name]!)
                material.color = .init(tint: .white, texture: .init(texture!))
                
                entity.model?.materials = [material]
            }
        }
    }
    
    // TODO: might be useful later
    // create points of a picture frame from an image in 3d world space
    func convertImageToWorldSpace() {
        let imageWidth = Float(1072.0)
        let imageHeight = Float(1072.0)
        let frames: [[String: Float]] = [
            [
                "x": 220.0,
                "y": 260.0,
                "width": 120.0,
                "height": 140.0
            ],
            [
                "x": 480.0,
                "y": 130.0,
                "width": 150.0,
                "height": 200.0
            ],
            [
                "x": 480.0,
                "y": 350.0,
                "width": 150.0,
                "height": 200.0
            ],
            [
                "x": 780.0,
                "y": 250.0,
                "width": 120.0,
                "height": 140.0
            ]
        ]
        var scaledFrames: [[String: Float]] = []
        
        frames.forEach { frame in
            // measured in points not pixels
            let screenPoints: [String: Float] = ImageHandler().convertPixelToPoint(frame: frame, imageWidth: imageWidth, imageHeight: imageHeight)
            scaledFrames.append(screenPoints)
            
            let pinLocationTL: CGPoint = CGPoint(x: Double(screenPoints["x"]!), y: Double(screenPoints["y"]!))
            var results = raycast(from: pinLocationTL, allowing: .estimatedPlane, alignment: .vertical)
            createPoint(results: results)
            
            let pinLocationTR: CGPoint = CGPoint(x: Double(screenPoints["x"]! + screenPoints["width"]!), y: Double(screenPoints["y"]!))
            results = raycast(from: pinLocationTR, allowing: .estimatedPlane, alignment: .vertical)
            createPoint(results: results)
            
            let pinLocationBL: CGPoint = CGPoint(x: Double(screenPoints["x"]!), y: Double(screenPoints["y"]! + screenPoints["height"]!))
            results = raycast(from: pinLocationBL, allowing: .estimatedPlane, alignment: .vertical)
            createPoint(results: results)
            
            let pinLocationBR: CGPoint = CGPoint(x: Double(screenPoints["x"]! + screenPoints["width"]!), y: Double(screenPoints["y"]! + screenPoints["height"]!))
            results = raycast(from: pinLocationBR, allowing: .estimatedPlane, alignment: .vertical)
            createPoint(results: results)
            
        }
    }
    
    // TODO: might be useful later
    func createPoint(results: [ARRaycastResult]) {
        if let firstResult = results.first {
            let worldPos = simd_make_float3(firstResult.worldTransform.columns.3)
            let sphere = MeshResource.generateSphere(radius: 0.01)
            let material = SimpleMaterial(color: .blue, roughness: 0, isMetallic: true)
            let entity = ModelEntity(mesh: sphere, materials: [material])
            let anchorEntity = AnchorEntity(world: worldPos)
            
            anchorEntity.addChild(entity)
            scene.addAnchor(anchorEntity)
        }
    }
}

extension CustomARView {
    func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        // location of tap on screen
        guard let touchInView = sender?.location(in: self) else { return }
        // entity tapped on screen
        let hitEntity = self.entity(at: touchInView) as? ModelEntity
          
        if hitEntity != nil {
            // get/set entity information
            if !entityInfo.contains(where: { $0.key == hitEntity!.name}) {
                entityInfo[hitEntity!.name] = [
                    "origTranslateX": Double(hitEntity!.position.x),
                    "origTranslateY": Double(hitEntity!.position.y),
                    "origTranslateZ": Double(hitEntity!.position.z),
                    "newTranslateX": Double(hitEntity!.position.x),
                    "newTranslateY": Double(hitEntity!.position.y),
                    "newTranslateZ": Double(hitEntity!.position.z),
                    "origScaleX": Double(hitEntity!.scale.x),
                    "origScaleY": Double(hitEntity!.scale.y),
                    "origScaleZ": Double(hitEntity!.scale.z),
                    "newScaleX": Double(hitEntity!.scale.x),
                    "newScaleY": Double(hitEntity!.scale.y),
                    "newScaleZ": Double(hitEntity!.scale.z),
                    "scale": Double(1.0),
                    "origAngle": Double(hitEntity!.orientation.angle),
                    "newAngle": Double(hitEntity!.orientation.angle)
                ]
            }
            
//            Settings.shared.cameraTransform = self.cameraTransform
            Settings.shared.selectedEntityName = hitEntity!.name
            Settings.shared.showEntityModal = true
            
            if isTapped {
                // if tapping the same entity that's already selected
                if hitEntity!.id == selectedEntity!.id {
                    Settings.shared.showEntityModal = false
                    isTapped = false
                    
                    entityInfo[selectedEntity!.name]!["newTranslateY"] = entityInfo[selectedEntity!.name]!["origTranslateY"]
                    // if entity was translated while selected
                    entityInfo[selectedEntity!.name]!["newTranslateX"] = Double(selectedEntity!.position.x)
                    entityInfo[selectedEntity!.name]!["newTranslateZ"] = Double(selectedEntity!.position.z)
                }
                else {
                    // if tapping on new entity, reset selected entity
                    entityInfo[selectedEntity!.name]!["newTranslateY"] = entityInfo[selectedEntity!.name]!["origTranslateY"]
                    // if entity was translated while selected
                    entityInfo[selectedEntity!.name]!["newTranslateX"] = Double(selectedEntity!.position.x)
                    entityInfo[selectedEntity!.name]!["newTranslateZ"] = Double(selectedEntity!.position.z)
                    
                    selectedEntity!.move(to: Transform(scale: .init(x: Float(entityInfo[selectedEntity!.name]!["newScaleX"]!),
                                                                    y: Float(entityInfo[selectedEntity!.name]!["newScaleY"]!),
                                                                    z: Float(entityInfo[selectedEntity!.name]!["newScaleZ"]!)),
                                                       rotation: simd_quatf(angle: Float(entityInfo[selectedEntity!.name]!["newAngle"]!),
                                                                            axis: [0,1,0]),
                                                       translation: .init(x: Float(entityInfo[selectedEntity!.name]!["newTranslateX"]!),
                                                                          y: Float(entityInfo[selectedEntity!.name]!["newTranslateY"]!),
                                                                          z: Float(entityInfo[selectedEntity!.name]!["newTranslateZ"]!))),
                                         relativeTo: selectedEntity!.parent,
                                         duration: 0.5,
                                         timingFunction: .easeInOut)
                    
                    isSwitching = true
                      
                    // reset vars for new entity
                    selectedEntity = hitEntity
                    entityInfo[selectedEntity!.name]!["newTranslateX"] = Double(hitEntity!.position.x)
//                    entityInfo[selectedEntity!.name]!["newTranslateY"] = entityInfo[selectedEntity!.name]!["origTranslateY"]! + 0.2
                    entityInfo[selectedEntity!.name]!["newTranslateY"] = Double(hitEntity!.position.y + 0.2)
                    entityInfo[selectedEntity!.name]!["newTranslateZ"] = Double(hitEntity!.position.z)
                    
                    Settings.shared.scale = entityInfo[selectedEntity!.name]!["scale"]!
                    // convert radians back to degrees for slider
                    Settings.shared.angle = (-1 * entityInfo[selectedEntity!.name]!["newAngle"]! * 180) / .pi
                }
            }
            else {
                // tapping an entity when no other entity is selected
                // reset vars for new entity
                selectedEntity = hitEntity
                isTapped = true

                entityInfo[selectedEntity!.name]!["newTranslateX"] = Double(hitEntity!.position.x)
                entityInfo[selectedEntity!.name]!["newTranslateY"] = Double(hitEntity!.position.y + 0.2)
                entityInfo[selectedEntity!.name]!["newTranslateZ"] = Double(hitEntity!.position.z)
                
                Settings.shared.scale = entityInfo[selectedEntity!.name]!["scale"]!
                // convert radians back to degrees for slider
                Settings.shared.angle = (-1 * entityInfo[selectedEntity!.name]!["newAngle"]! * 180) / .pi
            }
            
            // scale, rotate, and translate
            let animation = selectedEntity!.move(to: Transform(scale: .init(x: Float(entityInfo[selectedEntity!.name]!["newScaleX"]!),
                                                                            y: Float(entityInfo[selectedEntity!.name]!["newScaleY"]!),
                                                                            z: Float(entityInfo[selectedEntity!.name]!["newScaleZ"]!)),
                                                               rotation: simd_quatf(angle: Float(entityInfo[selectedEntity!.name]!["newAngle"]!),
                                                                                    axis: [0,1,0]),
                                                               translation: .init(x: Float(entityInfo[selectedEntity!.name]!["newTranslateX"]!),
                                                                                  y: Float(entityInfo[selectedEntity!.name]!["newTranslateY"]!),
                                                                                  z: Float(entityInfo[selectedEntity!.name]!["newTranslateZ"]!))),
                                 relativeTo: selectedEntity!.parent,
                                 duration: 0.5,
                                 timingFunction: .easeInOut)
            
            // change switching flag once animation is complete to skip scaling when not necessary
            scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
                   .filter { $0.playbackController == animation }
                   .sink(receiveValue: { event in
                       self.isSwitching = false
                    }).store(in: &subscriptions)
        }
        else {
            // tapping on empty space on the screen and there is a selected entity
            if selectedEntity != nil {
                // if entity was translated while selected
                entityInfo[selectedEntity!.name]!["newTranslateX"] = Double(selectedEntity!.position.x)
                entityInfo[selectedEntity!.name]!["newTranslateZ"] = Double(selectedEntity!.position.z)
                
                // scale and translate
                selectedEntity!.move(to: Transform(scale: .init(x: Float(entityInfo[selectedEntity!.name]!["newScaleX"]!),
                                                                y: Float(entityInfo[selectedEntity!.name]!["newScaleY"]!),
                                                                z: Float(entityInfo[selectedEntity!.name]!["newScaleZ"]!)),
                                                   rotation: simd_quatf(angle: Float(entityInfo[selectedEntity!.name]!["newAngle"]!),
                                                                        axis: [0,1,0]),
                                                   translation: .init(x: Float(entityInfo[selectedEntity!.name]!["newTranslateX"]!),
                                                                      y: Float(entityInfo[selectedEntity!.name]!["origTranslateY"]!),
                                                                      z: Float(entityInfo[selectedEntity!.name]!["newTranslateZ"]!))),
                                     relativeTo: selectedEntity!.parent,
                                     duration: 0.5,
                                     timingFunction: .easeInOut)
                
                Settings.shared.showEntityModal = false
                isTapped = false
            }
            else { return }
        }
    }
}
