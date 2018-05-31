//
//  ViewController.swift
//  VoltLinesExercise
//
//  Created by Alaa Al-Zaibak on 25.05.2018.
//  Copyright © 2018 Alaa Al-Zaibak. All rights reserved.
//

import UIKit
import GoogleMaps
import SnapKit

class ViewController: UIViewController {

    private var locationManager = CLLocationManager()
    private var geocoder = CLGeocoder()
    private var mapView : GMSMapView!
    private var stopsCountLabel : UILabel!

    private var stopMarkersDictionary : [String : GMSMarker]?
    var viewModel : MarkerListViewModel? {
        didSet {
            refreshMarkers()
            stopsCountLabel.text = viewModel?.stopsCountText
        }
    }

    // Rio De Janeiro location
//    private var latitude : Double = -22.891144
//    private var longitude : Double = -43.225440
    private var radius : Double = 1650
//    // Levant location
    private var latitude : Double = 41.080037
    private var longitude : Double = 29.008330
    private var currentRegionName = ""

    private var pullUpControllerAdded = false
    private var markerTooltipViewController : MarkerTooltipViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        stopsCountLabel = UILabel(frame: CGRect.zero)
        stopsCountLabel.textColor = UIColor.orange
        stopsCountLabel.textAlignment = .center
        stopsCountLabel.font = UIFont(name: "Helvetica", size: 20)
        self.view.addSubview(stopsCountLabel)
        stopsCountLabel.snp.makeConstraints { (constraintMaker) in
            if #available(iOS 11, *) {
                constraintMaker.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            } else {
                constraintMaker.top.equalToSuperview()
            }
            constraintMaker.height.equalTo(50)
            constraintMaker.leading.equalToSuperview()
            constraintMaker.trailing.equalToSuperview()
        }

        loadGoogleMap(withLatitude: latitude, longitude: longitude)
        loadStops(atLatitude: latitude, longitude: longitude, radius: 1650)
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Private Methods

    /* Loads google map viewing the passed location
     */
    private func loadGoogleMap(withLatitude lat: Double, longitude long: Double) {

        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 15.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = self
        mapView.isMyLocationEnabled = true

        view.addSubview(mapView)

        mapView.snp.makeConstraints { (constraintMaker) in
            if #available(iOS 11, *) {
                constraintMaker.top.equalTo(stopsCountLabel.snp.bottom)
                constraintMaker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            } else {
                constraintMaker.top.equalToSuperview()
                constraintMaker.bottom.equalToSuperview()
            }
            constraintMaker.leading.equalToSuperview()
            constraintMaker.trailing.equalToSuperview()
        }
    }

    /* Loads the stops at the location using TrafiAPIManager, and create markers for them on the map.
     * It shows an alert to the user if an error occurred
     */
    private func loadStops(atLatitude lat: Double, longitude long: Double, radius: Double) {
        TrafiAPIManager.default.retreiveStops(atLatitude: lat, longitude: long, radius: radius) { (stopsArray, error) in
            guard error == nil else {
                // Show an alert to the user if an error occurred
                let alert = UIAlertController(title: "Error!", message: "Can't connect to the server, please try again later!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            guard let stops = stopsArray else {
                // Do nothing if there are no stops in the array
                return
            }

            self.viewModel = MarkerListViewModel(stops: stops)
        }
    }

    /* Loads stop schedules using TrafiAPIManager, and set them in the marker tooltip view.
     */
    private func loadStopSchedules(for marker: GMSMarker, viewController: MarkerTooltipViewController) {
        guard let markerViewModel = marker.userData as? MarkerViewModel else {
            return
        }
        let stop = markerViewModel.stop

        var regionName = currentRegionName.lowercased()
        let regionNameComponents = regionName.components(separatedBy: " ")
        if regionNameComponents.count > 0 {
            regionName = regionNameComponents[0]
        }

        TrafiAPIManager.default.retreiveStopDepartures(for: stop, region: regionName) { (success, error) in
            guard success || error == nil else {
                // Show an alert to the user if an error occurred
                let alert = UIAlertController(title: "Error!", message: "Can't connect to the server, please try again later!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }

            markerViewModel.reloadStopInfo()
            viewController.reloadViewModel()
        }
    }

    private func refreshMarkers() -> Void {
        var newMarkers = [String : GMSMarker]()

        // create marker for each marker model view and set its properties (reuse existing marker if it has the same id)
        if let markerViewModels = viewModel?.markerViewModels {
            for markerViewModel in markerViewModels {
                var marker = stopMarkersDictionary?.removeValue(forKey: markerViewModel.id)
                if marker == nil {
                    marker = GMSMarker()
                    // Add the stop to the marker as user data to be used later if needed
                    marker?.map = self.mapView
                }

                newMarkers[markerViewModel.id] = marker

                marker?.position = markerViewModel.position
                marker?.title = markerViewModel.title
                marker?.userData = markerViewModel
            }
        }

        // Remove old markers from the map
        if let markers = stopMarkersDictionary?.values {
            for marker in markers {
                marker.map = nil
                marker.userData = nil
            }
        }

        // set markers dictionary
        self.stopMarkersDictionary = newMarkers
    }
}

extension ViewController : GMSMapViewDelegate {

    // we need this delegate method to know if the zoom was changed (and we keep the position for loading stops to be the same)
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        let leftCoordinates = mapView.projection.visibleRegion().nearLeft;
        let rightCoordinates = mapView.projection.visibleRegion().nearRight;
        let distance = Utilities.default.getDistanceMetresBetweenLocationCoordinates(leftCoordinates, rightCoordinates);

        let radius = distance
        if abs(self.radius - radius) > 50 {
            self.radius = radius
            loadStops(atLatitude: self.latitude, longitude: self.longitude, radius:self.radius)
        }
    }
}

extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let location = locations.last else {
            return
        }

        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        let currentZoom = mapView.camera.zoom
        let cameraPosition = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: currentZoom)

        self.mapView?.animate(to: cameraPosition)

        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            guard let placemarks = placemarks else {
                return
            }
            guard placemarks.count > 0 else {
                return
            }

            let currentLocPlacemark = placemarks[0]
            self.currentRegionName = currentLocPlacemark.locality ?? ""
        }
        // Stop updating location
        self.locationManager.stopUpdatingLocation()
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let markerViewModel = marker.userData as? MarkerViewModel else {
            return false
        }
        if let currentMarkerTooltipViewController = markerTooltipViewController {
            currentMarkerTooltipViewController.view.removeFromSuperview()
            currentMarkerTooltipViewController.removeFromParentViewController()
        }

        let markerTooltipViewFrame = CGRect(x: 0, y: 0, width: mapView.frame.width, height: mapView.frame.height * 0.3)
        let markerTooltipView = MarkerTooltipView(frame: markerTooltipViewFrame)
        markerTooltipView.viewModel = markerViewModel.tooltipViewModel

        markerTooltipViewController = MarkerTooltipViewController()
        if let currentMarkerTooltipViewController = markerTooltipViewController {
            currentMarkerTooltipViewController.markerTooltipView = markerTooltipView
            self.addPullUpController(currentMarkerTooltipViewController)
            loadStopSchedules(for: marker, viewController: currentMarkerTooltipViewController)
        }

        return true
    }
}
