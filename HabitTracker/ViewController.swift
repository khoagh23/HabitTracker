import UIKit
import UserNotifications

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var myTableView: UITableView!
    
    var emptyStateContainerView: UIView!
    var emptyStateImageView: UIImageView!
    var emptyStateLabel: UILabel!

    var habits: [String] = [] {
        didSet { UserDefaults.standard.set(habits, forKey: "KhoThoiQuen") }
    }
    
    var habitsCompleted: [Bool] = [] {
        didSet { UserDefaults.standard.set(habitsCompleted, forKey: "TrangThaiTick") }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        myTableView?.dataSource = self
        myTableView?.delegate = self
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        
        self.view.backgroundColor = UIColor.systemGroupedBackground
        myTableView?.backgroundColor = .clear
        myTableView?.separatorStyle = .none
        
        setupEmptyStateUI()
        
        if let duLieuDaLuu = UserDefaults.standard.stringArray(forKey: "KhoThoiQuen") { habits = duLieuDaLuu }
        if let trangThaiDaLuu = UserDefaults.standard.array(forKey: "TrangThaiTick") as? [Bool] { habitsCompleted = trangThaiDaLuu }
        if habitsCompleted.count != habits.count { habitsCompleted = Array(repeating: false, count: habits.count) }
        
        checkEmptyState()
        
        let savedTitle = UserDefaults.standard.string(forKey: "SavedNotesTitle") ?? "Lịch trình hôm nay"
        self.navigationItem.title = savedTitle
        
        if myTableView != nil {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in }
        }
    }

    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        self.emptyStateContainerView?.isHidden = true
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
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: { _ in self.checkEmptyState() }))
        present(alert, animated: true)
    }

    // 🚀 TÍNH NĂNG MỚI: BÁNH RĂNG THỜI GIAN (TIME PICKER)
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        self.emptyStateContainerView?.isHidden = true
        let alert = UIAlertController(title: "Thêm lịch trình", message: "Vuốt để chọn giờ nha", preferredStyle: .alert)
        
        // Ô 1: Nhập tên (Vẫn dùng bàn phím chữ bình thường)
        alert.addTextField { $0.placeholder = "Tên việc (VD: Uống thuốc)" }
        
        // Ô 2: Khung chọn giờ (Biến hóa thành trục xoay)
        alert.addTextField { textField in
            textField.placeholder = "Chạm để chọn giờ"
            textField.tintColor = .clear
            
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .time
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.locale = Locale(identifier: "vi_VN")
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            textField.text = formatter.string(from: datePicker.date)
            
            datePicker.addAction(UIAction(handler: { _ in
                textField.text = formatter.string(from: datePicker.date)
            }), for: .valueChanged)
            
            textField.inputView = datePicker
        }
        
        alert.addAction(UIAlertAction(title: "Lên lịch", style: .default, handler: { _ in
            let text = alert.textFields?[0].text ?? ""
            let timeStr = alert.textFields?[1].text ?? ""
            
            if !text.isEmpty {
                self.habits.insert(text, at: 0)
                self.habitsCompleted.insert(false, at: 0)
                self.myTableView?.reloadData()
                
                
                var gio = 19
                var phut = 0
                let timeParts = timeStr.split(separator: ":")
                if timeParts.count == 2 {
                    gio = Int(timeParts[0]) ?? 19
                    phut = Int(timeParts[1]) ?? 0
                }
                
                self.datLichTheoGio(gio: gio, phut: phut, tenThoiQuen: text)
            }
            self.checkEmptyState()
        }))
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: { _ in self.checkEmptyState() }))
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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath)
        
        let habitName = habits[indexPath.row]
        let isCompleted = habitsCompleted[indexPath.row]
        
        cell.backgroundColor = .clear
        
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius = 5
        
        let backView = UIView()
        backView.backgroundColor = .clear
        backView.addSubview(cardView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: backView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16)
        ])
        cell.backgroundView = backView
        
        if isCompleted {
            let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: habitName)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            cell.textLabel?.attributedText = attributeString
            cell.textLabel?.textColor = .lightGray
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
        
        if habitsCompleted[indexPath.row] == true {
            shootConfettiAndVibrate()
        }
    }
    
    func shootConfettiAndVibrate() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: self.view.bounds.width / 2.0, y: -50)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: self.view.bounds.width, height: 1)
        
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow, .systemPink, .systemPurple, .systemOrange]
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 6.0
            cell.lifetime = 14.0
            cell.velocity = 250
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 2
            cell.spinRange = 2
            cell.scaleRange = 0.5
            cell.scaleSpeed = -0.05
            
            let rect = CGRect(x: 0, y: 0, width: 12, height: 12)
            UIGraphicsBeginImageContext(rect.size)
            color.setFill()
            UIBezierPath(rect: rect).fill()
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            cell.contents = image?.cgImage
            cells.append(cell)
        }
        
        emitter.emitterCells = cells
        self.view.layer.addSublayer(emitter)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            emitter.birthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                emitter.removeFromSuperlayer()
            }
        }
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
    
    func setupEmptyStateUI() {
        emptyStateContainerView = UIView()
        emptyStateContainerView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateContainerView.isHidden = true
        self.view.addSubview(emptyStateContainerView)
        
        emptyStateImageView = UIImageView()
        emptyStateImageView.image = UIImage(systemName: "list.bullet.clipboard")
        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateImageView.tintColor = .systemGray4
        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateContainerView.addSubview(emptyStateImageView)
        
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "Lịch trình hôm nay đang trống.\nBấm dấu + để tạo mới nhé"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        emptyStateLabel.textColor = .systemGray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateContainerView.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            emptyStateContainerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            emptyStateContainerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -20),
            emptyStateContainerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40),
            emptyStateContainerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -40),
            
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateContainerView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateContainerView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateContainerView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateContainerView.trailingAnchor),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateContainerView.bottomAnchor)
        ])
    }
    
    func checkEmptyState() {
        if myTableView == nil {
            emptyStateContainerView?.isHidden = true
            return
        }
        
        if habits.isEmpty {
            emptyStateContainerView?.isHidden = false
            myTableView?.backgroundView = UIView()
        } else {
            emptyStateContainerView?.isHidden = true
            myTableView?.backgroundView = nil
        }
    }
}
