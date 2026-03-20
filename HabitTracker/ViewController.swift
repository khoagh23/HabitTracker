import UIKit

// Thêm UITableViewDataSource và UITableViewDelegate để app biết cách xử lý danh sách
class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // 1. Tạo một kho chứa các thói quen và tự động lưu
        var habits: [String] = [" Uống 2 lít nước", " Tập thể dục 30 phút", " Giải trí 20p", " Ngủ trước 11h đêm"] {
            didSet {
                UserDefaults.standard.set(habits, forKey: "KhoThoiQuen")
            }
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            
            // --- MOI DỮ LIỆU TỪ KHO RA ---
            if let duLieuDaLuu = UserDefaults.standard.stringArray(forKey: "KhoThoiQuen") {
                habits = duLieuDaLuu
            }
            // -----------------------------
            
            // Đặt tiêu đề to đùng ở trên cùng
            title = "Ghi chú của KĐ"
            navigationController?.navigationBar.prefersLargeTitles = true
            
            // Tạo nút (+) ở góc phải trên cùng
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAddPopup))
        }    // 2. Khai báo cho app biết danh sách này có bao nhiêu dòng
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return habits.count
    }
    
    // 3. Đổ dữ liệu (chữ) vào từng dòng một
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Gọi lại cái "HabitCell" mà ban nãy vừa đặt tên
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath)
        
        // Lấy tên thói quen và nhét vào ô
        var content = cell.defaultContentConfiguration()
        content.text = habits[indexPath.row]
        cell.contentConfiguration = content
        
        return cell
    }
    
    // Hàm này để xử lý việc quẹt để xóa
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 1. Xóa thói quen khỏi mảng dữ liệu
            habits.remove(at: indexPath.row)
            
            // 2. Xóa dòng đó trên giao diện với hiệu ứng mờ dần (fade)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // Hàm xử lý sự kiện khi người dùng bấm vào một dòng
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) {
            
            // Kiểm tra: nếu có dấu tick rồi thì gỡ ra, nếu chưa có thì gắn vào
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .checkmark
            }
        }
        
        // Tắt cái hiệu ứng nền xám khi vừa bấm xong
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // Hàm hiển thị Popup khi bấm nút (+)
        @objc func showAddPopup() {
            let alert = UIAlertController(title: "Thêm thói quen", message: "Nhập thói quen mới của bạn", preferredStyle: .alert)
            
            alert.addTextField { textField in
                textField.placeholder = "VD: Đọc sách 30 phút..."
            }
            
            let saveAction = UIAlertAction(title: "Lưu", style: .default) { _ in
                if let textField = alert.textFields?.first, let newHabit = textField.text, !newHabit.isEmpty {
    // Thêm vào mảng dữ liệu
                    self.habits.append(newHabit)
    // Cập nhật lại giao diện
    // Tự động tìm cái bảng trên màn hình và yêu cầu vẽ lại dữ liệu
        if let myTableView = self.view.subviews.first(where: { $0 is UITableView }) as? UITableView {
                                            myTableView.reloadData()
                                        }
                }
            }
            
            let cancelAction = UIAlertAction(title: "Hủy", style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            alert.addAction(saveAction)
            present(alert, animated: true, completion: nil)
        }}
