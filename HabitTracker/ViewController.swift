import UIKit
import UserNotifications

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var myTableView: UITableView!
    
    var emptyStateLabel: UILabel!

    // Kho chứa tên thói quen
    var habits: [String] = [] {
        didSet { UserDefaults.standard.set(habits, forKey: "KhoThoiQuen") }
    }
    
    // Kho chứa trạng thái tick
    var habitsCompleted: [Bool] = [] {
        didSet { UserDefaults.standard.set(habitsCompleted, forKey: "TrangThaiTick") }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        myTableView?.dataSource = self
        myTableView?.delegate = self
        
        setupEmptyStateLabel()
        
        // Khôi phục danh sách
        if let duLieuDaLuu = UserDefaults.standard.stringArray(forKey: "KhoThoiQuen") {
            habits = duLieuDaLuu
        }
        
        // Khôi phục trạng thái tick
        if let trangThaiDaLuu = UserDefaults.standard.array(forKey: "TrangThaiTick") as? [Bool] {
            habitsCompleted = trangThaiDaLuu
        }
        
        if habitsCompleted.count != habits.count {
            habitsCompleted = Array(repeating: false, count: habits.count)
        }
        
        checkEmptyState()
        
        let savedTitle = UserDefaults.standard.string(forKey: "SavedNotesTitle") ?? "Thói quen của tôi"
        self.navigationItem.title = savedTitle
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted { print("Sếp đã cấp phép Ting Ting!") }
        }
    }

    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
      
        self.emptyStateLabel?.isHidden = true
        
        let alert = UIAlertController(title: "Đổi tên danh sách", message: "Bạn muốn đổi tên thành gì?", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Ví dụ: Việc cần làm"
            textField.text = self.navigationItem.title
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            let newTitle = alert.textFields?.first?.text ?? ""
            if !newTitle.isEmpty {
                self.navigationItem.title = newTitle
                UserDefaults.standard.set(newTitle, forKey: "SavedNotesTitle")
            }
            self.checkEmptyState()
        }))
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: { _ in
            self.checkEmptyState()
        }))
        present(alert, animated: true)
    }

    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
       
        self.emptyStateLabel?.isHidden = true
        
        let alert = UIAlertController(title: "Thêm lịch trình", message: "Bạn muốn làm việc này lúc mấy giờ?", preferredStyle: .alert)
        
        alert.addTextField { $0.placeholder = "Tên việc (VD: Uống thuốc)" }
        alert.addTextField {
            $0.placeholder = "Giờ (0-23, VD: 00)"
            $0.keyboardType = .numberPad
        }
        alert.addTextField {
            $0.placeholder = "Phút (0-59, VD: 00)"
            $0.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "Lên lịch", style: .default, handler: { _ in
            let text = alert.textFields?[0].text ?? ""
            let gioStr = alert.textFields?[1].text ?? ""
            let phutStr = alert.textFields?[2].text ?? ""
            
            if !text.isEmpty {
                self.habits.insert(text, at: 0)
                self.habitsCompleted.insert(false, at: 0)
                self.myTableView?.reloadData()
                
                let gio = Int(gioStr) ?? 19
                let phut = Int(phutStr) ?? 0
                self.datLichTheoGio(gio: gio, phut: phut, tenThoiQuen: text)
            }
           
            self.checkEmptyState()
        }))
        
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: { _ in
            
            self.checkEmptyState()
        }))
        
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            habits.remove(at: indexPath.row)
            habitsCompleted.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            self.checkEmptyState()
        }
    }

    @IBAction func startButtonTapped(_ sender: UIButton) { }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return habits.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath)
        
        let habitName = habits[indexPath.row]
        let isCompleted = habitsCompleted[indexPath.row]
        
        if isCompleted {
            let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: habitName)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            cell.textLabel?.attributedText = attributeString
            cell.textLabel?.textColor = .gray
            cell.accessoryType = .checkmark
        } else {
            cell.textLabel?.attributedText = nil
            cell.textLabel?.text = habitName
            cell.textLabel?.textColor = .black
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        habitsCompleted[indexPath.row].toggle()
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func datLichTheoGio(gio: Int, phut: Int, tenThoiQuen: String) {
        let content = UNMutableNotificationContent()
        content.title = "Đến giờ rồi bạn ơi!"
        content.body = "Tới lúc: \(tenThoiQuen) rồi, nhanh nhanh nào!"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = gio
        dateComponents.minute = phut

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func setupEmptyStateLabel() {
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "Hôm nay bạn chưa có lịch trình nào.\nBấm dấu + để thêm nhé"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        emptyStateLabel.textColor = .gray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.isHidden = true
        
        self.view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -20),
            emptyStateLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -40)
        ])
    }
    
    func checkEmptyState() {
        if myTableView == nil {
            emptyStateLabel?.isHidden = true
            return
        }
        
        if habits.isEmpty {
            emptyStateLabel?.isHidden = false
            myTableView?.backgroundView = UIView()
        } else {
            emptyStateLabel?.isHidden = true
            myTableView?.backgroundView = nil
        }
    }
}
