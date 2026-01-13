//
//  CalendarView.swift
//  FitnessTracker
//
//  Reusable monthly calendar component with date selection
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let accentColor: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 16) {
            // Header: Month/Year with navigation
            HStack {
                Button(action: {
                    viewModel.goToPreviousMonth()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(accentColor)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text(viewModel.monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    viewModel.goToNextMonth()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(accentColor)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)

            // Week day labels
            HStack(spacing: 8) {
                ForEach(weekDays.indices, id: \.self) { index in
                    Text(weekDays[index])
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Date grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.daysInMonth.indices, id: \.self) { index in
                    if let date = viewModel.daysInMonth[index] {
                        DateCell(
                            date: date,
                            isInCurrentMonth: viewModel.isInCurrentMonth(date),
                            isToday: viewModel.isToday(date),
                            isSelected: viewModel.isSelected(date),
                            hasData: viewModel.hasData(date),
                            dayNumber: viewModel.dayNumber(date),
                            accentColor: accentColor,
                            onTap: {
                                viewModel.selectDate(date)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
}

// MARK: - Date Cell

struct DateCell: View {
    let date: Date
    let isInCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let hasData: Bool
    let dayNumber: Int
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle
                if hasData {
                    // Green circle for dates with data
                    Circle()
                        .fill(Color.green)
                } else if isSelected {
                    // Accent color for selected dates without data
                    Circle()
                        .fill(accentColor.opacity(0.2))
                }

                // Selected ring overlay
                if isSelected && hasData {
                    Circle()
                        .strokeBorder(accentColor, lineWidth: 2)
                }

                Text("\(dayNumber)")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(textColor)
            }
            .frame(height: 44)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var textColor: Color {
        if !isInCurrentMonth {
            return .secondary.opacity(0.5)
        } else if hasData {
            // White text on green background
            return .white
        } else if isToday {
            return accentColor
        } else {
            return .primary
        }
    }
}
