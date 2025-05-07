//
//  ViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/04/23.
//

import UIKit

class ShopListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    var shopItems: [[Item]] = []
    
    weak var delegate: ItemAddViewControllerDelegate?
    
    
    @IBOutlet weak var tableView: UITableView!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toItemAddViewController",
           let itemAddVC = segue.destination as? ItemAddViewController {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    var myItems: [String] = ["Shop1", "Shop２", "Shop３"]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myItems.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShopCell", for: indexPath) as? ShopCell else {
            return UITableViewCell()
        }
        // お店の名前表示など
        let shops: [String] = ["スーパー", "ドラッグストア", "コンビニ"]
        cell.textLabel?.text = shops[indexPath.row]
        // tag1を取得
        if let titleText = cell.viewWithTag(1) as? UITextField {
            titleText.text = "\(myItems[indexPath.row])"
        }
        
        // ＋ボタンにタップ処理を追加！
        cell.addItemButton.tag = indexPath.row
        cell.addItemButton.addTarget(self, action: #selector(addItemButtonTapped(_:)), for: .touchUpInside)
        
        
        return cell
    }
    
    @IBAction func tapAdd(sender: AnyObject) {
        // myItemsに追加.
        myItems.append("ShopNEW")
        // TableViewを再読み込み.
        tableView.reloadData()
    }
    
    @IBAction func tapEdit(sender: AnyObject) {
        if isEditing {
            super.setEditing(false, animated: true)
            tableView.setEditing(false, animated: true)
        } else {
            super.setEditing(true, animated: true)
            tableView.setEditing(true, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // 削除のとき.
        if editingStyle == UITableViewCell.EditingStyle.delete {
            // 指定されたセルのオブジェクトをmyItemsから削除する.
            myItems.remove(at: indexPath.row)
            // TableViewを再読み込み.
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAtIndexPath sourceIndexPath: IndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
    }
    
    
    
    
    @objc func addItemButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let itemAddVC = storyboard.instantiateViewController(withIdentifier: "ItemAddViewController") as? ItemAddViewController {
            itemAddVC.selectedShopIndex = sender.tag
            itemAddVC.delegate = self
            self.present(itemAddVC, animated: true, completion: nil)
        }
    }
    
    
   
}

extension ShopListViewController: ItemAddViewControllerDelegate {
    func didAddItem(_ item: Item, toShopAt index: Int) {
        shopItems[index].append(item)
        tableView.reloadData()
    }
}
