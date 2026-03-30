//
//  ContentView.swift
//  saaaad
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = ExpenseStore()
    @State private var showingAdd = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        TabView {
            DashboardView(store: store, showingAdd: $showingAdd)
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

            ExpenseListView(store: store)
                .tabItem { Label("Expenses", systemImage: "list.bullet.rectangle.portrait.fill") }

            AnalyticsView(store: store)
                .tabItem { Label("Analytics", systemImage: "chart.bar.xaxis.ascending") }
        }
        .tint(.indigo)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showingAdd) {
            AddExpenseView(store: store)
        }
    }
}

// MARK: - Shared: Expense Row
struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: expense.category.icon)
                .font(.title3)
                .foregroundStyle(expense.category.color)
                .frame(width: 40, height: 40)
                .background(expense.category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.body)
                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(expense.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.body.bold())
                if !expense.note.isEmpty {
                    Text(expense.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    ContentView()
}
