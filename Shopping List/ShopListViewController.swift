//
//  ViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/04/23.
//

import UIKit

class ShopListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    

    var shops: [Shop] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadCheckStates()
        tableView.reloadData()
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShopCell", for: indexPath) as? ShopCell else{
                return UITableViewCell()
            }
        
            cell.shopNameLabel.text = shops[indexPath.section].name
            cell.addItemButton.tag = indexPath.section
            cell.addItemButton.addTarget(self, action: #selector(addItemButtonTapped(_:)), for: .touchUpInside)
            
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShopItemCell", for: indexPath) as? ShopItemCell else{
                return UITableViewCell()
            }
            let item = shops[indexPath.section].items[indexPath.row - 1]
            cell.nameLabel.text = item.name
            cell.isChecked = item.isChecked
            
            cell.toggleCheckAction = { [weak self] in
                item.isChecked.toggle()
                cell.isChecked = item.isChecked
                self?.saveCheckStates()
            }
            
            return cell
        }
    }
    
    @IBAction func addShopButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let shopAddVC = storyboard.instantiateViewController(withIdentifier: "ShopAddViewController") as? ShopAddViewController {
            shopAddVC.delegate = self
            navigationController?.pushViewController(shopAddVC, animated: true)
        }
    }
    
    @IBAction func editPositionButtonTapped(_ sender: UIButton) {
        tableView.isEditing.toggle()
    }
    
    @objc func addItemButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let itemAddVC = storyboard.instantiateViewController(withIdentifier: "ItemAddViewController") as? ItemAddViewController {
            itemAddVC.selectedShopIndex = index
            navigationController?.pushViewController(itemAddVC, animated: true)
        }
    }
    
    func didAddItem(_ item: Item, toShopAt index: Int) {
        shops[index].items.append(item)
        tableView.reloadData()
    }
    
    
    // セクションの数 = お店の数
    func numberOfSections(in tableView: UITableView) -> Int {
        return shops.count
    }

    // 各セクションに表示する商品の数（isExpandedで制御）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + shops[section].items.count
    }

    // 各商品のセル
    

    // セクションヘッダーの表示（お店の名前＋ボタン）
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemGroupedBackground
        
        let nameLabel = UILabel(frame: CGRect(x: 16, y: 0, width: 200, height: 40))
        nameLabel.text = shops[section].name
        headerView.addSubview(nameLabel)
        
        let toggleButton = UIButton(frame: CGRect(x: tableView.frame.width - 80, y: 5, width: 70, height: 30))
        toggleButton.setTitle(shops[section].isExpanded ? "閉じる" : "表示", for: .normal)
        toggleButton.setTitleColor(.systemBlue, for: .normal)
        toggleButton.tag = section
        toggleButton.addTarget(self, action: #selector(toggleItems(_:)), for: .touchUpInside)
        headerView.addSubview(toggleButton)
        
        return headerView
    }

    @objc func toggleItems(_ sender: UIButton) {
        let section = sender.tag
        shops[section].isExpanded.toggle()
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }
    
    @objc func detailButtonTapped(_ sender: UIButton) {
        let section = sender.tag
        let selectedShop = shops[section]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let itemListVC = storyboard.instantiateViewController(withIdentifier: "ItemListViewController") as? ItemListViewController {
            itemListVC.shop = selectedShop
            navigationController?.pushViewController(itemListVC, animated: true)
        }
    }
    
    func saveCheckStates() {
        var checkStates: [[Bool]] = []
        for shop in shops {
            let itemStates = shop.items.map { $0.isChecked }
            checkStates.append(itemStates)
        }
        UserDefaults.standard.set(checkStates, forKey: "CheckStates")
    }
    
    func loadCheckStates() {
        if let saveStates = UserDefaults.standard.array(forKey: "CheckStates") as? [[Bool]] {
            for (shopIndex, itemStates) in saveStates.enumerated() {
                if shopIndex < shops.count {
                    for (itemIndex, state) in itemStates.enumerated() {
                        shops[shopIndex].items[itemIndex].isChecked = state
                    }
                }
            }
        }
    }
    
}
    
   
extension ShopListViewController: ShopAddViewControllerDelegate {
    func didAddShop(name: String, latitude: Double, longitude: Double) {
        let newShop = Shop(name: name, latitude: latitude, longitude: longitude, items: [])
        shops.append(newShop)
        tableView.reloadData()
    }
}
