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
        createGroupButton.layer.cornerRadius = 10
        toJoinGroupButton.layer.cornerRadius = 10
    }

    @IBOutlet weak var createGroupButton: UIButton!
    @IBOutlet weak var toJoinGroupButton: UIButton!
    
    @IBAction func createGroupButtonTapped(_ sender: UIButton) {
        print("グループ作成ボタンが押されました")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let CreateGroupVC = storyboard.instantiateViewController(withIdentifier: "CreateGroupViewController") as? CreateGroupViewController {
                navigationController?.pushViewController(CreateGroupVC, animated: true)
            }
        }
}
