

import SwiftUI


@available(iOS 15.0, *)
// MARK: - Data Model
struct CreatorDesign: Identifiable, Codable {
    var id: UUID
    var brickColorSchemeName: String
    var brickImage: Data?
    var neonTrailEffect: String
    var customPowerUpName: String
    var paddleSkinColor: String
    var challengeTitle: String
    var brickPatternStyle: String
    var challengeDifficulty: Int
    var status: String
    
    init(id: UUID = UUID(),
         brickColorSchemeName: String,
         brickImage: Data? = nil,
         neonTrailEffect: String,
         customPowerUpName: String,
         paddleSkinColor: String,
         challengeTitle: String,
         brickPatternStyle: String,
         challengeDifficulty: Int,
         status: String) {
        self.id = id
        self.brickColorSchemeName = brickColorSchemeName
        self.brickImage = brickImage
        self.neonTrailEffect = neonTrailEffect
        self.customPowerUpName = customPowerUpName
        self.paddleSkinColor = paddleSkinColor
        self.challengeTitle = challengeTitle
        self.brickPatternStyle = brickPatternStyle
        self.challengeDifficulty = challengeDifficulty
        self.status = status
    }
}

@available(iOS 15.0, *)
// MARK: - ViewModel
class CreatorViewModel: ObservableObject {
    @Published var designs: [CreatorDesign] = []
    @Published var showingAddSheet = false
    @Published var showingActionSheet = false
    @Published var selectedDesign: CreatorDesign?
    @Published var showingImagePicker = false
    
    private let saveKey = "SavedCreatorDesigns"
    
    init() {
        loadData()
    }
    
    func addDesign(_ design: CreatorDesign) {
        designs.append(design)
        saveData()
    }
    
    func updateDesign(_ design: CreatorDesign) {
        if let index = designs.firstIndex(where: { $0.id == design.id }) {
            designs[index] = design
            saveData()
        }
    }
    
    func deleteDesign(at indexSet: IndexSet) {
        designs.remove(atOffsets: indexSet)
        saveData()
    }
    
    func deleteDesign(_ design: CreatorDesign) {
        if let index = designs.firstIndex(where: { $0.id == design.id }) {
            designs.remove(at: index)
            saveData()
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(designs) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CreatorDesign].self, from: data) {
            designs = decoded
        }
    }
}

@available(iOS 15.0, *)
// MARK: - Main View
struct CreatorLabView: View {
    @StateObject private var viewModel = CreatorViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    if viewModel.designs.isEmpty {
                        EmptyStsdsateView()
                    } else {
                        List {
                            ForEach(viewModel.designs) { design in
                                CreatorDesignCard(design: design)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .onTapGesture {
                                        viewModel.selectedDesign = design
                                        viewModel.showingActionSheet = true
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            viewModel.selectedDesign = design
                                            viewModel.showingActionSheet = true
                                        }) {
                                            Label("Options", systemImage: "ellipsis.circle")
                                        }
                                    }
                            }
                            .onDelete(perform: viewModel.deleteDesign)
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Creator Lab")
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
                    AddCreatorDesignView(viewModel: viewModel)
                }
                .sheet(isPresented: $viewModel.showingImagePicker) {
                    ImagePickerView { image in
                        if let data = image.pngData() {
                            viewModel.selectedDesign?.brickImage = data
                        }
                    }
                }
                .actionSheet(isPresented: $viewModel.showingActionSheet) {
                    ActionSheet(
                        title: Text("Design Options"),
                        buttons: [
                            .default(Text("Edit")) {
                                viewModel.showingAddSheet = true
                            },
                            .destructive(Text("Delete")) {
                                if let design = viewModel.selectedDesign {
                                    viewModel.deleteDesign(design)
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
// MARK: - Empty State View
struct EmptyStsdsateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "paintbrush.pointed")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.5))
            
            Text("No Designs Created")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Create your first custom brick set or paddle skin")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

@available(iOS 15.0, *)
// MARK: - Design Card View
struct CreatorDesignCard: View {
    let design: CreatorDesign
    
    private var statusColor: Color {
        switch design.status {
        case "Saved": return .blue
        case "Pending Test": return .orange
        case "Shared with Community": return .green
        default: return .gray
        }
    }
    
    private var statusIcon: String {
        switch design.status {
        case "Saved": return "tray.and.arrow.down"
        case "Pending Test": return "hourglass"
        case "Shared with Community": return "person.2"
        default: return "circle"
        }
    }
    
    private var difficultyColor: Color {
        switch design.challengeDifficulty {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4...5: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(design.challengeTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(design.brickColorSchemeName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                    Text(design.status)
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
            
            // Design Details
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pattern")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(design.brickPatternStyle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Power-Up")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(design.customPowerUpName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Difficulty")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= design.challengeDifficulty ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(difficultyColor)
                        }
                    }
                }
            }
            
            // Visual Preview
            HStack {
                if let imageData = design.brickImage,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                        .cornerRadius(6)
                }
                
                Circle()
                    .fill(Color(hex: design.paddleSkinColor))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                
                Spacer()
                
                Text(design.neonTrailEffect)
                    .font(.caption)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.top, 8)
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
// MARK: - Add/Edit View
struct AddCreatorDesignView: View {
    @ObservedObject var viewModel: CreatorViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var brickColorSchemeName: String = ""
    @State private var neonTrailEffect: String = "Standard"
    @State private var customPowerUpName: String = ""
    @State private var paddleSkinColor: String = "#FF6B6B"
    @State private var challengeTitle: String = ""
    @State private var brickPatternStyle: String = "Grid"
    @State private var challengeDifficulty: Int = 1
    @State private var status: String = "Saved"
    
    private let trailEffects = ["Standard", "Pulse", "Streak", "Sparkle", "Wave"]
    private let patternStyles = ["Grid", "Zigzag", "Spiral", "Checker", "Random"]
    private let statusOptions = ["Saved", "Pending Test", "Shared with Community"]
    private let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFBE0B", "#A05195", "#00B4D8"]
    
    private var isEditing: Bool {
        if let selected = viewModel.selectedDesign {
            return viewModel.designs.contains { $0.id == selected.id }
        }
        return false
    }
    
    init(viewModel: CreatorViewModel) {
        self.viewModel = viewModel
        
        if let selected = viewModel.selectedDesign {
            _brickColorSchemeName = State(initialValue: selected.brickColorSchemeName)
            _neonTrailEffect = State(initialValue: selected.neonTrailEffect)
            _customPowerUpName = State(initialValue: selected.customPowerUpName)
            _paddleSkinColor = State(initialValue: selected.paddleSkinColor)
            _challengeTitle = State(initialValue: selected.challengeTitle)
            _brickPatternStyle = State(initialValue: selected.brickPatternStyle)
            _challengeDifficulty = State(initialValue: selected.challengeDifficulty)
            _status = State(initialValue: selected.status)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Challenge Title", text: $challengeTitle)
                    TextField("Color Scheme Name", text: $brickColorSchemeName)
                }
                
                Section(header: Text("Visual Design")) {
                    Button(action: {
                        viewModel.showingImagePicker = true
                    }) {
//                        HStack {
//                            Image(systemName: "photo")
//                            Text(viewModel.selectedDesign?.brickImage != nil ? "Change Brick Image" : "Upload Brick Image")
//                            Spacer()
//                            if viewModel.selectedDesign?.brickImage != nil {
//                                Image(systemName: "checkmark.circle.fill")
//                                    .foregroundColor(.green)
//                            }
//                        }
                    }
                    
                    Picker("Brick Pattern", selection: $brickPatternStyle) {
                        ForEach(patternStyles, id: \.self) { style in
                            Text(style).tag(style)
                        }
                    }
                    
                    Picker("Neon Trail Effect", selection: $neonTrailEffect) {
                        ForEach(trailEffects, id: \.self) { effect in
                            Text(effect).tag(effect)
                        }
                    }
                }
                
                Section(header: Text("Customization")) {
                    TextField("Custom Power-Up Name", text: $customPowerUpName)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paddle Skin Color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(color == paddleSkinColor ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            paddleSkinColor = color
                                        }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Challenge Settings")) {
                    Stepper(value: $challengeDifficulty, in: 1...5) {
                        HStack {
                            Text("Difficulty")
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= challengeDifficulty ? "star.fill" : "star")
                                        .foregroundColor(star <= challengeDifficulty ? .yellow : .gray)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { stat in
                            Text(stat).tag(stat)
                        }
                    }
                }
                
                Section {
                    Button(action: saveDesign) {
                        HStack {
                            Spacer()
                            Text(isEditing ? "Update Design" : "Save Design")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Design" : "New Design")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                        viewModel.selectedDesign = nil
                    }
                }
            }
        }
    }
    
    private func saveDesign() {
        let newDesign = CreatorDesign(
            brickColorSchemeName: brickColorSchemeName,
            brickImage: viewModel.selectedDesign?.brickImage,
            neonTrailEffect: neonTrailEffect,
            customPowerUpName: customPowerUpName,
            paddleSkinColor: paddleSkinColor,
            challengeTitle: challengeTitle,
            brickPatternStyle: brickPatternStyle,
            challengeDifficulty: challengeDifficulty,
            status: status
        )
        
        if isEditing, let selected = viewModel.selectedDesign {
            var updatedDesign = newDesign
            updatedDesign.id = selected.id
            updatedDesign.brickImage = selected.brickImage
            viewModel.updateDesign(updatedDesign)
        } else {
            viewModel.addDesign(newDesign)
        }
        
        presentationMode.wrappedValue.dismiss()
        viewModel.selectedDesign = nil
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
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

@available(iOS 15.0, *)
struct CreatorLabView_Previews: PreviewProvider {
    static var previews: some View {
        CreatorLabView()
    }
}
