//
//  GroupViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/22.
//
import UIKit

class GroupViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func createGroupButtonTapped(_ sender: UIButton) {
        print("グループ作成ボタンが押されました")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let createVC = storyboard.instantiateViewController(withIdentifier: "CreateViewController") as? CreateViewController {
                navigationController?.pushViewController(createVC, animated: true)
            }
        }
}
