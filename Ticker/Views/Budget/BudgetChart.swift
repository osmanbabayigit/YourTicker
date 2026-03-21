import SwiftUI

// MARK: - Donut Chart

struct BudgetDonutChart: View {
    let entries: [BudgetEntry]
    let categories: [BudgetCategory]
    @State private var selectedSlice: String? = nil
    @State private var appear = false

    private var expenseEntries: [BudgetEntry] { entries.filter { $0.type == .expense } }
    private var totalExpense: Double { expenseEntries.reduce(0) { $0 + $1.amount } }

    private struct SliceData: Identifiable {
        let id: String
        let name: String
        let amount: Double
        let color: Color
        let percent: Double
        var startAngle: Angle
        var endAngle: Angle
    }

    private var slices: [SliceData] {
        guard totalExpense > 0 else { return [] }
        var grouped: [(String, Double, Color)] = []
        var map: [String: (Double, Color)] = [:]

        for entry in expenseEntries {
            let key  = entry.category?.name ?? "Diğer"
            let color = entry.category.map { Color(hex: $0.hexColor) } ?? TickerTheme.textTertiary
            map[key, default: (0, color)].0 += entry.amount
            map[key, default: (0, color)].1 = color
        }
        grouped = map.map { ($0.key, $0.value.0, $0.value.1) }
            .sorted { $0.1 > $1.1 }

        var result: [SliceData] = []
        var current = Angle(degrees: -90)
        for (name, amount, color) in grouped {
            let sweep = Angle(degrees: 360 * amount / totalExpense)
            let pct   = amount / totalExpense * 100
            result.append(SliceData(
                id: name, name: name, amount: amount,
                color: color, percent: pct,
                startAngle: current, endAngle: current + sweep
            ))
            current += sweep
        }
        return result
    }

    var body: some View {
        if slices.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundStyle(TickerTheme.textTertiary)
                Text("Gider yok")
                    .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 20)
        } else {
            VStack(spacing: 14) {
                // Donut
                ZStack {
                    ForEach(slices) { slice in
                        DonutSliceShape(
                            startAngle: slice.startAngle,
                            endAngle: appear ? slice.endAngle : slice.startAngle
                        )
                        .fill(slice.color.opacity(selectedSlice == slice.id ? 1.0 : 0.7))
                        .scaleEffect(selectedSlice == slice.id ? 1.06 : 1.0)
                        .shadow(color: selectedSlice == slice.id
                                ? slice.color.opacity(0.4) : .clear,
                                radius: 6)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(slices.firstIndex(where: { $0.id == slice.id }) ?? 0) * 0.05),
                            value: appear
                        )
                        .animation(.spring(response: 0.25), value: selectedSlice)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25)) {
                                selectedSlice = selectedSlice == slice.id ? nil : slice.id
                            }
                        }
                    }

                    // Merkez içerik
                    VStack(spacing: 3) {
                        if let id = selectedSlice, let s = slices.first(where: { $0.id == id }) {
                            Text(s.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(TickerTheme.textSecondary)
                                .lineLimit(1).transition(.scale.combined(with: .opacity))
                            Text(CurrencyHelper.format(s.amount))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(s.color).transition(.scale.combined(with: .opacity))
                            Text("%\(Int(s.percent))")
                                .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                                .transition(.opacity)
                        } else {
                            Text("Toplam gider")
                                .font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
                            Text(CurrencyHelper.format(totalExpense))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(TickerTheme.textPrimary)
                                .minimumScaleFactor(0.7).lineLimit(1)
                        }
                    }
                    .animation(.spring(response: 0.25), value: selectedSlice)
                }
                .frame(width: 170, height: 170)
                .onAppear {
                    withAnimation { appear = true }
                }

                // Lejant
                VStack(spacing: 5) {
                    ForEach(slices) { slice in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                selectedSlice = selectedSlice == slice.id ? nil : slice.id
                            }
                        } label: {
                            HStack(spacing: 7) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(slice.color)
                                    .frame(width: 10, height: 10)
                                Text(slice.name)
                                    .font(.system(size: 11))
                                    .foregroundStyle(selectedSlice == slice.id
                                                     ? TickerTheme.textPrimary : TickerTheme.textSecondary)
                                    .lineLimit(1)
                                Spacer()
                                Text("%\(Int(slice.percent))")
                                    .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                                Text(CurrencyHelper.format(slice.amount))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(selectedSlice == slice.id
                                                     ? slice.color : TickerTheme.textSecondary)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(selectedSlice == slice.id
                                        ? slice.color.opacity(0.08) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Donut slice shape

struct DonutSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    let innerRatio: CGFloat = 0.52
    let gap: CGFloat = 1.5

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set { startAngle = .degrees(newValue.first); endAngle = .degrees(newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = Swift.min(rect.width, rect.height) / 2 - gap
        let innerR = outerR * innerRatio
        let gapAngle = Angle(degrees: gap / outerR * 180 / .pi)

        let s = startAngle + gapAngle
        let e = endAngle - gapAngle
        guard e > s else { return Path() }

        var path = Path()
        path.addArc(center: center, radius: outerR, startAngle: s, endAngle: e, clockwise: false)
        path.addArc(center: center, radius: innerR, startAngle: e, endAngle: s, clockwise: true)
        path.closeSubpath()
        return path
    }
}

// MARK: - Bar Chart

struct MonthlyBarChart: View {
    let entries: [BudgetEntry]
    @State private var appear = false
    @State private var hoveredMonth: String? = nil

    private struct MonthData: Identifiable {
        let id: String
        let label: String
        let income: Double
        let expense: Double
        var balance: Double { income - expense }
    }

    private var data: [MonthData] {
        let cal = Calendar.current
        let today = Date()
        return (0..<6).reversed().map { offset -> MonthData in
            let date  = cal.date(byAdding: .month, value: -offset, to: today)!
            let label = date.formatted(.dateTime.month(.abbreviated))
            let month = entries.filter {
                cal.isDate($0.date, equalTo: date, toGranularity: .month)
            }
            let inc = month.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount }
            let exp = month.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return MonthData(id: label, label: label, income: inc, expense: exp)
        }
    }

    private var maxVal: Double {
        Swift.max(data.flatMap { [$0.income, $0.expense] }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(spacing: 10) {
            // Lejant
            HStack(spacing: 14) {
                legendItem(color: TickerTheme.green, label: "Gelir")
                legendItem(color: TickerTheme.red,   label: "Gider")
                Spacer()
            }

            // Barlar
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data) { month in
                    VStack(spacing: 4) {
                        // Tooltip
                        if hoveredMonth == month.id {
                            VStack(spacing: 1) {
                                if month.income > 0 {
                                    Text(CurrencyHelper.format(month.income))
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundStyle(TickerTheme.green)
                                }
                                if month.expense > 0 {
                                    Text(CurrencyHelper.format(month.expense))
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundStyle(TickerTheme.red)
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                        }

                        // Bar grubu
                        HStack(alignment: .bottom, spacing: 2) {
                            barView(value: month.income, max: maxVal, color: TickerTheme.green)
                            barView(value: month.expense, max: maxVal, color: TickerTheme.red)
                        }

                        Text(month.label)
                            .font(.system(size: 9)).foregroundStyle(
                                hoveredMonth == month.id
                                ? TickerTheme.textSecondary : TickerTheme.textTertiary
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .onHover { isHov in
                        withAnimation(.easeOut(duration: 0.15)) {
                            hoveredMonth = isHov ? month.id : nil
                        }
                    }
                }
            }
            .frame(height: 90)
            .onAppear { withAnimation(.spring(response: 0.6)) { appear = true } }
        }
    }

    @ViewBuilder
    private func barView(value: Double, max: Double, color: Color) -> some View {
        let targetH: CGFloat = value > 0 ? CGFloat(value / max) * 76 + 4 : 2
        let h = appear ? targetH : 2

        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 3)
                .fill(value > 0
                      ? color.opacity(hoveredMonth != nil ? 0.5 : 0.75)
                      : TickerTheme.bgPill)
                .frame(width: 12, height: h)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: h)
    }

    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
            Text(label).font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
        }
    }
}

// MARK: - Array extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
