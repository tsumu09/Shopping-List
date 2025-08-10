//
//  TotalAmountViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/09.
//

import UIKit
import FirebaseFirestore

class TotalAmountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var passedShopName: String?   // 外部から渡された選択された店名（単一）
    var fetchedShopNames: [String] = []  // Firestoreから取得した全店名
    var shopName: [String] = []
    var shops: [Shop] = []
    
    let db = Firestore.firestore()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shopnameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchShopNames()

        if let name = passedShopName {
            shopnameLabel.text = name
        }
        tableView.dataSource = self
        tableView.delegate = self
    }

    func fetchShopNames() {
        db.collection("shops").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Failed to fetch shops: \(error)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            
            print("Fetched documents count: \(documents.count)")
            
            self?.fetchedShopNames = documents.compactMap { doc in
                let name = doc.data()["name"] as? String
                print("Shop name: \(name ?? "nil")")
                return name
            }
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemGroupedBackground
        
        let nameLabel = UILabel(frame: CGRect(x: 50, y: 10, width: 200, height: 40))
        nameLabel.text = fetchedShopNames[section]
        headerView.addSubview(nameLabel)
        
        return headerView
    }
    // テーブルビューのデータソース
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedShopNames.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedShopNames.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ShopCell", for: indexPath)
        cell.textLabel?.text = fetchedShopNames[indexPath.row]
        return cell
    }
}
