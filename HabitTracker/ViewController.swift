import UIKit
import UserNotifications

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var myTableView: UITableView!
    
    var emptyStateContainerView: UIView!
    var emptyStateLabel: UILabel!
    var progressLabel: UILabel!
    
    var floatingResetButton: UIButton!

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
        
       
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        self.navigationController?.navigationBar.standardAppearance = navBarAppearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        self.view.backgroundColor = UIColor.systemGroupedBackground
        myTableView?.backgroundColor = .clear
        myTableView?.separatorStyle = .none
        
        setupEmptyStateUI()
        
        if let duLieuDaLuu = UserDefaults.standard.stringArray(forKey: "KhoThoiQuen") { habits = duLieuDaLuu }
        if let trangThaiDaLuu = UserDefaults.standard.array(forKey: "TrangThaiTick") as? [Bool] { habitsCompleted = trangThaiDaLuu }
        if habitsCompleted.count != habits.count { habitsCompleted = Array(repeating: false, count: habits.count) }
        
        setupHeaderView()
        checkEmptyState()
        
        self.navigationItem.title = "Lịch trình của tôi"
        
       
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(toggleSortMode))
        
        if myTableView != nil {
            setupFloatingResetButton()
            
          
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in }
            }
        }
    }

    
    @objc func toggleSortMode() {
        myTableView?.isEditing.toggle()
        let iconName = myTableView!.isEditing ? "checkmark.circle.fill" : "arrow.up.arrow.down"
        self.navigationItem.leftBarButtonItem?.image = UIImage(systemName: iconName)
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedHabit = habits.remove(at: sourceIndexPath.row)
        let movedStatus = habitsCompleted.remove(at: sourceIndexPath.row)
        habits.insert(movedHabit, at: destinationIndexPath.row)
        habitsCompleted.insert(movedStatus, at: destinationIndexPath.row)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    
    func setupFloatingResetButton() {
        floatingResetButton = UIButton(type: .system)
        floatingResetButton.translatesAutoresizingMaskIntoConstraints = false
        
        floatingResetButton.backgroundColor = .systemRed
        floatingResetButton.tintColor = .white
        
        floatingResetButton.setTitle("Xóa hết", for: .normal)
        floatingResetButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        
        floatingResetButton.layer.cornerRadius = 22
        floatingResetButton.layer.shadowColor = UIColor.black.cgColor
        floatingResetButton.layer.shadowOpacity = 0.3
        floatingResetButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        floatingResetButton.layer.shadowRadius = 5
        
        floatingResetButton.addTarget(self, action: #selector(handleResetTapped), for: .touchUpInside)
        
        self.view.addSubview(floatingResetButton)
        
        NSLayoutConstraint.activate([
            floatingResetButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            floatingResetButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            floatingResetButton.widthAnchor.constraint(equalToConstant: 100),
            floatingResetButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc func handleResetTapped() {
        if habits.isEmpty { return }
        
        let alert = UIAlertController(title: "Xóa sạch dữ liệu!", message: "Bạn có chắc chắn muốn xóa toàn bộ lịch trình không? Hành động này không thể hoàn tác.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Xóa tất cả", style: .destructive, handler: { _ in
            self.habits.removeAll()
            self.habitsCompleted.removeAll()
            self.myTableView?.reloadData()
            self.updateProgress()
            self.checkEmptyState()
            self.triggerVisualFeedback()
        }))
        
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

   
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        self.emptyStateContainerView?.isHidden = true
        let alert = UIAlertController(title: "Thêm lịch trình", message: "Thiết lập thời gian cho công việc", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.textColor = .label
            textField.attributedPlaceholder = NSAttributedString(
                string: "Tên công việc",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            )
        }
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "vi_VN")
        
        alert.addTextField { textField in
            textField.textColor = .label
            textField.attributedPlaceholder = NSAttributedString(string: "Chọn thời gian", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textField.tintColor = .clear
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm - dd/MM/yyyy"
            textField.text = formatter.string(from: datePicker.date)
            
            datePicker.addAction(UIAction(handler: { _ in
                textField.text = formatter.string(from: datePicker.date)
            }), for: .valueChanged)
            textField.inputView = datePicker
        }
        
        alert.addAction(UIAlertAction(title: "Thêm", style: .default, handler: { _ in
            let text = alert.textFields?[0].text ?? ""
            let timeStr = alert.textFields?[1].text ?? ""
            
            if !text.isEmpty {
                let tenHienThi = "\(text)  •  \(timeStr)"
                self.habits.insert(tenHienThi, at: 0)
                self.habitsCompleted.insert(false, at: 0)
                self.myTableView?.reloadData()
                self.updateProgress()
                self.datLichHen(thoiGian: datePicker.date, tenThoiQuen: text)
            }
            self.checkEmptyState()
        }))
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: { _ in self.checkEmptyState() }))
        present(alert, animated: true)
    }

    func showEditAlert(for indexPath: IndexPath) {
        let oldData = habits[indexPath.row]
        let oldName = oldData.components(separatedBy: "  •  ").first ?? oldData
        
        let alert = UIAlertController(title: "Sửa lịch trình", message: "Cập nhật công việc hoặc thời gian", preferredStyle: .alert)
        
        alert.addTextField { tf in
            tf.textColor = .label
            tf.text = oldName
        }
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "vi_VN")
        
        alert.addTextField { tf in
            tf.textColor = .label
            tf.attributedPlaceholder = NSAttributedString(string: "Chọn thời gian mới (Tùy chọn)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            tf.tintColor = .clear
            tf.inputView = datePicker
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm - dd/MM/yyyy"
            
            datePicker.addAction(UIAction(handler: { _ in
                tf.text = formatter.string(from: datePicker.date)
            }), for: .valueChanged)
        }
        
        alert.addAction(UIAlertAction(title: "Cập nhật", style: .default, handler: { _ in
            let newName = alert.textFields?[0].text ?? oldName
            let newTimeStr = alert.textFields?[1].text ?? ""
            
            if !newName.isEmpty {
                if !newTimeStr.isEmpty {
                    self.habits[indexPath.row] = "\(newName)  •  \(newTimeStr)"
                    self.datLichHen(thoiGian: datePicker.date, tenThoiQuen: newName)
                } else {
                    let components = oldData.components(separatedBy: "  •  ")
                    let oldTimePart = components.count > 1 ? components[1] : ""
                    if !oldTimePart.isEmpty {
                        self.habits[indexPath.row] = "\(newName)  •  \(oldTimePart)"
                    } else {
                        self.habits[indexPath.row] = newName
                    }
                }
                self.myTableView?.reloadRows(at: [indexPath], with: .automatic)
            }
        }))
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Xóa") { (action, view, completionHandler) in
            self.habits.remove(at: indexPath.row)
            self.habitsCompleted.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            self.updateProgress()
            self.checkEmptyState()
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .systemRed
        
        let editAction = UIContextualAction(style: .normal, title: "Sửa") { (action, view, completionHandler) in
            self.showEditAlert(for: indexPath)
            completionHandler(true)
        }
        editAction.image = UIImage(systemName: "pencil")
        editAction.backgroundColor = .systemOrange
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }

   
    @IBAction func startButtonTapped(_ sender: UIButton) {
        sender.setTitle("", for: .normal)
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        sender.addSubview(spinner)
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: sender.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: sender.centerYAnchor)
        ])
        
        spinner.startAnimating()
        sender.isUserInteractionEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            sender.setTitle("START", for: .normal)
            sender.isUserInteractionEnabled = true
            
            self.performSegue(withIdentifier: "ChuyenManHinh", sender: nil)
        }
    }

  
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return habits.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 75 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath)
        let habitName = habits[indexPath.row]
        let isCompleted = habitsCompleted[indexPath.row]
        
        cell.backgroundColor = .clear
        
        let cardView = UIView()
        cardView.backgroundColor = isCompleted ? UIColor.secondarySystemBackground : UIColor.systemBackground
        cardView.layer.cornerRadius = 12
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = isCompleted ? 0.0 : 0.05
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        
        let colorStrip = UIView()
        colorStrip.backgroundColor = isCompleted ? .systemGray4 : .systemBlue
        colorStrip.layer.cornerRadius = 12
        colorStrip.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        colorStrip.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(colorStrip)
        
        let backView = UIView()
        backView.backgroundColor = .clear
        backView.addSubview(cardView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: backView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            
            colorStrip.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            colorStrip.topAnchor.constraint(equalTo: cardView.topAnchor),
            colorStrip.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            colorStrip.widthAnchor.constraint(equalToConstant: 6)
        ])
        cell.backgroundView = backView
        
        if isCompleted {
            let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: habitName)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            cell.textLabel?.attributedText = attributeString
            cell.textLabel?.textColor = .secondaryLabel
            cell.accessoryType = .checkmark
            cell.tintColor = .systemBlue
        } else {
            cell.textLabel?.attributedText = nil
            cell.textLabel?.text = habitName
            cell.textLabel?.textColor = .label
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        habitsCompleted[indexPath.row].toggle()
        self.updateProgress()
        
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.1, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
            }) { _ in
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1.5, options: .curveEaseInOut, animations: {
                    cell.transform = .identity
                }, completion: nil)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        if habitsCompleted[indexPath.row] == true {
            triggerVisualFeedback()
        }
    }
    
    func triggerVisualFeedback() {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        if let window = windowScene?.windows.first(where: { $0.isKeyWindow }) {
            let flashView = UIView(frame: window.bounds)
            flashView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.20)
            flashView.isUserInteractionEnabled = false
            flashView.alpha = 0
            window.addSubview(flashView)
            
            UIView.animate(withDuration: 0.1, animations: {
                flashView.alpha = 1.0
            }) { _ in
                UIView.animate(withDuration: 0.4, delay: 0.05, options: .curveEaseOut, animations: {
                    flashView.alpha = 0
                }) { _ in
                    flashView.removeFromSuperview()
                }
            }
        }
    }

    func setupHeaderView() {
        guard myTableView != nil else { return }
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 70))
        
        let dateLabel = UILabel()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd 'tháng' MM"
        dateLabel.text = formatter.string(from: Date()).uppercased()
        
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        dateLabel.textColor = .secondaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(dateLabel)
        
        progressLabel = UILabel()
        progressLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        progressLabel.textColor = .label
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            dateLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            progressLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            progressLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20)
        ])
        
        myTableView.tableHeaderView = headerView
        updateProgress()
    }
    
    func updateProgress() {
        guard progressLabel != nil else { return }
        let total = habits.count
        let completed = habitsCompleted.filter { $0 == true }.count
        let left = total - completed
        
        if total == 0 {
            progressLabel.text = "Hãy thêm việc cho hôm nay"
            progressLabel.textColor = .label
        } else if left == 0 {
            progressLabel.text = "Hoàn hảo! Đã xong hết"
            progressLabel.textColor = .systemBlue
        } else {
            progressLabel.text = "Còn \(left) việc đang chờ bạn"
            progressLabel.textColor = .label
        }
    }

    func datLichHen(thoiGian: Date, tenThoiQuen: String) {
        let content = UNMutableNotificationContent()
        content.title = "Đến giờ hẹn rồi!"
        content.body = "Tới giờ thực hiện: \(tenThoiQuen)."
        content.sound = UNNotificationSound.default
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: thoiGian)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func setupEmptyStateUI() {
        emptyStateContainerView = UIView()
        emptyStateContainerView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateContainerView.isHidden = true
        self.view.addSubview(emptyStateContainerView)
        
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "Chưa có dữ liệu.\nNhấn dấu + để lên lịch trình mới."
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateContainerView.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            emptyStateContainerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            emptyStateContainerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -20),
            emptyStateContainerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40),
            emptyStateContainerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -40),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateContainerView.topAnchor),
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
            floatingResetButton?.isHidden = true
        } else {
            emptyStateContainerView?.isHidden = true
            myTableView?.backgroundView = nil
            floatingResetButton?.isHidden = false
        }
    }
}
