//
//  DashboardView.swift
//  saaaad
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: ExpenseStore
    @Binding var showingAdd: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false

    private var recentExpenses: [Expense] {
        store.expenses.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }
    private var thisMonthTotal: Double { store.total(period: .thisMonth) }
    private var change: Double? { store.monthOverMonthChange() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    statsRow
                    topCategories
                    recentSection
                }
                .padding()
                .padding(.bottom, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { isDarkMode.toggle() }
                    } label: {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
    }

    // MARK: Hero Card
    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.35, green: 0.25, blue: 0.95),
                                 Color(red: 0.65, green: 0.25, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Decorative circles
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 180)
                .offset(x: 100, y: -50)
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 120)
                .offset(x: -120, y: 60)

            VStack(spacing: 10) {
                Text("TOTAL THIS MONTH")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.7))

                Text(thisMonthTotal, format: .currency(code: currencyCode))
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if let change {
                    HStack(spacing: 5) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.bold())
                        Text("\(abs(change * 100), specifier: "%.1f")% vs last month")
                            .font(.caption)
                    }
                    .foregroundStyle(change >= 0 ? Color(red: 1, green: 0.6, blue: 0.6) : Color(red: 0.6, green: 1, blue: 0.7))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.15), in: Capsule())
                }
            }
            .padding(.vertical, 36)
            .padding(.horizontal, 24)
        }
        .clipped()
    }

    // MARK: Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Daily Avg",
                value: store.dailyAverage(period: .thisMonth),
                isCurrency: true,
                icon: "calendar.badge.clock",
                color: .blue
            )
            StatCard(
                title: "Transactions",
                value: Double(store.filtered(by: .thisMonth).count),
                isCurrency: false,
                icon: "arrow.left.arrow.right",
                color: .purple
            )
            if let biggest = store.filtered(by: .thisMonth).max(by: { $0.amount < $1.amount }) {
                StatCard(
                    title: "Largest",
                    value: biggest.amount,
                    isCurrency: true,
                    icon: "arrow.up.circle.fill",
                    color: .orange
                )
            } else {
                StatCard(
                    title: "Largest",
                    value: 0,
                    isCurrency: true,
                    icon: "arrow.up.circle.fill",
                    color: .orange
                )
            }
        }
    }

    // MARK: Top Categories
    private var topCategories: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Spending by Category")
                .font(.headline)

            let grand = thisMonthTotal
            let cats = Category.allCases
                .map { (cat: $0, total: store.total(period: .thisMonth, category: $0)) }
                .filter { $0.total > 0 }
                .sorted { $0.total > $1.total }

            if cats.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        Text("No expenses this month")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(cats.prefix(5), id: \.cat) { item in
                        CategoryBarRow(category: item.cat, total: item.total, grandTotal: grand)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Recent
    @ViewBuilder
    private var recentSection: some View {
        if !recentExpenses.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Expenses")
                    .font(.headline)

                VStack(spacing: 0) {
                    ForEach(recentExpenses) { expense in
                        ExpenseRow(expense: expense)
                        if expense.id != recentExpenses.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: Double
    let isCurrency: Bool
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

            if isCurrency {
                Text(value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            } else {
                Text(Int(value).description)
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Category Bar Row
struct CategoryBarRow: View {
    let category: Category
    let total: Double
    let grandTotal: Double

    private var fraction: Double { grandTotal > 0 ? min(total / grandTotal, 1) : 0 }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(category.color)
                    .frame(width: 18)
                Text(category.rawValue)
                    .font(.subheadline)
                Spacer()
                Text(total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline.bold())
                Text("· \(Int(fraction * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(height: 7)
                    Capsule()
                        .fill(category.color.gradient)
                        .frame(width: max(4, geo.size.width * fraction), height: 7)
                        .animation(.spring(duration: 0.6), value: fraction)
                }
            }
            .frame(height: 7)
        }
    }
}
