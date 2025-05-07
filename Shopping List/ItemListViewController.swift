//
//  ItemListViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit

class ItemListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var selectedShopIndex: Int?
    var shopItems: [[Item]] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shopItems[selectedShopIndex ?? 0].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let item = shopItems[selectedShopIndex ?? 0][indexPath.row]
        cell.textLabel?.text = item.name
        
        
        // 重要度によって背景色を変更
        switch item.priority {
        case 0:
            cell.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3) // 高
        case 1:
            cell.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.3) // 中
        case 2:
            cell.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3) // 低
        default:
            cell.backgroundColor = UIColor.white
        }
        
        return cell
    }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "ToItemList",
               let itemListVC = segue.destination as? ItemListViewController,
               let indexPath = tableView.indexPathForSelectedRow {
                itemListVC.selectedShopIndex = indexPath.row
                itemListVC.shopItems = self.shopItems
            }
        }
        
        
        
        
        
}
