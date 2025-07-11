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
    
    var saveDate:UserDefaults = UserDefaults.standard
    
    var shops: [Shop] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func selectLocationButtonTapped(_ sender: UIButton) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapView",
           let mapVC = segue.destination as? MapViewController {
            mapVC.delegate = self
        }
    }
    
    func didSelectLocation(latitude: Double, longitude: Double) {
        selectLatitude = latitude
        selectLongitude = longitude
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let name = shopNameTextField.text, !name.isEmpty else {
            print("お店の名前が空です")
            return
        }
        
        guard let lat = selectLatitude, let lon = selectLongitude else {
            print("座標が設定されていません")
            return
        }
        print("保存ボタンが押された！name: \(name), lat: \(lat), lon: \(lon)")
        let shop = Shop(name: name, latitude: lat , longitude: lon, items: [], isExpanded: true )
        shops.append(shop)
//        saveDate.set(shops, forKey: "shops")
        if let encoded = try? JSONEncoder().encode(shops) {
            UserDefaults.standard.set(encoded, forKey: "shops")
        }
        startMonitoringShop(shop: shop)
        
        
        delegate?.didAddShop(name: name, latitude: lat, longitude: lon)
        navigationController?.popViewController(animated: true)
    }
    
    func startMonitoringShop(shop: Shop) {
        let center = CLLocationCoordinate2D(latitude: shop.latitude, longitude: shop.longitude)
        let region = CLCircularRegion(center: center, radius: 100, identifier: shop.name)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        locationManager.startMonitoring(for: region)
      
    }
    
}

