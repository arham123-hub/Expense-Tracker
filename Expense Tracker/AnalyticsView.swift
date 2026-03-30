//
//  AnalyticsView.swift
//  saaaad
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var store: ExpenseStore
    @State private var showingBudgets = false

    private var monthlyData: [(month: Date, total: Double)] {
        store.monthlyTotals(months: 6)
    }

    private var categoryData: [(cat: Category, total: Double)] {
        Category.allCases
            .map { (cat: $0, total: store.total(period: .thisMonth, category: $0)) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }

    private let monthFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthlyBarChart
                    categoryBreakdown
                    budgetSection
                    insightsSection
                }
                .padding()
                .padding(.bottom, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingBudgets = true
                    } label: {
                        Label("Budgets", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingBudgets) {
                BudgetSettingsView(store: store)
            }
        }
    }

    // MARK: Monthly Bar Chart
    private var monthlyBarChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Monthly Spending")
                    .font(.headline)
                Text("Last 6 months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Chart(monthlyData, id: \.month) { item in
                BarMark(
                    x: .value("Month", monthFmt.string(from: item.month)),
                    y: .value("Amount", item.total)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.indigo.opacity(0.5), .indigo],
                        startPoint: .bottom, endPoint: .top
                    )
                )
                .cornerRadius(8)
                .annotation(position: .top) {
                    if item.total > 0 {
                        Text(item.total, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { val in
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text(v, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color(.separator).opacity(0.5))
                }
            }
            .chartXAxis {
                AxisMarks { AxisValueLabel() }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Category Breakdown (Donut + Legend)
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Month Breakdown")
                .font(.headline)

            if categoryData.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.pie")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        Text("No data for this month")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                HStack(alignment: .center, spacing: 24) {
                    // Donut chart
                    Chart(categoryData, id: \.cat) { item in
                        SectorMark(
                            angle: .value("Amount", item.total),
                            innerRadius: .ratio(0.58),
                            angularInset: 2.5
                        )
                        .foregroundStyle(item.cat.color)
                        .cornerRadius(5)
                    }
                    .frame(width: 130, height: 130)

                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categoryData, id: \.cat) { item in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.cat.color)
                                    .frame(width: 10, height: 10)
                                Text(item.cat.rawValue)
                                    .font(.caption)
                                Spacer()
                                Text(item.total, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                    .font(.caption.bold())
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Budget Section
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Monthly Budgets")
                    .font(.headline)
                Spacer()
                Button("Edit") { showingBudgets = true }
                    .font(.subheadline)
                    .foregroundStyle(.indigo)
            }

            let withBudgets = Category.allCases.filter { store.budget(for: $0) > 0 }

            if withBudgets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("No budgets set")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Set Budgets") { showingBudgets = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 14) {
                    ForEach(withBudgets) { cat in
                        BudgetProgressRow(
                            category: cat,
                            spent: store.total(period: .thisMonth, category: cat),
                            budget: store.budget(for: cat)
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Insights
    @ViewBuilder
    private var insightsSection: some View {
        let expenses = store.filtered(by: .thisMonth)
        if !expenses.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Quick Insights")
                    .font(.headline)

                VStack(spacing: 10) {
                    if let topCat = categoryData.first {
                        InsightRow(
                            icon: topCat.cat.icon,
                            color: topCat.cat.color,
                            text: "**\(topCat.cat.rawValue)** is your top category this month"
                        )
                    }
                    if let biggest = expenses.max(by: { $0.amount < $1.amount }) {
                        InsightRow(
                            icon: "arrow.up.circle.fill",
                            color: .orange,
                            text: "Largest single expense: **\(biggest.name)**"
                        )
                    }
                    if let change = store.monthOverMonthChange() {
                        let dir = change >= 0 ? "more" : "less"
                        let pct = String(format: "%.0f", abs(change * 100))
                        InsightRow(
                            icon: change >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                            color: change >= 0 ? .red : .green,
                            text: "Spending **\(pct)% \(dir)** than last month"
                        )
                    }
                }
            }
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 22))
        }
    }

    private var currencyCode: String { Locale.current.currency?.identifier ?? "USD" }
}

// MARK: - Budget Progress Row
struct BudgetProgressRow: View {
    let category: Category
    let spent: Double
    let budget: Double

    private var fraction: Double { min(spent / budget, 1.0) }
    private var statusColor: Color {
        fraction < 0.7 ? .green : fraction < 0.9 ? .orange : .red
    }

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Label(category.rawValue, systemImage: category.icon)
                    .font(.subheadline)
                    .foregroundStyle(category.color)
                Spacer()
                Group {
                    Text(spent, format: .currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(0)))
                        .foregroundStyle(statusColor)
                    Text(" / ")
                        .foregroundStyle(.secondary)
                    Text(budget, format: .currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(0)))
                        .foregroundStyle(.secondary)
                }
                .font(.caption.bold())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill)).frame(height: 8)
                    Capsule()
                        .fill(statusColor.gradient)
                        .frame(width: max(4, geo.size.width * fraction), height: 8)
                        .animation(.spring(duration: 0.7), value: fraction)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Insight Row
struct InsightRow: View {
    let icon: String
    let color: Color
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

// MARK: - Budget Settings View
struct BudgetSettingsView: View {
    @ObservedObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss
    @State private var budgetTexts: [String: String] = [:]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Category.allCases) { cat in
                        HStack(spacing: 12) {
                            Image(systemName: cat.icon)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(cat.color.gradient, in: RoundedRectangle(cornerRadius: 8))

                            Text(cat.rawValue)
                                .font(.body)

                            Spacer()

                            HStack(spacing: 4) {
                                Text(Locale.current.currencySymbol ?? "$")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                TextField("—", text: Binding(
                                    get: {
                                        if let t = budgetTexts[cat.rawValue] { return t }
                                        let b = store.budget(for: cat)
                                        return b > 0 ? String(format: "%.0f", b) : ""
                                    },
                                    set: { budgetTexts[cat.rawValue] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Set a monthly spending limit per category")
                        .textCase(nil)
                }
            }
            .navigationTitle("Monthly Budgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        for cat in Category.allCases {
                            if let text = budgetTexts[cat.rawValue] {
                                if let amount = Double(text), amount > 0 {
                                    store.setBudget(amount, for: cat)
                                } else if text.isEmpty {
                                    store.setBudget(0, for: cat)
                                }
                            }
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
