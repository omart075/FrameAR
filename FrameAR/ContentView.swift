import SwiftUI
import UIKit
import PhotosUI

struct ContentView: View {
    @State private var showingImagePicker: Bool = false
    @State private var pickingSingleImage: Bool = false
    
    @State private var showModal: Bool = false
    
    @State private var textSwitch = true
    
    @ObservedObject var settings = Settings.shared
    
    private let imageHandler = ImageHandler()
    
    var body: some View {
        CustomARViewRepresentable()
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                if !Settings.shared.isHanging {
                    ZStack{
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack {
                                    HStack {
                                        VStack {
                                            Text((textSwitch ? "Delete" : ""))
                                                .padding(.bottom, 40)
                                                .font(.system(size: 14, design: .rounded).weight(.bold))
                                                .shadow(color: .black, radius: 2.0)
                                            Text((textSwitch ? "Hang" : ""))
                                                .font(.system(size: 14, design: .rounded).weight(.bold))
                                                .shadow(color: .black, radius: 2.0)
                                        }
                                        // buttons that affect 3d entities directly
                                        VStack{
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
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.bottom, 5)
                                            
                                            Button {
                                                withAnimation {
                                                    Settings.shared.isHanging.toggle()
                                                }
                                                ARManager.shared.actionStream.send(.hangFrames)
                                            } label: {
                                                Image(systemName: "hammer")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20)
                                                    .padding()
                                                    .buttonStyle(PlainButtonStyle())
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .background(Color.black.opacity(0.20))
                                        .frame(width: 40)
                                        .cornerRadius(60)
                                        .padding(.trailing)
                                    }
                                    .padding(.bottom)
                                    
                                    HStack {
                                        VStack {
                                            Text((textSwitch ? "Design" : ""))
                                                .padding(.bottom, 40)
                                                .font(.system(size: 14, design: .rounded).weight(.bold))
                                                .shadow(color: .black, radius: 2.0)
                                            Text((textSwitch ? "Mural" : ""))
                                                .font(.system(size: 14, design: .rounded).weight(.bold))
                                                .shadow(color: .black, radius: 2.0)
                                        }
                                        // buttons that affect layouts
                                        VStack {
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
                                        .frame(width: 40)
                                        .cornerRadius(60)
                                        .padding(.trailing)
                                    }
                                }
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                        if self.textSwitch {
                                            withAnimation {
                                                self.textSwitch.toggle()
                                            }
                                        }
                                    }
                                }
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
                else {
                    HangingView()
                }
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

struct HangingView: View {
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    VStack {
                        Button {
                            withAnimation {
                                Settings.shared.isHanging.toggle()
                            }
                            ARManager.shared.actionStream.send(.hangFrames)
                        } label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .padding()
                                .buttonStyle(PlainButtonStyle())
                                .cornerRadius(16)
                                .foregroundColor(.white)
                        }
                        .frame(width: 65, height: 65)
                    }
                    .background(Color.black.opacity(0.20))
                    .cornerRadius(65/2)
                    .padding()
                }
            }
        }
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
