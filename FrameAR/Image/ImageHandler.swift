import ARKit
import RealityKit
import SwiftUI
import Combine
import UIKit
import PhotosUI

struct ImageHandler {
    
    func deleteImages() {
        let documentDirectoryPath:String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let filemanager = FileManager.default
        do {
            let files = try filemanager.contentsOfDirectory(atPath: documentDirectoryPath)
            for file in files {
                try filemanager.removeItem(atPath: "\(documentDirectoryPath)/\(file)")
            }
        } catch {
            print("Could not clear folder: \(error)")
        }
    }
    
    // save image locally for texture
    func saveImage(image: UIImage, name: String) -> URL? {
        var filePath: URL?
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let data = image.pngData() {
                filePath = documentsDirectory.appendingPathComponent("\(name).png")
            try? data.write(to: filePath!)
        }
        
        return filePath
    }
    
    // convert pixel in an image to point on screen
    func convertPixelToPoint(frame: [String: Float], imageWidth: Float, imageHeight: Float) -> [String: Float] {
        // width, height in points
        let screenScale = Float(UIScreen.main.scale)
        let screenWidth = Float(UIScreen.main.bounds.width) * screenScale
        let screenHeight = Float(UIScreen.main.bounds.height) * screenScale
        
        let xScale = screenWidth / imageWidth
        let yScale = screenHeight / imageHeight
        
        let scaledX = (frame["x"]! * xScale) / screenScale
        let scaledY = (frame["y"]! * yScale) / screenScale
        let scaledWidth = (frame["width"]! * xScale) / screenScale
        let scaledHeight = (frame["height"]! * yScale) / screenScale
        
        return [
            "x": scaledX,
            "y": scaledY,
            "width": scaledWidth,
            "height": scaledHeight
        ]
    }
}
