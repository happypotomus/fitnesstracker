//
//  CalendarViewModel.swift
//  FitnessTracker
//
//  Manages calendar state for monthly view
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date?
    @Published var datesWithData: Set<Date> = []

    private let calendar = Calendar.current

    // MARK: - Computed Properties

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var currentDate = monthFirstWeek.start

        // Generate 42 days (6 weeks) to fill calendar grid
        for _ in 0..<42 {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return days
    }

    // MARK: - Navigation

    func goToPreviousMonth() {
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else {
            return
        }
        currentMonth = previousMonth
    }

    func goToNextMonth() {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
            return
        }
        currentMonth = nextMonth
    }

    func goToToday() {
        currentMonth = Date()
        selectedDate = Date()
    }

    // MARK: - Date Selection

    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func clearSelection() {
        selectedDate = nil
    }

    // MARK: - Date Helpers

    func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }

    func isSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }

    func isInCurrentMonth(_ date: Date) -> Bool {
        return calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    func hasData(_ date: Date) -> Bool {
        return datesWithData.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    func dayNumber(_ date: Date) -> Int {
        return calendar.component(.day, from: date)
    }

    // MARK: - Data Management

    func updateDatesWithData(_ dates: [Date]) {
        // Store dates normalized to start of day for comparison
        datesWithData = Set(dates.map { calendar.startOfDay(for: $0) })
    }
}
