import SwiftUI

struct EntityModalView: View {
    @Binding var isShowing: Bool
    
    @State private var curHeight: CGFloat = 200
    @State private var prevDragTranslation = CGSize.zero
    @State private var opacity: Double = 1.0
    
    @ObservedObject var settings: Settings
    
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
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.right.and.arrow.down.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding()
                        .foregroundColor(.black)
                    Slider (
                        value: $settings.scale,
                        in: 0.1...5
                    )
                    .tint(.black)
                    .padding()
                    .onChange(of: settings.scale) { _ in
                        ARManager.shared.actionStream.send(.scaleEntity(scale: settings.scale))
                    }
                    Image(systemName: "arrow.down.left.and.arrow.up.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding()
                        .foregroundColor(.black)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding()
                        .foregroundColor(.black)
                    Slider (
                        value: $settings.angle,
                        in: -360...360
                    )
                    .tint(.black)
                    .padding()
                    .onChange(of: settings.angle) { _ in
                        ARManager.shared.actionStream.send(.rotateEntity(angle: settings.angle))
                    }
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding()
                        .foregroundColor(.black)
                    Spacer()
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
                    ARManager.shared.actionStream.send(.deselectEntity)
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

struct EntityModalView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
