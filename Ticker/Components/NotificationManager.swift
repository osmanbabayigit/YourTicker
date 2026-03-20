import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - İzin

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Bildirim izni hatası: \(error.localizedDescription)")
            }
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Bildirim planla

    func schedule(for task: TaskItem) {
        guard let reminderDate = task.reminderDate else { return }
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = reminderDate.formatted(date: .abbreviated, time: .shortened)
        content.sound = .default

        if task.priority == 2 {
            content.interruptionLevel = .timeSensitive
        }

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("Bildirim eklenemedi: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Bildirim iptal

    func cancel(for task: TaskItem) {
        center.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
