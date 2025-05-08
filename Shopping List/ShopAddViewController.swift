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
    
    @IBOutlet weak var shopNameTextField: UITextField!
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMap",
           let mapVC = segue.destination as? MapViewController {
            mapVC.delegate = self
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let name = shopNameTextField.text, !name.isEmpty,
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
