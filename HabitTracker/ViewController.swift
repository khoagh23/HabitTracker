import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var myTableView: UITableView!

    // 1. Kho chứa thói quen (TỰ ĐỘNG LƯU)
    var habits: [String] = ["Uống 2 lít nước", "Tập thể dục 30 phút", "Giải trí 20p", "Ngủ trước 11h đêm"] {
        didSet {
            UserDefaults.standard.set(habits, forKey: "KhoThoiQuen")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // THÊM DẤU ? VÀO ĐÂY ĐỂ CỨU APP
        myTableView?.dataSource = self
        myTableView?.delegate = self
        
        // KHÔI PHỤC DỮ LIỆU CŨ
        if let duLieuDaLuu = UserDefaults.standard.stringArray(forKey: "KhoThoiQuen") {
            habits = duLieuDaLuu
        }
        
        let savedTitle = UserDefaults.standard.string(forKey: "SavedNotesTitle") ?? "Ghi chú của KĐ"
        self.navigationItem.title = savedTitle
    }

    // 2. Chức năng ĐỔI TÊN
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Đổi tên danh sách", message: "Bạn muốn đổi tên thành gì?", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Ví dụ: Ghi chú"
            textField.text = self.navigationItem.title
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            let newTitle = alert.textFields?.first?.text ?? ""
            if !newTitle.isEmpty {
                self.navigationItem.title = newTitle
                UserDefaults.standard.set(newTitle, forKey: "SavedNotesTitle")
            }
        }))
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(alert, animated: true)
    }

    // 3. Chức năng THÊM MỚI (Dấu +)
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Thêm thói quen", message: "Hôm nay định làm gì?", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Ví dụ: Đọc sách 15p" }
        
        alert.addAction(UIAlertAction(title: "Thêm", style: .default, handler: { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.habits.insert(text, at: 0)
                self.myTableView?.reloadData() // Thêm dấu ? ở đây nữa cho chắc
            }
        }))
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(alert, animated: true)
    }

    // 4. Chức năng XÓA (Vuốt sang trái)
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            habits.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // 5. Nút START (Nối dây này ở màn hình 1 nha)
    @IBAction func startButtonTapped(_ sender: UIButton) { }

    // 6. Cấu hình số dòng và nội dung
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return habits.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath)
        cell.textLabel?.text = habits[indexPath.row]
        return cell
    }
}
