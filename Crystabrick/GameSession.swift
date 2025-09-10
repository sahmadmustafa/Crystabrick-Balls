import SwiftUI

@available(iOS 15.0, *)
// MARK: - Data Model (unchanged)

struct GameSession: Identifiable, Codable {
    var id: UUID
    var levelSelected: String
    var powerUpUsed: String
    var totalBricksBroken: Int
    var comboStreaks: Int
    var livesLeft: Int
    var timeTaken: Int
    var themeUsed: String
    var customPaddleImage: Data?
    var status: String
    
    init(id: UUID = UUID(),
         levelSelected: String,
         powerUpUsed: String,
         totalBricksBroken: Int,
         comboStreaks: Int,
         livesLeft: Int,
         timeTaken: Int,
         themeUsed: String,
         customPaddleImage: Data? = nil,
         status: String) {
        self.id = id
        self.levelSelected = levelSelected
        self.powerUpUsed = powerUpUsed
        self.totalBricksBroken = totalBricksBroken
        self.comboStreaks = comboStreaks
        self.livesLeft = livesLeft
        self.timeTaken = timeTaken
        self.themeUsed = themeUsed
        self.customPaddleImage = customPaddleImage
        self.status = status
    }
}

@available(iOS 15.0, *)
// MARK: - ViewModel (unchanged)
class GameSessionViewModel: ObservableObject {
    @Published var sessions: [GameSession] = []
    @Published var showingAddSheet = false
    @Published var showingActionSheet = false
    @Published var selectedSession: GameSession?
    
    private let saveKey = "SavedGameSessions"
    
    init() {
        loadData()
    }
    
    func addSession(_ session: GameSession) {
        sessions.append(session)
        saveData()
    }
    
    func updateSession(_ session: GameSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            saveData()
        }
    }
    
    func deleteSession(at indexSet: IndexSet) {
        sessions.remove(atOffsets: indexSet)
        saveData()
    }
    
    func deleteSession(_ session: GameSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions.remove(at: index)
            saveData()
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([GameSession].self, from: data) {
            sessions = decoded
        }
    }
}

@available(iOS 15.0, *)
// MARK: - Main View (Redesigned)
struct PlayArenaTrackerView: View {
    @StateObject private var viewModel = GameSessionViewModel()
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Light background
                Color(.systemGray6)
                    .edgesIgnoringSafeArea(.all)
                
                // Content
                VStack(spacing: 0) {
                    if viewModel.sessions.isEmpty {
                        EmptyStateView()
                    } else {
                        List {
                            ForEach(viewModel.sessions) { session in
                                GameSessionCard(session: session)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .onTapGesture {
                                        viewModel.selectedSession = session
                                        viewModel.showingActionSheet = true
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            viewModel.selectedSession = session
                                            viewModel.showingActionSheet = true
                                        }) {
                                            Label("Options", systemImage: "ellipsis.circle")
                                        }
                                    }
                            }
                            .onDelete(perform: viewModel.deleteSession)
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Game Sessions")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.showingAddSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .sheet(isPresented: $viewModel.showingAddSheet) {
                    AddGameSessionView(viewModel: viewModel, showingImagePicker: $showingImagePicker)
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePickerView { image in
                        if let data = image.pngData() {
                            viewModel.selectedSession?.customPaddleImage = data
                        }
                    }
                }
                .actionSheet(isPresented: $viewModel.showingActionSheet) {
                    ActionSheet(
                        title: Text("Session Options"),
                        buttons: [
                            .default(Text("Edit")) {
                                viewModel.showingAddSheet = true
                            },
                            .destructive(Text("Delete")) {
                                if let session = viewModel.selectedSession {
                                    viewModel.deleteSession(session)
                                }
                            },
                            .cancel()
                        ]
                    )
                }
            }
        }
    }
}

@available(iOS 15.0, *)
// MARK: - Empty State View (Redesigned)
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.5))
            
            Text("No Game Sessions")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Add your first game session to track performance")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

@available(iOS 15.0, *)
// MARK: - Game Session Card (Redesigned)
struct GameSessionCard: View {
    let session: GameSession
    
    private var statusColor: Color {
        switch session.status {
        case "Game In Progress": return .blue
        case "Level Cleared": return .green
        case "Game Over": return .red
        default: return .gray
        }
    }
    
    private var statusIcon: String {
        switch session.status {
        case "Game In Progress": return "hourglass"
        case "Level Cleared": return "flag.checkered"
        case "Game Over": return "xmark.circle"
        default: return "circle"
        }
    }
    
    private var levelColor: Color {
        switch session.levelSelected {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        case "Custom": return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.levelSelected)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(levelColor)
                    
                    Text("\(session.totalBricksBroken) bricks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                    Text(session.status)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Divider
            Divider()
                .padding(.vertical, 4)
            
            // Stats
            HStack(spacing: 16) {
                StatView(icon: "arrow.clockwise", value: "\(session.comboStreaks)", label: "Combos")
                StatView(icon: "heart", value: "\(session.livesLeft)", label: "Lives")
                StatView(icon: "stopwatch", value: "\(session.timeTaken)s", label: "Time")
            }
            
            // Power-Up and Theme
            HStack(spacing: 16) {
                StatView(icon: "bolt", value: session.powerUpUsed, label: "Power-Up")
                StatView(icon: "paintbrush", value: session.themeUsed, label: "Theme")
            }
            
            // Custom Paddle Preview if available
            if let imageData = session.customPaddleImage,
               let uiImage = UIImage(data: imageData) {
                HStack {
                    Text("Custom Paddle:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                        .cornerRadius(4)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

@available(iOS 15.0, *)
// MARK: - Stat View Component
struct StatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 15.0, *)
// MARK: - Add/Edit View (Redesigned)
struct AddGameSessionView: View {
    @ObservedObject var viewModel: GameSessionViewModel
    @Binding var showingImagePicker: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @State private var levelSelected: String = "Easy"
    @State private var powerUpUsed: String = "None"
    @State private var totalBricksBroken: String = "0"
    @State private var comboStreaks: String = "0"
    @State private var livesLeft: String = "3"
    @State private var timeTaken: String = "0"
    @State private var themeUsed: String = "Neon Green"
    @State private var status: String = "Game In Progress"
    
    private let levels = ["Easy", "Medium", "Hard", "Custom"]
    private let powerUps = ["None", "Laser", "Multiball", "Slow Time", "Wide Paddle", "Shield"]
    private let themes = ["Neon Green", "Pink Pulse", "Blue Wave", "Dark Matter", "Retro Arcade"]
    private let statusOptions = ["Game In Progress", "Level Cleared", "Game Over"]
    
    private var isEditing: Bool {
        if let selected = viewModel.selectedSession {
            return viewModel.sessions.contains { $0.id == selected.id }
        }
        return false
    }
    
    init(viewModel: GameSessionViewModel, showingImagePicker: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingImagePicker = showingImagePicker
        
        if let selected = viewModel.selectedSession {
            _levelSelected = State(initialValue: selected.levelSelected)
            _powerUpUsed = State(initialValue: selected.powerUpUsed)
            _totalBricksBroken = State(initialValue: String(selected.totalBricksBroken))
            _comboStreaks = State(initialValue: String(selected.comboStreaks))
            _livesLeft = State(initialValue: String(selected.livesLeft))
            _timeTaken = State(initialValue: String(selected.timeTaken))
            _themeUsed = State(initialValue: selected.themeUsed)
            _status = State(initialValue: selected.status)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Info")) {
                    Picker("Level", selection: $levelSelected) {
                        ForEach(levels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { stat in
                            Text(stat).tag(stat)
                        }
                    }
                }
                
                Section(header: Text("Customization")) {
                    Picker("Power-Up", selection: $powerUpUsed) {
                        ForEach(powerUps, id: \.self) { power in
                            Text(power).tag(power)
                        }
                    }
                    
                    Picker("Theme", selection: $themeUsed) {
                        ForEach(themes, id: \.self) { theme in
                            Text(theme).tag(theme)
                        }
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
//                        HStack {
//                            Image(systemName: "photo")
//                            Text("Custom Paddle Image")
//                            Spacer()
//                            if viewModel.selectedSession?.customPaddleImage != nil {
//                                Image(systemName: "checkmark.circle.fill")
//                                    .foregroundColor(.green)
//                            }
//                        }
                    }
                }
                
                Section(header: Text("Performance")) {
                    NumberInputField(title: "Bricks Broken", value: $totalBricksBroken)
                    NumberInputField(title: "Combo Streaks", value: $comboStreaks)
                    NumberInputField(title: "Lives Left", value: $livesLeft)
                    NumberInputField(title: "Time Taken (sec)", value: $timeTaken)
                }
                
                Section {
                    Button(action: saveSession) {
                        HStack {
                            Spacer()
                            Text(isEditing ? "Update Session" : "Add Session")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Session" : "New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                        viewModel.selectedSession = nil
                    }
                }
            }
        }
    }
    
    private func saveSession() {
        guard let bricksBroken = Int(totalBricksBroken),
              let streaks = Int(comboStreaks),
              let lives = Int(livesLeft),
              let time = Int(timeTaken) else {
            return
        }
        
        let newSession = GameSession(
            levelSelected: levelSelected,
            powerUpUsed: powerUpUsed,
            totalBricksBroken: bricksBroken,
            comboStreaks: streaks,
            livesLeft: lives,
            timeTaken: time,
            themeUsed: themeUsed,
            customPaddleImage: viewModel.selectedSession?.customPaddleImage,
            status: status
        )
        
        if isEditing, let selected = viewModel.selectedSession {
            var updatedSession = newSession
            updatedSession.id = selected.id
            updatedSession.customPaddleImage = selected.customPaddleImage
            viewModel.updateSession(updatedSession)
        } else {
            viewModel.addSession(newSession)
        }
        
        presentationMode.wrappedValue.dismiss()
        viewModel.selectedSession = nil
    }
}

@available(iOS 15.0, *)
// MARK: - Number Input Field
struct NumberInputField: View {
    let title: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: $value)
                .multilineTextAlignment(.trailing)
        }
    }
}

@available(iOS 15.0, *)
// MARK: - Image Picker View (unchanged)
struct ImagePickerView: UIViewControllerRepresentable {
    var onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

@available(iOS 15.0, *)
struct PlayArenaTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayArenaTrackerView()
    }
}
