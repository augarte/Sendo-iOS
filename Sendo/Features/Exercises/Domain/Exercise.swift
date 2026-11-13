//
//  Exercise.swift
//  Sendo
//
//  Created by Aimar Ugarte on 24/10/21.
//

import Foundation

typealias ExerciseID = String

public struct Exercise: Codable {

    let id: ExerciseID
    let name: String
    let title: String
    let type: String
    let description: String
    let steps: [String]
    let tips: [String]
    let primary: [String]
    let secondary: [String]
    let equipment: [String]
    let images: [String]
}

/// The filter groups the catalog's anatomical muscle names fold into. Every catalog exercise falls in at least one.
enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case core = "Core"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"

    var id: String { rawValue }
    var title: String { rawValue }

    init?(muscle: String) {
        let name = muscle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch name {
        case "pectoralis major", "chest": self = .chest
        case "latissimus dorsi", "erector spinae", "trapezius", "back", "upper back", "lower back": self = .back
        case "biceps brachii", "biceps", "bicpes": self = .biceps
        case "triceps brachii", "triceps": self = .triceps
        case "abdominals", "obliques", "core": self = .core
        case "quadriceps", "quads": self = .quads
        case "ischiocrural muscles", "hamstrings": self = .hamstrings
        case "glutaeus maximus", "glutes": self = .glutes
        case "gastrocnemius", "soleus", "calves": self = .calves
        case let name where name.hasPrefix("deltoid") || name == "shoulders" || name == "should": self = .shoulders
        default: return nil
        }
    }
}

extension Exercise {
    var primaryGroups: [MuscleGroup] {
        var groups: [MuscleGroup] = []
        for group in primary.compactMap(MuscleGroup.init(muscle:)) where !groups.contains(group) { groups.append(group) }
        return groups
    }

    /// Primary muscle names for display, falling back to the raw catalog names when none map to a group.
    var primaryTitles: [String] {
        let groups = primaryGroups.map(\.title)
        return groups.isEmpty ? primary.map(Self.sentenceCase) : groups
    }

    /// Secondary muscles for display, without repeating anything already listed as primary.
    var secondaryTitles: [String] {
        var titles: [String] = []
        let excluded = Set(primaryTitles)
        for muscle in secondary {
            let title = MuscleGroup(muscle: muscle)?.title ?? Self.sentenceCase(muscle.lowercased() == "forerm" ? "forearm" : muscle)
            if !excluded.contains(title), !titles.contains(title) { titles.append(title) }
        }
        return titles
    }

    var equipmentTitles: [String] {
        var titles: [String] = []
        for item in equipment {
            let title = Self.equipmentTitle(item)
            if !titles.contains(where: { $0.caseInsensitiveCompare(title) == .orderedSame }) { titles.append(title) }
        }
        return titles
    }

    /// "Chest · Barbell": the primary muscles and the first piece of equipment, for list rows.
    var summary: String {
        (primaryTitles + equipmentTitles.prefix(1)).joined(separator: " · ")
    }

    /// "compound, isolation" becomes "Compound · Isolation".
    var typeTitle: String {
        type.split(separator: ",").map { Self.sentenceCase(String($0)) }.joined(separator: " · ")
    }

    private static func sentenceCase(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }

    /// Catalog equipment like "bench: incline" or "machine: butterfly" reads as "Incline bench" and "Butterfly machine".
    private static func equipmentTitle(_ raw: String) -> String {
        var name = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch name {
        case "body": return "Bodyweight"
        case "dumbbells": name = "dumbbell"
        default: break
        }
        let parts = name.components(separatedBy: ": ")
        if parts.count == 2 { name = parts[1] + " " + parts[0] }
        return sentenceCase(name)
    }
}
