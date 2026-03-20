import SwiftUI
import SwiftData

/// Odak Modu — bir güne çift tıklayınca açılır
/// Görevleri bir zaman şeridinde gösterir, saat bazlı görsel yerleşim
struct FocusDayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let tasks: [TaskItem]

    @State private var showingAddTask = false

    private var dayTasks: [TaskItem] {
        tasks.filter {
            guard let d = $0.dueDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
        .sorted { ($0.priority, $0.isCompleted ? 1 : 0) > ($1.priority, $1.isCompleted ? 1 : 0) }
    }

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var completedCount: Int { dayTasks.filter { $0.isCompleted }.count }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if isToday {
                            Text("BUGÜN")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                        Text(date, format: .dateTime.weekday(.wide))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                    Text(date, format: .dateTime.day().month(.wide).year())
                        .font(.system(size: 28, weight: .bold))

                    if !dayTasks.isEmpty {
                        Text("\(completedCount)/\(dayTasks.count) görev tamamlandı")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    Button("Kapat") { dismiss() }
                        .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 13))

                    Button {
                        showingAddTask = true
                    } label: {
                        Label("Görev Ekle", systemImage: "plus")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent).tint(.blue).controlSize(.small)
                }
            }
            .padding(24)

            // Progress bar
            if !dayTasks.isEmpty {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.secondary.opacity(0.1)).frame(height: 3)
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geo.size.width * CGFloat(completedCount) / CGFloat(dayTasks.count), height: 3)
                            .animation(.spring(response: 0.5), value: completedCount)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 24)
            }

            Divider().opacity(0.3).padding(.top, 8)

            if dayTasks.isEmpty {
                emptyState
            } else {
                taskGrid
            }
        }
        .frame(width: 680, height: 520)
        .background(GlassView(material: .hudWindow))
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(selectedDate: date)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color.blue.opacity(0.08)).frame(width: 80, height: 80)
                Image(systemName: isToday ? "sun.max" : "moon.stars")
                    .font(.system(size: 30)).foregroundStyle(Color.blue.opacity(0.4))
            }
            Text(isToday ? "Bugün boş!" : "Bu gün boş")
                .font(.system(size: 18, weight: .semibold))
            Text("Yeni bir görev ekleyerek günü doldur")
                .font(.system(size: 13)).foregroundStyle(.secondary)
            Button("Görev Ekle") { showingAddTask = true }
                .buttonStyle(.borderedProminent).tint(.blue)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Görev grid

    private var taskGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(dayTasks) { task in
                    FocusTaskCard(task: task)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Odak modu görev kartı

struct FocusTaskCard: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var context
    @State private var showingEdit = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Üst satır
            HStack(alignment: .top) {
                // Renk + tamamlama
                Button {
                    withAnimation(.spring(response: 0.3)) { task.isCompleted.toggle() }
                    try? context.save()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: task.hexColor).opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: task.hexColor))
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold))
                        .strikethrough(task.isCompleted, color: .secondary)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .lineLimit(2)

                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Öncelik
                if task.priority > 0 {
                    Image(systemName: task.priority == 2 ? "exclamationmark.2" : "exclamationmark")
                        .font(.system(size: 11))
                        .foregroundStyle(task.priority == 2 ? Color.red : Color.orange)
                }
            }

            // Alt görevler (varsa mini progress)
            if !task.subtasks.isEmpty {
                VStack(spacing: 4) {
                    ForEach(task.sortedSubtasks.prefix(3)) { sub in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(sub.isCompleted ? Color(hex: task.hexColor) : Color.secondary.opacity(0.3))
                                .frame(width: 5, height: 5)
                            Text(sub.title)
                                .font(.system(size: 10))
                                .foregroundStyle(sub.isCompleted ? .secondary : .primary)
                                .strikethrough(sub.isCompleted)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.leading, 4)

                // Progress
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.12)).frame(height: 3)
                        Capsule()
                            .fill(Color(hex: task.hexColor))
                            .frame(
                                width: task.subtasks.isEmpty ? 0 :
                                    geo.size.width * CGFloat(task.completedSubtaskCount) / CGFloat(task.subtasks.count),
                                height: 3
                            )
                    }
                }
                .frame(height: 3)
            }

            // Etiketler
            if !task.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(task.tags.prefix(3)) { tag in
                        Text(tag.name)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color(hex: tag.hexColor).opacity(0.12))
                            .foregroundStyle(Color(hex: tag.hexColor))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(task.isCompleted
                      ? Color(nsColor: .controlBackgroundColor).opacity(0.3)
                      : Color(hex: task.hexColor).opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    task.isCompleted
                    ? Color.secondary.opacity(0.1)
                    : Color(hex: task.hexColor).opacity(isHovered ? 0.4 : 0.15),
                    lineWidth: 1.5
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.2), value: isHovered)
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) { EditTaskView(task: task) }
    }
}
