import Foundation

/// One saved vocabulary entry.
struct Word: Identifiable, Codable, Hashable {
    var id: UUID
    /// The English word or phrase.
    var english: String
    /// The English definition.
    var definition: String
    /// The Sinhala meaning (සිංහල අර්ථය).
    var sinhala: String
    /// Optional example sentence.
    var example: String
    var isFavorite: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        english: String,
        definition: String = "",
        sinhala: String = "",
        example: String = "",
        isFavorite: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.english = english
        self.definition = definition
        self.sinhala = sinhala
        self.example = example
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    /// Decoded field by field so that words saved by an older version of the
    /// app keep loading after new fields are added.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        english = try c.decodeIfPresent(String.self, forKey: .english) ?? ""
        definition = try c.decodeIfPresent(String.self, forKey: .definition) ?? ""
        sinhala = try c.decodeIfPresent(String.self, forKey: .sinhala) ?? ""
        example = try c.decodeIfPresent(String.self, forKey: .example) ?? ""
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    var displayDefinition: String {
        definition.isEmpty ? "No definition yet" : definition
    }

    var displaySinhala: String {
        sinhala.isEmpty ? "—" : sinhala
    }
}
