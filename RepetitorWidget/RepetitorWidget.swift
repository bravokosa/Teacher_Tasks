import WidgetKit
import SwiftUI

// Модель для виджета (такая же как в приложении)
struct HomeworkTask: Codable {
    var id = UUID()
    var title: String
    var details: String
    var dueDate: Date
    var isCompleted: Bool = false
    var subject: String = "Сдача теории"
}

struct Provider: TimelineProvider {
    let appGroup = "group.anna.repetitor2025" // Твоя группа
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), task: HomeworkTask(title: "Загрузка...", details: "", dueDate: Date(), subject: "Тест"))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), task: HomeworkTask(title: "Пример задания", details: "", dueDate: Date(), subject: "Тест"))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var mostUrgentTask: HomeworkTask? = nil
        
        if let defaults = UserDefaults(suiteName: appGroup),
           let data = defaults.data(forKey: "SavedTasks"),
           let tasks = try? JSONDecoder().decode([HomeworkTask].self, from: data) {
            // Ищем самую срочную невыполненную задачу
            mostUrgentTask = tasks.filter { !$0.isCompleted }.sorted { $0.dueDate < $1.dueDate }.first
        }

        let entry = SimpleEntry(date: Date(), task: mostUrgentTask)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let task: HomeworkTask?
}

struct RepetitorWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var gradientColors: [Color] {
        if let task = entry.task, task.subject == "Тест" {
            return [.orange, .red]
        } else {
            return [.blue, .purple]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: entry.task == nil ? [.gray.opacity(0.3), .gray.opacity(0.5)] : gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.15)

            if let task = entry.task {
                VStack(alignment: .leading) {
                    HStack {
                        Text(task.subject.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(.ultraThinMaterial))
                            .foregroundColor(gradientColors.first)
                        Spacer()
                        Image(systemName: task.subject == "Тест" ? "flame.fill" : "book.closed.fill")
                            .font(.caption)
                            .foregroundColor(gradientColors.last)
                    }
                    Spacer()
                    Text(task.title)
                        .font(family == .systemSmall ? .headline : .title3)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    Spacer()
                    HStack {
                        Image(systemName: "timer")
                        Text(task.dueDate, style: .relative)
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .foregroundColor(task.dueDate < Date() ? .red : .primary)
                }
                .padding()
            } else {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom))
                    Text("Всё сдано!")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
        }
        .containerBackground(for: .widget) { Color.white }
    }
}

@main
struct RepetitorWidget: Widget {
    let kind: String = "RepetitorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                RepetitorWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                RepetitorWidgetEntryView(entry: entry)
                    .background(Color.white)
            }
        }
        .configurationDisplayName("Горящее задание")
        .description("Показывает, что учить прямо сейчас.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
