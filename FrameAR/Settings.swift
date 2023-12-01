import Foundation
import Combine

class Settings: ObservableObject {
    static let shared = Settings()

    @Published var showEntityModal = false
    @Published var selectedEntityName = ""
    @Published var scale: Double = 1.0
    @Published var angle: Double = 0.0
}
