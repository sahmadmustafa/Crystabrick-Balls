


import SwiftUI

struct HomeView2: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background
                LinearGradient(gradient: Gradient(colors: [
                    Color(hex: "0F0525"),
                    Color(hex: "1A0933"),
                    Color(hex: "2A0B4A")
                ]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Title
                    Text("NEON BREAKOUT")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: Color(hex: "E94560"), radius: 10, x: 0, y: 0)
                    
                    Spacer()
                    
                    // Game Cards
                    VStack(spacing: 25) {
                        // Card 1 - Play Arena Tracker
                        NavigationLink(destination: PlayArenaTrackerView()) {
                            GameCard(
                                title: "PLAY ARENA TRACKER",
                                icon: "gamecontroller.fill",
                                color: Color(hex: "00D1FF"),
                                description: "Track your gameplay stats and performance"
                            )
                        }
                        
                        // Card 2 - Creator Lab
                        NavigationLink(destination: CreatorLabView()) {
                            GameCard(
                                title: "CREATOR LAB",
                                icon: "paintbrush.fill",
                                color: Color(hex: "FF00E4"),
                                description: "Design custom paddles and game themes"
                            )
                        }
                        
                        // Card 3 - Coming Soon
                        // Card 2 - Creator Lab
                        NavigationLink(destination: HomeView()) {
                            GameCard(
                                title: "Start Game",
                                icon: "gamecontroller.fill",
                                color: Color(hex: "FF00E4"),
                                description: ""
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .accentColor(.pink)
    }
}

struct GameCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    var locked: Bool = false
    
    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "1E103A"))
                .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Neon border
            RoundedRectangle(cornerRadius: 15)
                .stroke(color, lineWidth: 2)
                .shadow(color: color, radius: 5, x: 0, y: 0)
                .shadow(color: color, radius: 5, x: 0, y: 0)
            
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(color)
                    
                    if locked {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Title
                Text(title)
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
            .padding(20)
        }
        .frame(height: 180)
        .opacity(locked ? 0.7 : 1.0)
    }
}



// Color extension
extension Color {
    init(hesdsdx: String) {
        let hesdsdx = hesdsdx.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hesdsdx).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hesdsdx.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct HomeView2_Previews: PreviewProvider {
    static var previews: some View {
        HomeView2()
    }
}
