//
//  ItemListViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit

class ItemListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var shop : Shop?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shop?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ItemShopCell", for: indexPath) as? ItemCell else {
            return UITableViewCell()
        }
        if let item = shop?.items[indexPath.row]{
            cell.nameLabel.text = item.name
            cell.detailLabel.text = item.detail
            cell.importance = item.importance
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            if let deadline = item.deadline {
                cell.deadlineLabel.text = formatter.string(from: deadline)
            } else {
                cell.deadlineLabel.text = "未設定"
            }
        }
        return cell
    }
}
