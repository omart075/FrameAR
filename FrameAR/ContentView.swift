import SwiftUI
import UIKit
import PhotosUI

struct ContentView: View {
    @State private var showingImagePicker: Bool = false
    @State private var pickingSingleImage: Bool = false
    
    @State private var showModal: Bool = false
    
    @ObservedObject var settings = Settings.shared
    
    private let imageHandler = ImageHandler()
    
    var body: some View {
        CustomARViewRepresentable()
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                ZStack{
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack {
                                Button {
                                    ARManager.shared.actionStream.send(.removeAllAnchors)
                                    imageHandler.deleteImages()
                                } label: {
                                    Image(systemName: "trash")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .padding()
                                        .buttonStyle(PlainButtonStyle())
                                        .cornerRadius(16)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 40, height: 40)
                                .padding(.bottom, 5)
                                
                                Button {
                                    showModal = true
                                } label: {
                                    Image(systemName: "square.grid.2x2")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .padding()
                                        .buttonStyle(PlainButtonStyle())
                                        .cornerRadius(16)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 40, height: 40)
                                .padding(.bottom, 5)
                                
                                Button {
                                    
                                } label: {
                                    Image(systemName: "compass.drawing")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .padding()
                                        .buttonStyle(PlainButtonStyle())
                                        .cornerRadius(16)
                                        .foregroundColor(.white)
                                }
                            }
                            .background(Color.black.opacity(0.20))
                            .cornerRadius(40/2)
                            .padding()
                        }
                        Spacer()
                        HStack {
                            ExpandableButtonPanel(
                                primaryButton: ExpandableButton(label: Image(systemName: "plus")),
                                secondaryButtons: [
                                    ExpandableButton(label: Image(systemName: "photo")) {
                                        showingImagePicker = true
                                        pickingSingleImage = true
                                    },
                                    ExpandableButton(label: Image(systemName: "photo.on.rectangle.angled")) {
                                        showingImagePicker = true
                                    }
                                ]
                            )
                            .padding()
                            .sheet(
                                isPresented: $showingImagePicker,
                                content: {
                                    ImagePicker(pickingSingleImage: $pickingSingleImage)
                                        .ignoresSafeArea()
                                }
                            )
                        }
                    }
                    
                    // TODO: modal not showing if entity modal is showing
                    ModalView(isShowing: $showModal)
                    EntityModalView(isShowing: $settings.showEntityModal, settings: settings)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .statusBarHidden(true)
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// TODO: move to separate file
struct ExpandableButton: Identifiable {
    let id = UUID()
    let label: Image
    var action: (() -> Void)? = nil
}

struct ExpandableButtonPanel: View {
    let primaryButton: ExpandableButton
    let secondaryButtons: [ExpandableButton]
    
    private let size: CGFloat = 65
    private var cornerRadius: CGFloat {
        get { size / 2 }
    }
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack {
            if isExpanded {
                ForEach(secondaryButtons) { button in
                    Button {
                        button.action?()
                        withAnimation { self.isExpanded.toggle() }
                    } label: {
                        button.label.foregroundColor(.white)
                    }
                    .frame(width: self.size, height: self.size)
                }
            }
            Button {
                withAnimation(.bouncy) { self.isExpanded.toggle() }
                self.primaryButton.action?()
            } label: {
                if isExpanded {
                    Image(systemName: "xmark").foregroundColor(.white)
                }
                else {
                    self.primaryButton.label.foregroundColor(.white)
                }
            }
            .frame(width: self.size, height: self.size)
        }
        .background(Color.black.opacity(0.20))
        .cornerRadius(cornerRadius)
    }
}

struct HExpandableButtonPanel: View {
    let primaryButton: ExpandableButton
    let secondaryButtons: [ExpandableButton]
    
    private let size: CGFloat = 80
    private var cornerRadius: CGFloat {
        get { size / 2 }
    }
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        HStack {
            if isExpanded {
                ForEach(secondaryButtons) { button in
                    Button {
                        button.action?()
                        withAnimation { self.isExpanded.toggle() }
                    } label: {
                        button.label
                    }
                    .frame(width: self.size, height: self.size)
                }
            }
            Button {
                withAnimation(.bouncy) { self.isExpanded.toggle() }
                self.primaryButton.action?()
            } label: {
                self.primaryButton.label
            }
            .frame(width: self.size, height: self.size)
        }
        .background(Color.gray.opacity(0.75))
        .cornerRadius(cornerRadius)
    }
}
