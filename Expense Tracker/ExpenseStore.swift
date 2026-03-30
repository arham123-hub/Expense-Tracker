//
//  ExpenseStore.swift
//  saaaad
//

import Foundation

class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = [] {
        didSet { save() }
    }
    @Published var budgets: [String: Double] = [:] {
        didSet { saveBudgets() }
    }

    private let expensesKey = "SavedExpenses"
    private let budgetsKey  = "SavedBudgets"

    init() {
        load()
        loadBudgets()
    }

    // MARK: - CRUD
    func add(_ expense: Expense)    { expenses.append(expense) }
    func delete(_ expense: Expense) { expenses.removeAll { $0.id == expense.id } }
    func update(_ expense: Expense) {
        if let i = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[i] = expense
        }
    }

    // MARK: - Budgets
    func setBudget(_ amount: Double, for category: Category) {
        budgets[category.rawValue] = amount
    }
    func budget(for category: Category) -> Double {
        budgets[category.rawValue] ?? 0
    }

    // MARK: - Filtering
    func filtered(by period: TimePeriod, category: Category? = nil) -> [Expense] {
        let calendar = Calendar.current
        let now = Date()
        var base: [Expense]
        switch period {
        case .thisMonth:
            base = expenses.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .lastMonth:
            let last = calendar.date(byAdding: .month, value: -1, to: now)!
            base = expenses.filter { calendar.isDate($0.date, equalTo: last, toGranularity: .month) }
        case .threeMonths:
            let cutoff = calendar.date(byAdding: .month, value: -3, to: now)!
            base = expenses.filter { $0.date >= cutoff }
        case .allTime:
            base = expenses
        }
        if let cat = category { base = base.filter { $0.category == cat } }
        return base
    }

    func total(period: TimePeriod = .thisMonth, category: Category? = nil) -> Double {
        filtered(by: period, category: category).reduce(0) { $0 + $1.amount }
    }

    // MARK: - Analytics Helpers
    func monthlyTotals(months: Int = 6) -> [(month: Date, total: Double)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<months).reversed().compactMap { offset -> (Date, Double)? in
            guard
                let target = calendar.date(byAdding: .month, value: -offset, to: now),
                let start  = calendar.date(from: calendar.dateComponents([.year, .month], from: target))
            else { return nil }
            let t = expenses
                .filter { calendar.isDate($0.date, equalTo: target, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
            return (start, t)
        }
    }

    func dailyAverage(period: TimePeriod) -> Double {
        let list = filtered(by: period)
        guard !list.isEmpty else { return 0 }
        let total = list.reduce(0) { $0 + $1.amount }
        let calendar = Calendar.current
        let days: Double
        switch period {
        case .thisMonth:
            days = Double(max(1, calendar.component(.day, from: Date())))
        case .lastMonth:
            let lm = calendar.date(byAdding: .month, value: -1, to: Date())!
            days = Double(calendar.range(of: .day, in: .month, for: lm)?.count ?? 30)
        case .threeMonths:
            days = 90
        case .allTime:
            if let oldest = list.min(by: { $0.date < $1.date }) {
                days = max(1, Date().timeIntervalSince(oldest.date) / 86400)
            } else { days = 1 }
        }
        return total / days
    }

    func monthOverMonthChange() -> Double? {
        let this = total(period: .thisMonth)
        let last = total(period: .lastMonth)
        guard last > 0 else { return nil }
        return (this - last) / last
    }

    // MARK: - CSV Export
    func csvData(for period: TimePeriod = .allTime) -> Data {
        var rows = ["Date,Name,Category,Amount,Note"]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        for e in filtered(by: period).sorted(by: { $0.date > $1.date }) {
            let note = e.note.replacingOccurrences(of: "\"", with: "\"\"")
            let name = e.name.replacingOccurrences(of: "\"", with: "\"\"")
            rows.append("\(formatter.string(from: e.date)),\"\(name)\",\(e.category.rawValue),\(e.amount),\"\(note)\"")
        }
        return rows.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    // MARK: - Persistence
    private func save() {
        if let d = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(d, forKey: expensesKey)
        }
    }
    private func load() {
        if let d = UserDefaults.standard.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: d) {
            expenses = decoded
        }
    }
    private func saveBudgets() {
        if let d = try? JSONEncoder().encode(budgets) {
            UserDefaults.standard.set(d, forKey: budgetsKey)
        }
    }
    private func loadBudgets() {
        if let d = UserDefaults.standard.data(forKey: budgetsKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: d) {
            budgets = decoded
        }
    }
}
