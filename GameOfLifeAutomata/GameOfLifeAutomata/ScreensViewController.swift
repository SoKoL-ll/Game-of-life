import UIKit

class ScreensViewController: UIViewController {
    public weak var dataSource: CATiledDataSource?
    var data: [(image: UIImage, state: State)]!
    let table: UITableView = {
        let res = UITableView()
        
        res.translatesAutoresizingMaskIntoConstraints = false
        
        res.register(ScreensCellView.self, forCellReuseIdentifier: "cell")
        res.rowHeight = 140
        
        return res
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = CustomColors.table_background_color.color()
                
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = CustomColors.table_background_color.color()
        view.addSubview(table)
        addConstraint()
    }
    
    private func addConstraint() {
        NSLayoutConstraint.activate([
            table.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            table.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            table.topAnchor.constraint(equalTo: self.view.topAnchor),
            table.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
}

extension ScreensViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.table.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ScreensCellView
        
        cell.backgroundColor = CustomColors.cell_background_color.color()
        cell.image.image = data[indexPath.row].image

        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {

            data.remove(at: indexPath.row)
            dataSource?.deleteSnapshot(at: indexPath.row)
            table.beginUpdates()
            table.deleteRows(at: [indexPath], with: .left)
            
            table.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setAlert = UIAlertController(title: "Вы уверены?", message: nil, preferredStyle: .alert)
        
        setAlert.addAction(UIAlertAction(title: "Да", style: .default) { [unowned self] _ in
            self.table.deselectRow(at: indexPath, animated: true)
            let state = self.data[indexPath.row].state
            self.navigationController?.popViewController(animated: true)
            self.dataSource?.setStatefromSnapshot(from: state)
        })
        setAlert.addAction(UIAlertAction(title: "Нет", style: .default, handler: nil))
        self.present(setAlert, animated: true, completion: nil)
    }
}
