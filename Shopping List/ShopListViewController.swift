//
//  ViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/04/23.
//

import UIKit

class ShopListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var shops: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shops.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShopCell", for: indexPath) as? ShopCell else{
            return UITableViewCell()
        }
        cell.shopNameLabel.text = shops[indexPath.row]
        
        cell.addItemButton.tag = indexPath.row
        cell.addItemButton.addTarget(self, action: #selector(addItemButtonTapped(_:)), for: .touchUpInside)
        
        return cell
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
}
    
   
extension ShopListViewController: ShopAddViewControllerDelegate {
    func didAddShop(name: String, latitude: Double, longitude: Double) {
        shops.append(name)
        tableView.reloadData()
    }
}
