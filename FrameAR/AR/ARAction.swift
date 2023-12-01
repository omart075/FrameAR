import SwiftUI

enum ARAction {
    case addEntity(image: UIImage)
    case addEntities(images: [UIImage])
    case removeAllAnchors
    case convertImageToWorldSpace
    case deselectEntity
    case scaleEntity(scale: Double)
    case rotateEntity(angle: Double)
}
