import SwiftUI

struct HomeView: View {
    @StateObject private var game = GameViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                
                // Stars background
                StarsView()
                    .opacity(0.5)
                
                VStack(spacing: 30) {
                    // Title Card
                    CardView {
                        VStack {
                            Text("NEON")
                                .font(.system(size: 50, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: Color.blue, radius: 10, x: 0, y: 0)
                            
                            Text("BREAKOUT")
                                .font(.system(size: 50, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: Color.purple, radius: 10, x: 0, y: 0)
                        }
                        .padding()
                    }
                    
      
                    
                    // Play Game Card
                    NavigationLink(destination: NeonBreakoutGame()
                        .environmentObject(game)) {
                        CardView {
                            VStack {
                                Text("PLAY NOW")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.system(size: 24))
                                    
                                    Text("Start Breaking Bricks!")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.top, 10)
                            }
                            .padding()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
    }
}
// Card View Modifier
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color.black.opacity(0.5))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.5),
                                Color.purple.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// Instruction Step View (reusable component)
struct InstructdfionStep: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// Stars Background View
struct StarsVddiew: View {
    @State private var stars: [CGPoint] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(stars.indices, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...2), height: CGFloat.random(in: 1...2))
                        .position(stars[index])
                        .opacity(Double.random(in: 0.5...1.0))
                }
            }
            .onAppear {
                // Generate random stars
                stars = (0..<100).map { _ in
                    CGPoint(
                        x: CGFloat.random(in: 0..<geometry.size.width),
                        y: CGFloat.random(in: 0..<geometry.size.height)
                    )
                }
            }
        }
    }
}

// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.dark)
    }
}
