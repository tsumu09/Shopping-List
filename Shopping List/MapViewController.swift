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

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    weak var delegate: MapViewControllerDelegate?
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let coordinate = view.annotation?.coordinate {
            delegate?.didSelectLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBOutlet weak var mapView: MKMapView!

    let locationManager = CLLocationManager()

    // ピンの位置（後で他の画面に渡したいならここに保存する）
    var selectedCoordinate: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        mapView.showsUserLocation = true

        // 長押しジェスチャー追加（ピンを立てる用）
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }

        // 最初だけ現在地に移動（何回もやらないようにstop）
        let region = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation()
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .began { return }

        let touchPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        // 既存のピンを消して新しく追加
        mapView.removeAnnotations(mapView.annotations)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "お店の場所"
        mapView.addAnnotation(annotation)

        // 選択された座標を保存
        selectedCoordinate = coordinate

        print("選ばれた緯度: \(coordinate.latitude), 経度: \(coordinate.longitude)")
        
        delegate?.didSelectLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        navigationController?.popViewController(animated: true)
    }
}
