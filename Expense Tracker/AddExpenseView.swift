//
//  AddExpenseView.swift
//  saaaad
//

import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var store: ExpenseStore
    @Environment(\.dismiss) var dismiss

    var editingExpense: Expense? = nil

    @State private var name       = ""
    @State private var amountText = ""
    @State private var category: Category = .food
    @State private var date       = Date()
    @State private var note       = ""
    @State private var showError  = false

    private var isEditing: Bool { editingExpense != nil }

    init(store: ExpenseStore, editingExpense: Expense? = nil) {
        self.store = store
        self.editingExpense = editingExpense
        if let e = editingExpense {
            _name       = State(initialValue: e.name)
            _amountText = State(initialValue: String(e.amount))
            _category   = State(initialValue: e.category)
            _date       = State(initialValue: e.date)
            _note       = State(initialValue: e.note)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Name + Amount
                Section {
                    HStack(spacing: 14) {
                        // Animated category icon
                        Image(systemName: category.icon)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(category.color.gradient,
                                        in: RoundedRectangle(cornerRadius: 14))
                            .animation(.spring(duration: 0.3), value: category)

                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Expense name", text: $name)
                                .font(.headline)

                            HStack(spacing: 4) {
                                Text(Locale.current.currencySymbol ?? "$")
                                    .foregroundStyle(.secondary)
                                TextField("0.00", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Category Grid
                Section("Category") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Category.allCases) { cat in
                                CategoryChip(cat: cat, isSelected: category == cat)
                                    .onTapGesture {
                                        withAnimation(.spring(duration: 0.25)) { category = cat }
                                    }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                // Date
                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                // Note
                Section("Note") {
                    TextField("Add a note (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { submit() }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty || amountText.isEmpty)
                }
            }
            .alert("Invalid Input", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a name and a valid positive amount.")
            }
        }
    }

    private func submit() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let amount = Double(amountText), amount > 0 else {
            showError = true
            return
        }
        if var expense = editingExpense {
            expense.name     = name
            expense.amount   = amount
            expense.category = category
            expense.date     = date
            expense.note     = note
            store.update(expense)
        } else {
            store.add(Expense(name: name, amount: amount, category: category, date: date, note: note))
        }
        dismiss()
    }
}

private struct CategoryChip: View {
    let cat: Category
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: cat.icon)
                .font(.title3)
                .foregroundStyle(isSelected ? .white : cat.color)
                .frame(width: 48, height: 48)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? AnyShapeStyle(cat.color.gradient) : AnyShapeStyle(cat.color.opacity(0.12)))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? cat.color : .clear, lineWidth: 2)
                }
                .shadow(color: isSelected ? cat.color.opacity(0.4) : .clear, radius: 6, y: 3)

            Text(cat.rawValue)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
        }
    }
}
