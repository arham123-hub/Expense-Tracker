//
//  ExpenseListView.swift
//  saaaad
//

import SwiftUI

struct ExpenseListView: View {
    @ObservedObject var store: ExpenseStore
    @State private var searchText = ""
    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var showingAdd = false
    @State private var editingExpense: Expense? = nil
    @State private var exportItem: CSVFile? = nil

    private var filteredExpenses: [Expense] {
        let base = store.filtered(by: selectedPeriod).sorted { $0.date > $1.date }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.note.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedExpenses: [(key: String, items: [Expense])] {
        let calendar = Calendar.current
        let df = DateFormatter()
        df.dateStyle = .medium

        let dict = Dictionary(grouping: filteredExpenses) { expense -> String in
            if calendar.isDateInToday(expense.date)     { return "Today" }
            if calendar.isDateInYesterday(expense.date) { return "Yesterday" }
            return df.string(from: expense.date)
        }

        return dict.map { (key: $0.key, items: $0.value) }
            .sorted { a, b in
                if a.key == "Today"     { return true }
                if b.key == "Today"     { return false }
                if a.key == "Yesterday" { return true }
                if b.key == "Yesterday" { return false }
                return a.key > b.key
            }
    }

    private var periodTotal: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Period + total header
                VStack(spacing: 10) {
                    periodPicker
                    if !filteredExpenses.isEmpty {
                        HStack {
                            Text("\(filteredExpenses.count) expense\(filteredExpenses.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(periodTotal, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .font(.subheadline.bold())
                                .foregroundStyle(.indigo)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 10)
                .background(Color(.systemBackground))

                if filteredExpenses.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedExpenses, id: \.key) { section in
                            Section(section.key) {
                                ForEach(section.items) { expense in
                                    ExpenseRow(expense: expense)
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                editingExpense = expense
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.indigo)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                withAnimation { store.delete(expense) }
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Expenses")
            .searchable(text: $searchText, prompt: "Search by name, category…")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        exportItem = CSVFile(data: store.csvData(for: selectedPeriod))
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(filteredExpenses.isEmpty)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddExpenseView(store: store)
            }
            .sheet(item: $editingExpense) { expense in
                AddExpenseView(store: store, editingExpense: expense)
            }
            .shareSheet(item: $exportItem)
        }
    }

    // MARK: Period Picker
    private var periodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimePeriod.allCases) { period in
                    Button {
                        withAnimation(.spring(duration: 0.3)) { selectedPeriod = period }
                    } label: {
                        Text(period.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedPeriod == period ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedPeriod == period
                                    ? Color.indigo
                                    : Color(.secondarySystemFill),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedPeriod == period ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "tray.fill" : "magnifyingglass")
                .font(.system(size: 52))
                .foregroundStyle(.quaternary)
            Text(searchText.isEmpty ? "No Expenses" : "No Results")
                .font(.title3.bold())
            Text(searchText.isEmpty ? "Tap + to record an expense" : "Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - CSV Export Support

struct CSVFile: Identifiable, Transferable {
    let id = UUID()
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { $0.data }
    }
}

extension View {
    func shareSheet(item: Binding<CSVFile?>) -> some View {
        sheet(item: item) { file in
            ShareSheet(data: file.data, fileName: "expenses.csv")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let fileName: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
