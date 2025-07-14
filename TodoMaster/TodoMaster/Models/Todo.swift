import Foundation
import SwiftUI
import CloudKit

public class Todo: Identifiable, ObservableObject, Codable, Hashable {
    public let id: UUID
    @Published public var title: String
    @Published public var notes: String
    @Published public var isCompleted: Bool
    @Published public var dueDate: Date?
    @Published public var priority: Priority
    @Published public var category: Category?
    @Published public var tags: [Tag]
    @Published public var createdAt: Date
    @Published public var updatedAt: Date
    @Published public var reminderDate: Date?
    @Published public var isPinned: Bool
    @Published public var estimatedTime: TimeInterval?
    @Published public var attachments: [Attachment]
    @Published public var location: Location?
    @Published public var pomodoroCount: Int
    @Published public var completedPomodoros: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, notes, isCompleted, dueDate, priority, category, tags
        case createdAt, updatedAt, reminderDate, isPinned, estimatedTime, attachments
        case location, pomodoroCount, completedPomodoros
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(notes, forKey: .notes)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(dueDate, forKey: .dueDate)
        try container.encode(priority, forKey: .priority)
        try container.encode(category, forKey: .category)
        try container.encode(tags, forKey: .tags)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(reminderDate, forKey: .reminderDate)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(estimatedTime, forKey: .estimatedTime)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(location, forKey: .location)
        try container.encode(pomodoroCount, forKey: .pomodoroCount)
        try container.encode(completedPomodoros, forKey: .completedPomodoros)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decode(String.self, forKey: .notes)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        priority = try container.decode(Priority.self, forKey: .priority)
        category = try container.decodeIfPresent(Category.self, forKey: .category)
        tags = try container.decode([Tag].self, forKey: .tags)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        estimatedTime = try container.decodeIfPresent(TimeInterval.self, forKey: .estimatedTime)
        attachments = try container.decode([Attachment].self, forKey: .attachments)
        location = try container.decodeIfPresent(Location.self, forKey: .location)
        pomodoroCount = try container.decode(Int.self, forKey: .pomodoroCount)
        completedPomodoros = try container.decode(Int.self, forKey: .completedPomodoros)
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priority: Priority = .none,
        category: Category? = nil,
        tags: [Tag] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        reminderDate: Date? = nil,
        isPinned: Bool = false,
        estimatedTime: TimeInterval? = nil,
        attachments: [Attachment] = [],
        location: Location? = nil,
        pomodoroCount: Int = 0,
        completedPomodoros: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.category = category
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reminderDate = reminderDate
        self.isPinned = isPinned
        self.estimatedTime = estimatedTime
        self.attachments = attachments
        self.location = location
        self.pomodoroCount = pomodoroCount
        self.completedPomodoros = completedPomodoros
    }
    
    public enum Priority: Int, Codable, CaseIterable, Hashable {
        case none = 0
        case low = 1
        case medium = 2
        case high = 3
        
        public var name: String {
            switch self {
            case .none: return "None"
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
        
        public var icon: String {
            switch self {
            case .none: return "circle"
            case .low: return "exclamationmark.circle"
            case .medium: return "exclamationmark.2.circle"
            case .high: return "exclamationmark.3.circle"
            }
        }
        
        public var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            default: return .gray
            }
        }
    }
    
    public struct Category: Identifiable, Codable, Hashable {
        public let id: UUID
        public var name: String
        public var colorHex: String
        public var icon: String
        
        public static let defaultColors = [
            ColorOption(name: "Blue", hex: "#007AFF"),
            ColorOption(name: "Green", hex: "#34C759"),
            ColorOption(name: "Orange", hex: "#FF9500"),
            ColorOption(name: "Red", hex: "#FF3B30"),
            ColorOption(name: "Purple", hex: "#AF52DE"),
            ColorOption(name: "Yellow", hex: "#FFD60A"),
            ColorOption(name: "Pink", hex: "#FF2D55"),
            ColorOption(name: "Teal", hex: "#5AC8FA"),
            ColorOption(name: "Indigo", hex: "#5856D6")
        ]
        
        public struct ColorOption: Identifiable, Codable, Hashable {
            public let id: UUID
            public let name: String
            public let hex: String
            
            public init(name: String, hex: String) {
                self.id = UUID()
                self.name = name
                self.hex = hex
            }
            
            public func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
            
            public static func == (lhs: ColorOption, rhs: ColorOption) -> Bool {
                return lhs.id == rhs.id
            }
        }
        
        public var color: Color {
            Color(hex: colorHex) ?? .blue
        }
        
        public init(id: UUID = UUID(), name: String, colorHex: String, icon: String) {
            self.id = id
            self.name = name
            self.colorHex = colorHex
            self.icon = icon
        }
        
        public init(id: UUID = UUID(), name: String, color: Color, icon: String) {
            self.id = id
            self.name = name
            self.colorHex = color.hex
            self.icon = icon
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public static func == (lhs: Category, rhs: Category) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    public struct Tag: Identifiable, Codable, Equatable, Hashable {
        public let id: UUID
        public var name: String
        public var color: String
        
        public init(id: UUID = UUID(), name: String, color: String) {
            self.id = id
            self.name = name
            self.color = color
        }
        
        public static func == (lhs: Tag, rhs: Tag) -> Bool {
            lhs.id == rhs.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    public struct Attachment: Identifiable, Codable, Equatable {
        public let id: UUID
        public var data: Data
        public var filename: String
        public var type: AttachmentType
        
        public init(id: UUID = UUID(), data: Data, filename: String, type: AttachmentType) {
            self.id = id
            self.data = data
            self.filename = filename
            self.type = type
        }
        
        public enum AttachmentType: String, Codable {
            case image
            case document
            case audio
            case video
            
            public var icon: String {
                switch self {
                case .image: return "photo"
                case .document: return "doc"
                case .audio: return "waveform"
                case .video: return "video"
                }
            }
        }
    }
    
    public struct Location: Identifiable, Codable, Hashable {
        public let id: UUID
        public var latitude: Double
        public var longitude: Double
        public var name: String
        
        public init(id: UUID = UUID(), latitude: Double, longitude: Double, name: String) {
            self.id = id
            self.latitude = latitude
            self.longitude = longitude
            self.name = name
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public static func == (lhs: Location, rhs: Location) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    // MARK: - CloudKit Support
    func cloudKitRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "Todo", recordID: CKRecord.ID(recordName: id.uuidString))
        record["title"] = title
        record["notes"] = notes
        record["dueDate"] = dueDate
        record["priority"] = priority.rawValue
        record["isCompleted"] = isCompleted
        record["categoryID"] = category?.id.uuidString
        record["tagIDs"] = Array(tags).map { $0.id.uuidString }
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        if let location = location {
            record["latitude"] = location.latitude
            record["longitude"] = location.longitude
            record["locationName"] = location.name
        }
        return record
    }
    
    init(from record: CKRecord) {
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.title = record["title"] as? String ?? "Untitled"
        self.notes = record["notes"] as? String ?? ""
        self.isCompleted = record["isCompleted"] as? Bool ?? false
        self.dueDate = record["dueDate"] as? Date
        self.priority = Priority(rawValue: record["priority"] as? Int ?? 0) ?? .none
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.updatedAt = record["updatedAt"] as? Date ?? Date()
        self.reminderDate = record["reminderDate"] as? Date
        self.isPinned = record["isPinned"] as? Bool ?? false
        self.estimatedTime = record["estimatedTime"] as? TimeInterval
        self.attachments = record["attachments"] as? [Attachment] ?? []
        self.pomodoroCount = record["pomodoroCount"] as? Int ?? 0
        self.completedPomodoros = record["completedPomodoros"] as? Int ?? 0
        
        if let latitude = record["latitude"] as? Double,
           let longitude = record["longitude"] as? Double,
           let locationName = record["locationName"] as? String {
            self.location = Location(latitude: latitude, longitude: longitude, name: locationName)
        } else {
            self.location = nil
        }
        
        // Category and tags will need to be set after initialization
        self.category = nil
        self.tags = []
    }
    
    // MARK: - Hashable Conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable Conformance
    public static func == (lhs: Todo, rhs: Todo) -> Bool {
        return lhs.id == rhs.id
    }
} 
