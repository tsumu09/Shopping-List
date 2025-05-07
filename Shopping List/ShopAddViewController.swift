//
//  ShopAddViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit
import CoreLocation

protocol ShopAddViewControllerDelegate: AnyObject {
    func didAddShop(name: String, latitude: Double, longitude: Double)
}

class ShopAddViewController: UIViewController, MapViewControllerDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    weak var delegate: ShopAddViewControllerDelegate?
    
    var selectLatitude: Double?
    var selectLongitude: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func selectLocationButtonTapped(_ sender: UIButton) {
        // 地図を開く処理（MapViewControllerへ遷移）
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mapVC = storyboard.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
            mapVC.delegate = self
            navigationController?.pushViewController(mapVC, animated: true)
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty,
        let lat = selectLatitude,
        let lon = selectLongitude else {
            return
        }
        
        delegate?.didAddShop(name: name, latitude: lat, longitude: lon)
        navigationController?.popViewController(animated: true)
    }
    
    func didSelectLocation(latitude: Double, longitude: Double) {
        selectLatitude = latitude
        selectLongitude = longitude
    }
    
}
