import SwiftUI
import UserNotifications
import WidgetKit

// --- МОДЕЛЬ ДАННЫХ ---
struct HomeworkTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var details: String
    var dueDate: Date
    var isCompleted: Bool = false
    var subject: String = "Сдача теории"
}

// --- ГЛАВНЫЙ ЭКРАН ---
struct ContentView: View {
    @State private var tasks: [HomeworkTask] = []
    @State private var showAddSheet = false
    
    // ВАЖНО: Твоя группа
    let appGroup = "group.anna.repetitor2025"
    
    // Статистика для кольца
    var activeTasksCount: Int { tasks.filter { !$0.isCompleted }.count }
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let completed = Double(tasks.filter { $0.isCompleted }.count)
        return completed / Double(tasks.count)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 1. ЖИВОЙ ФОН
                BackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 2. ЗАГОЛОВОК И КОЛЬЦО
                        HeaderView(activeCount: activeTasksCount, progress: progress)
                            .padding(.top, 20)
                        
                        // 3. СПИСОК ЗАДАЧ
                        if tasks.isEmpty {
                            EmptyPlaceholderView()
                        } else {
                            LazyVStack(spacing: 16) {
                                // БЕЗОПАСНАЯ СОРТИРОВКА (без ошибок Binding)
                                ForEach(tasks.sorted(by: { t1, t2 in
                                    if t1.isCompleted != t2.isCompleted {
                                        return !t1.isCompleted // Сначала невыполненные
                                    }
                                    return t1.dueDate < t2.dueDate
                                })) { task in
                                    NeonTaskCard(task: task, onToggle: {
                                        toggleTask(task)
                                    })
                                    .contextMenu {
                                        Button(role: .destructive) { deleteTask(task: task) } label: {
                                            Label("Удалить", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                
                // 4. ПЛАВАЮЩАЯ КНОПКА +
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(
                                    LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(Circle())
                                .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddSheet) {
                AddTaskView(tasks: $tasks, appGroup: appGroup)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                loadTasks()
            }
        }
        .onAppear {
            requestNotificationPermission()
            loadTasks()
        }
    }
    func toggleTask(_ task: HomeworkTask) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].isCompleted.toggle()
                saveTasks()
            }
        }
    }
    
    func deleteTask(task: HomeworkTask) {
        withAnimation {
            tasks.removeAll(where: { $0.id == task.id })
            saveTasks()
        }
    }
    
    func saveTasks() {
        if let defaults = UserDefaults(suiteName: appGroup),
           let encoded = try? JSONEncoder().encode(tasks) {
            defaults.set(encoded, forKey: "SavedTasks")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func loadTasks() {
        if let defaults = UserDefaults(suiteName: appGroup),
           let data = defaults.data(forKey: "SavedTasks") {
            if let decoded = try? JSONDecoder().decode([HomeworkTask].self, from: data) {
                tasks = decoded
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
}

// --- КОМПОНЕНТЫ ДИЗАЙНА (Всё внутри одного файла) ---

struct HeaderView: View {
    let activeCount: Int
    let progress: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Date().formatted(date: .abbreviated, time: .omitted).uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                if activeCount > 0 {
                    Text("Осталось: \(activeCount)")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(LinearGradient(colors: [.primary, .secondary], startPoint: .leading, endPoint: .trailing))
                } else {
                    Text("Всё готово! 🎉")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing))
                }
            }
            Spacer()
            ZStack {
                Circle().stroke(lineWidth: 8).opacity(0.1).foregroundColor(.blue)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom))
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.spring(), value: progress)
                Text("\(Int(progress * 100))%").font(.caption).fontWeight(.bold)
            }
            .frame(width: 60, height: 60)
        }
        .padding(.horizontal, 8)
    }
}

struct NeonTaskCard: View {
    let task: HomeworkTask
    let onToggle: () -> Void
    
    var gradientColors: [Color] {
        if task.subject == "Тест" { return [.orange, .red] }
        else { return [.blue, .purple] }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .opacity(task.isCompleted ? 0 : 1)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .opacity(task.isCompleted ? 1 : 0)
                        .scaleEffect(task.isCompleted ? 1 : 0.5)
                }
            }
            .padding(.leading, 8)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.subject.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)).opacity(0.2))
                        .foregroundColor(gradientColors.first)
                    Spacer()
                    if !task.isCompleted {
                        TimeBadge(date: task.dueDate)
                    }
                }
                
                Text(task.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                    .lineLimit(2)
                
                if !task.details.isEmpty && !task.isCompleted {
                    Text(task.details)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(LinearGradient(colors: gradientColors.map { $0.opacity(0.5) }, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        .padding(1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                .opacity(task.isCompleted ? 0 : 0.2)
                .blur(radius: 20)
                .offset(y: 10)
                .padding(20)
        )
        .scaleEffect(task.isCompleted ? 0.98 : 1)
        .opacity(task.isCompleted ? 0.7 : 1)
    }
}

struct TimeBadge: View {
    let date: Date
    var isUrgent: Bool { date < Date() }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isUrgent ? "exclamationmark.triangle.fill" : "calendar")
            Text(date, style: .relative)
        }
        .font(.caption2)
        .fontWeight(.bold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isUrgent ? Color.red.opacity(0.1) : Color.secondary.opacity(0.1))
        .foregroundColor(isUrgent ? .red : .secondary)
        .cornerRadius(8)
    }
}

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            GeometryReader { geo in
                Circle().fill(Color.blue.opacity(0.1))
                    .frame(width: geo.size.width * 0.8)
                    .offset(x: -geo.size.width * 0.4, y: -geo.size.height * 0.2)
                    .blur(radius: 60)
                Circle().fill(Color.purple.opacity(0.1))
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.3)
                    .blur(radius: 60)
            }
        }
    }
}

struct EmptyPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 50)
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                .padding()
                .background(Circle().fill(.thinMaterial).shadow(radius: 10))
            Text("Время учиться!")
                .font(.title2)
                .fontWeight(.bold)
            Text("Добавь задания через +, чтобы не забыть\nподготовиться к тесту или теории.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// --- ЭКРАН ДОБАВЛЕНИЯ ---
struct AddTaskView: View {
    @Binding var tasks: [HomeworkTask]
    var appGroup: String
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var details = ""
    @State private var dueDate = Date()
    @State private var selectedType = "Сдача теории"
    let taskTypes = ["Сдача теории", "Тест"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Тип задания", selection: $selectedType) {
                        ForEach(taskTypes, id: \.self) { type in Text(type) }
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("Детали")) {
                    TextField("Тема (напр. Причастия)", text: $title)
                        .font(.headline)
                    TextEditor(text: $details).frame(height: 80)
                }
                Section(header: Text("Дедлайн")) {
                    DatePicker("Когда сдавать?", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Новое задание")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        let newTask = HomeworkTask(title: title, details: details, dueDate: dueDate, subject: selectedType)
                        tasks.append(newTask)
                        if let defaults = UserDefaults(suiteName: appGroup),
                           let encoded = try? JSONEncoder().encode(tasks) {
                            defaults.set(encoded, forKey: "SavedTasks")
                            WidgetCenter.shared.reloadAllTimelines()
                            scheduleNotification(for: newTask)
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    func scheduleNotification(for task: HomeworkTask) {
        let content = UNMutableNotificationContent()
        content.title = "\(task.subject): \(task.title)"
        content.body = "Пора готовиться!"
        content.sound = .default
        let triggerDate = task.dueDate.addingTimeInterval(-3600)
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    ContentView()
}
