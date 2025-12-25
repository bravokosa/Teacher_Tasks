import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import WidgetKit // ПОДКЛЮЧИЛИ МОЗГ ВИДЖЕТА

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        return true // Разрешаем нажимать кнопку всегда, сами разберемся с текстом
    }

    override func didSelectPost() {
        // 1. Пытаемся добыть текст любыми способами
        var textToSave = self.contentText ?? ""
        
        if textToSave.isEmpty {
            // Если пусто, пробуем найти текст во вложениях (для хитрых приложений)
            if let item = extensionContext?.inputItems.first as? NSExtensionItem,
               let provider = item.attachments?.first {
                if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (data, error) in
                        if let text = data as? String {
                            textToSave = text
                        }
                        // Продолжаем сохранение уже с текстом
                        self.processAndSave(text: textToSave)
                    }
                    return // Выходим, чтобы дождаться загрузки
                }
            }
        }
        
        // Если текст был сразу - сохраняем
        processAndSave(text: textToSave)
    }
    
    func processAndSave(text: String) {
        // Если текст всё равно пустой, пишем заглушку
        let finalDetails = text.isEmpty ? "Ссылка или файл из Telegram" : text
        let finalTitle = text.isEmpty ? "Новое задание" : "Из Telegram"
        
        // Ищем дату или ставим "Завтра"
        let smartDate = detectDate(in: finalDetails) ?? Date().addingTimeInterval(86400)
        
        saveTask(title: finalTitle, details: finalDetails, date: smartDate)
        
        // Закрываем окно
        DispatchQueue.main.async {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }
    
    func detectDate(in text: String) -> Date? {
        // Умный поиск даты
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        // Если нашли дату, возвращаем её
        if let firstMatch = matches.first, let date = firstMatch.date {
            return date
        }
        return nil
    }
    
    func saveTask(title: String, details: String, date: Date) {
        let suiteName = "group.anna.repetitor2025" // ТВОЯ ГРУППА
        
        struct SimpleTask: Codable {
            var id = UUID()
            var title: String
            var details: String
            var dueDate: Date
            var isCompleted: Bool = false
            var subject: String = "Сдача теории"
        }
        
        let newTask = SimpleTask(title: title, details: details, dueDate: date)
        
        if let userDefaults = UserDefaults(suiteName: suiteName) {
            var currentTasks: [SimpleTask] = []
            
            if let data = userDefaults.data(forKey: "SavedTasks"),
               let decoded = try? JSONDecoder().decode([SimpleTask].self, from: data) {
                currentTasks = decoded
            }
            
            currentTasks.append(newTask)
            
            if let encoded = try? JSONEncoder().encode(currentTasks) {
                userDefaults.set(encoded, forKey: "SavedTasks")
                
                // ВОТ ОНО! ПИНАЕМ ВИДЖЕТ, ЧТОБЫ ОН ОБНОВИЛСЯ
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
