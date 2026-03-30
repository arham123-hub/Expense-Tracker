//
//  Expense.swift
//  saaaad
//

import Foundation
import SwiftUI

enum Category: String, CaseIterable, Identifiable, Codable {
    case food = "Food"
    case transport = "Transport"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case bills = "Bills"
    case health = "Health"
    case rent = "Rent"
    case education = "Education"
    case travel = "Travel"
    case groceries = "Groceries"
    case subscriptions = "Subscriptions"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food:          return "fork.knife"
        case .transport:     return "car.fill"
        case .entertainment: return "tv.fill"
        case .shopping:      return "bag.fill"
        case .bills:         return "doc.text.fill"
        case .health:        return "heart.fill"
        case .rent:          return "house.fill"
        case .education:     return "book.fill"
        case .travel:        return "airplane"
        case .groceries:     return "cart.fill"
        case .subscriptions: return "repeat.circle.fill"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food:          return .orange
        case .transport:     return Color(red: 0.2, green: 0.5, blue: 1.0)
        case .entertainment: return .purple
        case .shopping:      return .pink
        case .bills:         return .red
        case .health:        return .green
        case .rent:          return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .education:     return Color(red: 0.1, green: 0.6, blue: 0.6)
        case .travel:        return Color(red: 0.0, green: 0.6, blue: 0.8)
        case .groceries:     return Color(red: 0.3, green: 0.7, blue: 0.3)
        case .subscriptions: return Color(red: 0.5, green: 0.2, blue: 0.8)
        case .other:         return .gray
        }
    }
}

struct Expense: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Double
    var category: Category
    var date: Date
    var note: String

    enum CodingKeys: String, CodingKey {
        case id, name, amount, category, date, note
    }

    init(name: String, amount: Double, category: Category, date: Date = Date(), note: String = "") {
        self.name = name
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = try c.decode(UUID.self,     forKey: .id)
        name     = try c.decode(String.self,   forKey: .name)
        amount   = try c.decode(Double.self,   forKey: .amount)
        category = try c.decode(Category.self, forKey: .category)
        date     = try c.decode(Date.self,     forKey: .date)
        note     = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
}

enum TimePeriod: String, CaseIterable, Identifiable {
    case thisMonth   = "This Month"
    case lastMonth   = "Last Month"
    case threeMonths = "3 Months"
    case allTime     = "All Time"
    var id: String { rawValue }
}
