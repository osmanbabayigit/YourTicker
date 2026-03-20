import SwiftUI

// MARK: - Donut grafik (büyük)

struct BudgetDonutChart: View {
    let entries: [BudgetEntry]
    let categories: [BudgetCategory]

    @State private var selectedSlice: Int? = nil

    struct Slice: Identifiable {
        let id: Int
        let name: String
        let amount: Double
        let color: Color
        let startAngle: Angle
        let endAngle: Angle
    }

    var expenseByCategory: [(BudgetCategory?, Double)] {
        let expenses = entries.filter { $0.type == .expense }
        var dict: [UUID?: Double] = [:]
        for e in expenses { dict[e.category?.id, default: 0] += e.amount }
        return dict
            .map { (key, total) in (categories.first { $0.id == key }, total) }
            .sorted { $0.1 > $1.1 }
    }

    var totalExpense: Double { expenseByCategory.reduce(0) { $0 + $1.1 } }

    var slices: [Slice] {
        guard totalExpense > 0 else { return [] }
        var startAngle = Angle(degrees: -90)
        return expenseByCategory.enumerated().map { (i, item) in
            let pct = item.1 / totalExpense
            let sweep = Angle(degrees: pct * 360)
            let end = startAngle + sweep
            let color = item.0.map { Color(hex: $0.hexColor) } ?? Color.secondary
            let s = Slice(id: i, name: item.0?.name ?? "Diğer",
                         amount: item.1, color: color,
                         startAngle: startAngle, endAngle: end)
            startAngle = end
            return s
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gider dağılımı")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            if slices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary.opacity(0.3))
                    Text("Bu ay gider yok")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 16) {
                    // Donut — büyük
                    ZStack {
                        ForEach(slices) { slice in
                            DonutSliceShape(
                                startAngle: slice.startAngle,
                                endAngle: slice.endAngle,
                                innerRatio: 0.52
                            )
                            .fill(slice.color)
                            .opacity(selectedSlice == nil || selectedSlice == slice.id ? 1.0 : 0.3)
                            .scaleEffect(selectedSlice == slice.id ? 1.05 : 1.0)
                            .animation(.spring(response: 0.25), value: selectedSlice)
                            .onTapGesture {
                                selectedSlice = selectedSlice == slice.id ? nil : slice.id
                            }
                        }

                        VStack(spacing: 3) {
                            if let sel = selectedSlice,
                               let slice = slices.first(where: { $0.id == sel }) {
                                Text(slice.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Text(CurrencyHelper.format(slice.amount))
                                    .font(.system(size: 15, weight: .bold))
                                Text(String(format: "%.0f%%", (slice.amount / totalExpense) * 100))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Toplam gider")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                Text(CurrencyHelper.format(totalExpense))
                                    .font(.system(size: 15, weight: .bold))
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                                    .frame(maxWidth: 110)
                            }
                        }
                    }
                    .frame(width: 200, height: 200)
                    .frame(maxWidth: .infinity)

                    // Legend — iki sütun
                    let cols = Array(slices.prefix(8)).chunked(into: 2)
                    VStack(spacing: 0) {
                        ForEach(cols.indices, id: \.self) { rowIdx in
                            HStack(spacing: 0) {
                                ForEach(cols[rowIdx]) { slice in
                                    Button {
                                        selectedSlice = selectedSlice == slice.id ? nil : slice.id
                                    } label: {
                                        HStack(spacing: 6) {
                                            Circle().fill(slice.color).frame(width: 8, height: 8)
                                            Text(slice.name)
                                                .font(.system(size: 11))
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                            Spacer()
                                            Text(String(format: "%.0f%%", (slice.amount / totalExpense) * 100))
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .opacity(selectedSlice == nil || selectedSlice == slice.id ? 1.0 : 0.4)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity)
                                }
                                if cols[rowIdx].count == 1 {
                                    Spacer().frame(maxWidth: .infinity)
                                }
                            }
                            if rowIdx < cols.indices.last ?? 0 {
                                Divider().opacity(0.3)
                            }
                        }
                    }
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Array chunked yardımcı

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Donut dilim şekli

struct DonutSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRatio

        var path = Path()
        path.move(to: CGPoint(
            x: center.x + outerRadius * cos(CGFloat(startAngle.radians)),
            y: center.y + outerRadius * sin(CGFloat(startAngle.radians))
        ))
        path.addArc(center: center, radius: outerRadius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addLine(to: CGPoint(
            x: center.x + innerRadius * cos(CGFloat(endAngle.radians)),
            y: center.y + innerRadius * sin(CGFloat(endAngle.radians))
        ))
        path.addArc(center: center, radius: innerRadius,
                    startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}

// MARK: - Son 6 ay bar grafiği (büyük)

struct MonthlyBarChart: View {
    let entries: [BudgetEntry]

    struct MonthData: Identifiable {
        let id: Int
        let label: String
        let income: Double
        let expense: Double
    }

    var monthData: [MonthData] {
        let cal = Calendar.current
        let now = Date()
        return (0..<6).reversed().map { offset -> MonthData in
            guard let date = cal.date(byAdding: .month, value: -offset, to: now) else {
                return MonthData(id: offset, label: "", income: 0, expense: 0)
            }
            let me = entries.filter { cal.isDate($0.date, equalTo: date, toGranularity: .month) }
            return MonthData(
                id: offset,
                label: date.formatted(.dateTime.month(.abbreviated)),
                income:  me.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount },
                expense: me.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            )
        }
    }

    var maxValue: Double {
        monthData.map { max($0.income, $0.expense) }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Son 6 ay")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 12) {
                    legendDot(color: .green, label: "Gelir")
                    legendDot(color: .red,   label: "Gider")
                }
            }

            // Y ekseni + barlar
            HStack(alignment: .bottom, spacing: 0) {
                // Y ekseni etiketleri
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach([1.0, 0.5, 0.0], id: \.self) { pct in
                        Text(CurrencyHelper.format(maxValue * pct))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .frame(width: 55, alignment: .trailing)
                        if pct > 0 { Spacer() }
                    }
                }
                .frame(height: 120)

                // Barlar
                GeometryReader { geo in
                    let barGroupW = (geo.size.width) / CGFloat(monthData.count)
                    ZStack(alignment: .bottomLeading) {
                        // Grid lines
                        ForEach([0.0, 0.5, 1.0], id: \.self) { pct in
                            Rectangle()
                                .fill(Color.gray.opacity(0.12))
                                .frame(height: 0.5)
                                .offset(y: -geo.size.height * CGFloat(pct))
                        }

                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(monthData) { month in
                                VStack(spacing: 4) {
                                    HStack(alignment: .bottom, spacing: 4) {
                                        barColumn(value: month.income,  max: maxValue, height: geo.size.height, color: .green)
                                        barColumn(value: month.expense, max: maxValue, height: geo.size.height, color: .red)
                                    }
                                    Text(month.label)
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: barGroupW)
                            }
                        }
                    }
                }
                .frame(height: 140)
            }
            .padding(.leading, 4)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func barColumn(value: Double, max: Double, height: CGFloat, color: Color) -> some View {
        let barH = max > 0 ? CGFloat(value / max) * height : 0
        VStack(spacing: 2) {
            if value > 0 {
                Text(CurrencyHelper.format(value))
                    .font(.system(size: 7))
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(width: 36)
            } else {
                Spacer()
            }
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.75))
                .frame(width: 14, height: Swift.max(barH, value > 0 ? 3 : 0))
                .animation(.spring(response: 0.5), value: barH)
        }
    }

    @ViewBuilder
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }
}
