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
        if !hasSetIntialRegion, let userLocation = locations.first {
            let region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
            hasSetIntialRegion = true
        }
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
