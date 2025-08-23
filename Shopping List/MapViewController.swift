//
//  MapViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit
import MapKit
import CoreLocation


protocol MapViewControllerDelegate: AnyObject {
    func didSelectLocation(latitude: Double, longitude: Double)
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    weak var delegate: MapViewControllerDelegate?
    
    var selectedCoordinate: CLLocationCoordinate2D?
    var groupId: String!
    var shops: [Shop] = []
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.showsUserLocation = true

        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    
        // 長押しジェスチャー追加（ピンを立てる用）
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
    }
    
    var hasSetIntialRegion = false
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        for shop in shops {
            let shopLocation = CLLocation(latitude: shop.latitude, longitude: shop.longitude)
            let distance = location.distance(from: shopLocation)
            
            if distance < 50 { // 50m以内
                let remainingItems = shop.items.filter { !$0.isChecked }
                if !remainingItems.isEmpty {
                    sendLocalNotification(shop: shop, items: remainingItems)
                }
            }
        }
    }

    func sendLocalNotification(shop: Shop, items: [Item]) {
        let content = UNMutableNotificationContent()
        content.title = "\(shop.name)の買い物リスト"
        content.body = items.map { $0.name }.joined(separator: ", ") + " がまだ残っています"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            // 既存のピンを消して新しく追加
            mapView.removeAnnotations(mapView.annotations)

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            selectedCoordinate = coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("現在地の取得に失敗しました: \(error.localizedDescription)")
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        guard let coordinate = selectedCoordinate else  {
            print("座標が選ばれていません")
            return
        }
        print("完了ボタンが押された！緯度: \(coordinate.latitude), 経度: \(coordinate.longitude)")
            delegate?.didSelectLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        dismiss(animated: true, completion: nil)

        
       
    }
    
}
