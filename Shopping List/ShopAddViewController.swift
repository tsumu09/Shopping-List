//
//  ShopAddViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit
import UserNotifications
import CoreLocation

protocol ShopAddViewControllerDelegate: AnyObject {
    func didAddShop(name: String, latitude: Double, longitude: Double)
}

class ShopAddViewController: UIViewController, MapViewControllerDelegate {
    
    var selectLatitude: Double?
    var selectLongitude: Double?
    var saveDate:UserDefaults = UserDefaults.standard
    var shops: [Shop] = []
    var groupId: String!
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var shopNameTextField: UITextField!
    
    weak var delegate: ShopAddViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func selectLocationButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mapVC = storyboard.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
        mapVC.delegate = self // 位置情報を受け取るため

        // モーダル表示のスタイルを設定
        mapVC.modalPresentationStyle = .pageSheet // or .pageSheet
        present(mapVC, animated: true, completion: nil)
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
        
//        startMonitoringShop(shop: shop)
        
        FirestoreManager.shared.addShop(
                    to: groupId,
                    name: name,
                    latitude: lat,
                    longitude: lon
                ) { [weak self] error in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let err = error {
                            self.presentAlert(title: "登録失敗",message: err.localizedDescription)
                        } else {
                            
                        self.navigationController?
                                .popViewController(animated: true)
                        }
                    }
                }
    }
    
    func startMonitoringShop(shop: Shop) {
        let center = CLLocationCoordinate2D(latitude: shop.latitude, longitude: shop.longitude)
        let region = CLCircularRegion(center: center, radius: 100, identifier: shop.name)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        locationManager.startMonitoring(for: region)
      
    }
    
    private func presentAlert(title: String, message: String) {
            let a = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
            a.addAction(.init(title: "OK", style: .default))
            present(a, animated: true)
        }
}

