//
//  ShopAddViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit
import CoreLocation

protocol ShopAddViewControllerDelegate: AnyObject {
    func didAddShop(name: String, coordinate: CLLocationCoordinate2D)
}

class ShopAddViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var selectLocationButton: UIButton!

    weak var delegate: ShopAddViewControllerDelegate?

    var selectedCoordinate: CLLocationCoordinate2D?
    var selectLatitude: Double?
    var selectLongitude: Double?
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMap" {
            if let mapVC = segue.destination as? MapViewController {
                mapVC.delegate = self
            }
        }
    }

    @IBAction func mapButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showMap", sender: nil)
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
              let coordinate = selectedCoordinate else {
            return
        }

        delegate?.didAddShop(name: name, coordinate: coordinate)
        navigationController?.popViewController(animated: true)
    }
}
extension ShopAddViewController: MapViewControllerDelegate {
    func didSelectLocation(latitude: Double, longitude: Double) {
        selectLatitude = latitude
        selectLongitude = longitude
        print("選択したいち - 緯度: \(latitude), 経度: \(longitude)")
    }
}
