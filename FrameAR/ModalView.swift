import SwiftUI

struct ModalView: View {
    @Binding var isShowing: Bool
    
    @State private var curHeight: CGFloat = 200
    @State private var prevDragTranslation = CGSize.zero
    @State private var opacity: Double = 1.0
    
    private let threshold: CGFloat = 200
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isShowing {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        isShowing = false
                    }
                mainView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
        .animation(.easeInOut, value: isShowing)
    }
    
    var mainView: some View {
        VStack {
            // Drag icon
            ZStack {
                Capsule()
                    .frame(width: 40, height: 6)
                    .foregroundColor(.black)
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.00001))
            .gesture(dragGesture)
            .padding(.top, 10)
            
            // Buttons
            HStack {
                VStack {
                    Text("Create")
                        .foregroundColor(.black)
                    Button {
                    } label: {
                        Image(systemName: "hand.tap")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding()
                            .buttonStyle(PlainButtonStyle())
                            .cornerRadius(16)
                            .foregroundColor(.black)
                    }
                    .frame(width: 40, height: 40)
                    .padding()
                }
                
                Divider().frame(width: 2)
                    .padding()
                
                VStack {
                    Text("Import")
                        .foregroundColor(.black)
                    Button {
                    } label: {
                        Image(systemName: "plus.viewfinder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding()
                            .buttonStyle(PlainButtonStyle())
                            .cornerRadius(16)
                            .foregroundColor(.black)
                    }
                    .frame(width: 40, height: 40)
                    .padding()
                }
                
                Divider().frame(width: 2)
                    .padding()
                
                VStack {
                    Text("Saved")
                        .foregroundColor(.black)
                    Button {
                    } label: {
                        Image(systemName: "externaldrive")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding()
                            .buttonStyle(PlainButtonStyle())
                            .cornerRadius(16)
                            .foregroundColor(.black)
                    }
                    .frame(width: 40, height: 40)
                    .padding()
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.bottom, 50)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 30)
            }
                .foregroundColor(.white)
        )
        .frame(height: curHeight)
        .frame(maxWidth: .infinity)
        .opacity(opacity)
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { gesture in
                let dragAmount = gesture.translation.height - prevDragTranslation.height
                
                // slow the drag up significantly
                if curHeight > threshold {
                    curHeight -= dragAmount / 6
                }
                else {
                    curHeight -= dragAmount
                    opacity = Double(curHeight/threshold)
                }
                
                prevDragTranslation = gesture.translation
            }
            .onEnded { _ in
                // make sure modal is correct size when it comes back up
                if curHeight < threshold {
                    isShowing = false
                }
                
                withAnimation {
                    curHeight = threshold
                    opacity = 0.0
                }
                prevDragTranslation = .zero
                opacity = 1.0
            }
    }
}

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
