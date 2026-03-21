import SwiftUI
import SwiftData

struct GoalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Goal.sortOrder) private var goals: [Goal]
    @Query private var tasks: [TaskItem]

    @State private var selectedStatus: GoalStatus? = .active
    @State private var showingAddGoal = false
    @State private var selectedGoal: Goal? = nil

    private var filtered: [Goal] {
        guard let s = selectedStatus else { return goals }
        return goals.filter { $0.status == s }
    }

    private var activeCount:    Int { goals.filter { $0.status == .active    }.count }
    private var completedCount: Int { goals.filter { $0.status == .completed }.count }

    var body: some View {
        HSplitView {
            // Sol: Hedef listesi
            leftPanel
                .frame(minWidth: 300, maxWidth: 380)

            // Sağ: Detay
            if let goal = selectedGoal {
                GoalDetailView(goal: goal, tasks: tasks) {
                    selectedGoal = nil
                }
            } else {
                emptyDetail
            }
        }
        .background(TickerTheme.bgApp)
        .sheet(isPresented: $showingAddGoal) { AddGoalView() }
    }

    // MARK: - Sol panel

    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text("Hedefler")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)

                Spacer()

                Button { showingAddGoal = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color(hex: "#A78BFA"))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Filtreler
            HStack(spacing: 4) {
                filterChip(label: "Aktif", count: activeCount, status: .active)
                filterChip(label: "Tamamlandı", count: completedCount, status: .completed)
                filterChip(label: "Tümü", count: goals.count, status: nil)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            // Liste
            if filtered.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "target")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(TickerTheme.textTertiary)
                    Text("Henüz hedef yok")
                        .font(.system(size: 13)).foregroundStyle(TickerTheme.textSecondary)
                    Text("+ butonuna basarak başla")
                        .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(filtered) { goal in
                            GoalCard(goal: goal, isSelected: selectedGoal?.id == goal.id)
                                .onTapGesture { selectedGoal = goal }
                                .contextMenu { goalContextMenu(goal) }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .background(TickerTheme.bgSidebar)
    }

    @ViewBuilder
    private func filterChip(label: String, count: Int, status: GoalStatus?) -> some View {
        let isSelected = selectedStatus == status
        Button { selectedStatus = status } label: {
            HStack(spacing: 4) {
                Text(label).font(.system(size: 11, weight: .medium))
                Text("\(count)").font(.system(size: 10)).opacity(0.6)
            }
            .foregroundStyle(isSelected ? Color(hex: "#A78BFA") : TickerTheme.textTertiary)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(isSelected ? Color(hex: "#A78BFA").opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: isSelected)
    }

    @ViewBuilder
    private func goalContextMenu(_ goal: Goal) -> some View {
        Button {
            goal.status = goal.status == .completed ? .active : .completed
            try? context.save()
        } label: {
            Label(goal.status == .completed ? "Aktif'e Al" : "Tamamlandı İşaretle",
                  systemImage: goal.status == .completed ? "arrow.uturn.left" : "checkmark.seal")
        }
        Button {
            goal.status = .archived
            try? context.save()
        } label: { Label("Arşivle", systemImage: "archivebox") }
        Divider()
        Button(role: .destructive) {
            context.delete(goal); try? context.save()
            if selectedGoal?.id == goal.id { selectedGoal = nil }
        } label: { Label("Sil", systemImage: "trash") }
    }

    // MARK: - Boş detay

    private var emptyDetail: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "target")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(TickerTheme.textTertiary)
            Text("Bir hedef seç")
                .font(.system(size: 14)).foregroundStyle(TickerTheme.textSecondary)
            Text("Soldan bir hedef seçerek\nmilestone'larını yönet")
                .font(.system(size: 11)).foregroundStyle(TickerTheme.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(TickerTheme.bgApp)
    }
}

// MARK: - Hedef kartı (liste)

struct GoalCard: View {
    @Bindable var goal: Goal
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                // Emoji + renk
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(hex: goal.hexColor).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Text(goal.emoji).font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TickerTheme.textPrimary).lineLimit(1)

                    HStack(spacing: 6) {
                        if let days = goal.daysLeft {
                            Text(days >= 0 ? "\(days) gün kaldı" : "\(abs(days)) gün geçti")
                                .font(.system(size: 10))
                                .foregroundStyle(days < 0 ? TickerTheme.red :
                                                 days < 7 ? TickerTheme.orange : TickerTheme.textTertiary)
                        }
                        if goal.totalMilestones > 0 {
                            Text("·").foregroundStyle(TickerTheme.textTertiary)
                            Text("\(goal.completedMilestones)/\(goal.totalMilestones)")
                                .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                        }
                    }
                }

                Spacer()

                // Yüzde
                Text("\(Int(goal.progressPercent * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: goal.hexColor))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(TickerTheme.bgPill).frame(height: 4)
                    Capsule()
                        .fill(Color(hex: goal.hexColor))
                        .frame(width: geo.size.width * goal.progressPercent, height: 4)
                        .animation(.spring(response: 0.5), value: goal.progressPercent)
                }
            }
            .frame(height: 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected
                      ? Color(hex: goal.hexColor).opacity(0.08)
                      : isHovered ? TickerTheme.bgCardHover : TickerTheme.bgCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected
                        ? Color(hex: goal.hexColor).opacity(0.25)
                        : TickerTheme.borderSub, lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Hedef Detay

struct GoalDetailView: View {
    @Bindable var goal: Goal
    let tasks: [TaskItem]
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @State private var newMilestoneText = ""
    @State private var isEditingGoal = false
    @FocusState private var milestoneFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            detailHeader
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            progressSection
            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)
            milestoneSection
        }
        .background(TickerTheme.bgApp)
        .sheet(isPresented: $isEditingGoal) { EditGoalView(goal: goal) }
    }

    // MARK: - Header

    private var detailHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: goal.hexColor).opacity(0.15))
                    .frame(width: 48, height: 48)
                Text(goal.emoji).font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(TickerTheme.textPrimary)

                HStack(spacing: 8) {
                    // Durum pill
                    Text(goal.status.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(goal.status.color)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(goal.status.color.opacity(0.1))
                        .clipShape(Capsule())

                    if let days = goal.daysLeft {
                        Text(days >= 0 ? "\(days) gün kaldı" : "\(abs(days)) gün geçti")
                            .font(.system(size: 10))
                            .foregroundStyle(days < 0 ? TickerTheme.red :
                                             days < 7 ? TickerTheme.orange : TickerTheme.textTertiary)
                    }

                    if let target = goal.targetDate {
                        Text(target, format: .dateTime.day().month(.abbreviated).year())
                            .font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Button { isEditingGoal = true } label: {
                    Image(systemName: "pencil").font(.system(size: 11))
                        .foregroundStyle(TickerTheme.textTertiary)
                        .padding(6).background(TickerTheme.bgPill)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
    }

    // MARK: - Progress

    private var progressSection: some View {
        HStack(spacing: 12) {
            // Büyük yüzde
            VStack(spacing: 2) {
                Text("\(Int(goal.progressPercent * 100))%")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(hex: goal.hexColor))
                Text("tamamlandı").font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
            }
            .frame(width: 80)

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color(hex: goal.hexColor).opacity(0.1), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: goal.progressPercent)
                    .stroke(Color(hex: goal.hexColor),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5), value: goal.progressPercent)
            }
            .frame(width: 56, height: 56)

            Spacer()

            // Milestone sayısı
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(goal.completedMilestones)/\(goal.totalMilestones)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Text("adım").font(.system(size: 10)).foregroundStyle(TickerTheme.textTertiary)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
    }

    // MARK: - Milestone'lar

    private var milestoneSection: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "list.bullet").font(.system(size: 9))
                    Text("Adımlar").font(.system(size: 10, weight: .medium)).kerning(0.3)
                }
                .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 3) {
                    ForEach(goal.sortedMilestones) { milestone in
                        MilestoneRow(milestone: milestone, accentColor: Color(hex: goal.hexColor))
                            .contextMenu {
                                Button(role: .destructive) {
                                    context.delete(milestone)
                                    try? context.save()
                                } label: { Label("Sil", systemImage: "trash") }
                            }
                    }

                    // Yeni milestone ekleme
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: goal.hexColor).opacity(0.6))

                        TextField("Yeni adım ekle...", text: $newMilestoneText)
                            .textFieldStyle(.plain).font(.system(size: 13))
                            .foregroundStyle(TickerTheme.textPrimary)
                            .focused($milestoneFocused)
                            .onSubmit { addMilestone() }

                        if !newMilestoneText.isEmpty {
                            Button("Ekle") { addMilestone() }
                                .buttonStyle(.plain).font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: goal.hexColor))
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(TickerTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(TickerTheme.borderSub, lineWidth: 1))
                    .padding(.top, 6)
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
    }

    private func addMilestone() {
        let trimmed = newMilestoneText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let order = (goal.milestones.map { $0.sortOrder }.max() ?? -1) + 1
        let ms = GoalMilestone(title: trimmed, sortOrder: order)
        ms.goal = goal
        context.insert(ms)
        try? context.save()
        newMilestoneText = ""
        milestoneFocused = true
    }
}

// MARK: - Milestone satırı

struct MilestoneRow: View {
    @Bindable var milestone: GoalMilestone
    let accentColor: Color
    @Environment(\.modelContext) private var context
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3)) {
                    milestone.isCompleted.toggle()
                    milestone.completedAt = milestone.isCompleted ? Date() : nil
                }
                try? context.save()
            } label: {
                ZStack {
                    Circle()
                        .fill(milestone.isCompleted ? accentColor : Color.clear)
                        .frame(width: 18, height: 18)
                    Circle()
                        .strokeBorder(milestone.isCompleted ? accentColor : TickerTheme.borderMid,
                                      lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if milestone.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .heavy)).foregroundStyle(.white)
                    }
                }
                .contentTransition(.symbolEffect(.replace.downUp))
            }
            .buttonStyle(.plain)

            Text(milestone.title)
                .font(.system(size: 13))
                .foregroundStyle(milestone.isCompleted ? TickerTheme.textTertiary : TickerTheme.textPrimary)
                .strikethrough(milestone.isCompleted, color: TickerTheme.textTertiary)
                .lineLimit(2)

            Spacer()

            if milestone.isCompleted, let date = milestone.completedAt {
                Text(date, format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 9)).foregroundStyle(TickerTheme.textTertiary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(milestone.isCompleted
                      ? Color.clear
                      : isHovered ? TickerTheme.bgCardHover : Color.clear)
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Hedef ekleme

struct AddGoalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var goals: [Goal]

    @State private var title = ""
    @State private var emoji = "🎯"
    @State private var hexColor = "#A78BFA"
    @State private var hasTargetDate = false
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var notes = ""
    @State private var showingEmojiPicker = false
    @FocusState private var titleFocused: Bool

    private let colorOptions = [
        "#A78BFA","#3B82F6","#34D399","#FB923C",
        "#F472B6","#FBBF24","#2DD4BF","#F87171"
    ]

    private let emojiOptions = [
        "🎯","🚀","💪","📖","💰","🏃","🎨","💻",
        "🌟","❤️","🎵","✈️","🏠","🎓","🌱","⚡"
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(emoji).font(.system(size: 20))
                Text("Yeni Hedef")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12))
                    .foregroundStyle(TickerTheme.textTertiary)
                Button("Ekle") { save() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: hexColor))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(hex: hexColor).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    // Başlık
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Hedef Adı", icon: "target")
                        TextField("Hedefini yaz...", text: $title)
                            .textFieldStyle(.plain).font(.system(size: 14))
                            .foregroundStyle(TickerTheme.textPrimary).focused($titleFocused)
                            .padding(10).background(TickerTheme.bgPill)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Emoji
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Emoji", icon: "face.smiling")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { e in
                                Button { emoji = e } label: {
                                    Text(e).font(.system(size: 20))
                                        .frame(width: 36, height: 36)
                                        .background(emoji == e
                                                    ? Color(hex: hexColor).opacity(0.15) : TickerTheme.bgPill)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8)
                                            .stroke(emoji == e ? Color(hex: hexColor).opacity(0.3) : Color.clear, lineWidth: 1))
                                }
                                .buttonStyle(.plain).animation(.spring(response: 0.2), value: emoji)
                            }
                        }
                    }
                    .padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Renk
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Renk", icon: "circle.hexagongrid")
                        HStack(spacing: 8) {
                            ForEach(colorOptions, id: \.self) { hex in
                                Button { hexColor = hex } label: {
                                    ZStack {
                                        Circle().fill(Color(hex: hex)).frame(width: 24, height: 24)
                                        if hexColor == hex {
                                            Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2).frame(width: 24, height: 24)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 8, weight: .heavy)).foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain).animation(.spring(response: 0.15), value: hexColor)
                            }
                        }
                    }
                    .padding(18)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Hedef tarihi
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            sectionLabel("Hedef Tarihi", icon: "calendar")
                            Spacer()
                            Toggle("", isOn: $hasTargetDate)
                                .labelsHidden().toggleStyle(.switch).controlSize(.small)
                        }
                        if hasTargetDate {
                            DatePicker("", selection: $targetDate, displayedComponents: .date)
                                .labelsHidden().colorScheme(.dark)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(18)
                    .animation(.spring(response: 0.25), value: hasTargetDate)

                    Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

                    // Notlar
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Notlar", icon: "note.text")
                        TextField("Opsiyonel not...", text: $notes)
                            .textFieldStyle(.plain).font(.system(size: 13))
                            .foregroundStyle(TickerTheme.textSecondary)
                            .padding(9).background(TickerTheme.bgPill)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .padding(18)
                }
            }
        }
        .frame(width: 420)
        .background(Color(hex: "#161618"))
        .onAppear { titleFocused = true }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium)).kerning(0.3)
        }
        .foregroundStyle(TickerTheme.textTertiary).textCase(.uppercase)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let order = (goals.map { $0.sortOrder }.max() ?? -1) + 1
        let goal = Goal(
            title: trimmed, emoji: emoji,
            hexColor: hexColor,
            targetDate: hasTargetDate ? targetDate : nil,
            notes: notes
        )
        goal.sortOrder = order
        context.insert(goal)
        try? context.save()
        dismiss()
    }
}

// MARK: - Hedef düzenleme

struct EditGoalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var goal: Goal

    @State private var title: String
    @State private var emoji: String
    @State private var hexColor: String
    @State private var hasTargetDate: Bool
    @State private var targetDate: Date
    @State private var notes: String

    init(goal: Goal) {
        self.goal = goal
        _title = State(initialValue: goal.title)
        _emoji = State(initialValue: goal.emoji)
        _hexColor = State(initialValue: goal.hexColor)
        _hasTargetDate = State(initialValue: goal.targetDate != nil)
        _targetDate = State(initialValue: goal.targetDate ?? Date())
        _notes = State(initialValue: goal.notes)
    }

    private let colorOptions = [
        "#A78BFA","#3B82F6","#34D399","#FB923C",
        "#F472B6","#FBBF24","#2DD4BF","#F87171"
    ]
    private let emojiOptions = [
        "🎯","🚀","💪","📖","💰","🏃","🎨","💻",
        "🌟","❤️","🎵","✈️","🏠","🎓","🌱","⚡"
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(emoji).font(.system(size: 18))
                Text("Hedefi Düzenle")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(TickerTheme.textPrimary)
                Spacer()
                Button("İptal") { dismiss() }
                    .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(TickerTheme.textTertiary)
                Button("Kaydet") { save() }
                    .buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: hexColor))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(hex: hexColor).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 18).padding(.vertical, 14)

            Rectangle().fill(TickerTheme.borderSub).frame(height: 1)

            VStack(spacing: 14) {
                TextField("Hedef adı", text: $title)
                    .textFieldStyle(.plain).font(.system(size: 14))
                    .foregroundStyle(TickerTheme.textPrimary)
                    .padding(10).background(TickerTheme.bgPill)
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 6) {
                    ForEach(emojiOptions, id: \.self) { e in
                        Button { emoji = e } label: {
                            Text(e).font(.system(size: 18))
                                .frame(width: 32, height: 32)
                                .background(emoji == e ? Color(hex: hexColor).opacity(0.15) : TickerTheme.bgPill)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(colorOptions, id: \.self) { hex in
                        Button { hexColor = hex } label: {
                            ZStack {
                                Circle().fill(Color(hex: hex)).frame(width: 24, height: 24)
                                if hexColor == hex {
                                    Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2).frame(width: 24, height: 24)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    Text("Hedef tarihi").font(.system(size: 12)).foregroundStyle(TickerTheme.textSecondary)
                    Spacer()
                    Toggle("", isOn: $hasTargetDate).labelsHidden().toggleStyle(.switch).controlSize(.small)
                }
                if hasTargetDate {
                    DatePicker("", selection: $targetDate, displayedComponents: .date)
                        .labelsHidden().colorScheme(.dark)
                }

                // Durum
                HStack(spacing: 6) {
                    ForEach(GoalStatus.allCases, id: \.self) { s in
                        Button { goal.status = s } label: {
                            Text(s.label).font(.system(size: 11))
                                .foregroundStyle(goal.status == s ? s.color : TickerTheme.textTertiary)
                                .padding(.horizontal, 9).padding(.vertical, 5)
                                .background(goal.status == s ? s.color.opacity(0.1) : TickerTheme.bgPill)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Sil
                Button(role: .destructive) {
                    context.delete(goal); try? context.save(); dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash").font(.system(size: 12))
                        Text("Hedefi Sil").font(.system(size: 13))
                    }
                    .foregroundStyle(TickerTheme.red)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .frame(width: 400)
        .background(Color(hex: "#161618"))
    }

    private func save() {
        goal.title = title.trimmingCharacters(in: .whitespaces)
        goal.emoji = emoji; goal.hexColor = hexColor
        goal.targetDate = hasTargetDate ? targetDate : nil
        goal.notes = notes
        try? context.save(); dismiss()
    }
}
