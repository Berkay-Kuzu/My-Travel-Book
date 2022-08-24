//
//  ViewController.swift
//  TravelBook
//
//  Created by Berkay Kuzu on 22.08.2022.
//

import UIKit   // Kütüphaneleri(UIKit, MapKit, CoreLocation) projeme import ediyorum.
import MapKit // Harita özellğini kullanmak için kullanıyorum.
import CoreLocation // Kullanıcının konumunu almak için kullanıyorum.
import CoreData // Core Data'yı almak için kullanıyorum.

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate { /* ViewControllerda bu protokollerden ve sınıflardan bazı fonksiyonları çağırmak için yazıyoruz.*/
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager() // CoreLocation'ı kullanmak için locationManager ouşturduk.
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // kullanıcının en iyi konumu alır.
        locationManager.requestWhenInUseAuthorization() // kullanıcı uygulamayı kullanırken konumu alır
        locationManager.startUpdatingLocation() // kullanıcının konumu almaya başlar.
        
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
            // ID kullanarak CoreData'daki verileri çekiyorum. Tıkladığımda boş ise bunu yapıyorum!
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString) //Böylece sadece id ile çağırabiliyoruz!
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        
                        
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("error")
            }
            
            
           
            
        } else {
            // Add New Data
        }
        
    }
    
    @objc func chooseLocation (gestureRecognizer:UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began { /*Dokunma işlemi başladıysa, dokunulan noktaları al! */
            
            let touchedPoint = gestureRecognizer.location(in: self.mapView) // Dokunulan noktayı aldım
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView) // Dokunulan noktayı koordinat sistemine çevirdik.
            
            chosenLatitude = touchedCoordinates.latitude /* touchedCoordinates içindeki latitude ve longitude'ları chosenLatitude değişkenine kaydettik. Böylece artık touchedCoordinates içindeki latitude ve longitude'ları kullanabiliyoruz.*/
            chosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
            
        }
        
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == "" { /* Sadece boş ise beni al ve haritamı değiştir! selectedTitle boş değilse enlem ve boylam vardır.*/
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) // Lokasyon oluşturdum
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Zoom Seviyesi
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        } else {
            //
        } // Kullanıcının yerini ne yapacağız? Bu fonksiyon güncellenen konumları bir dizi içinde veriyor [CLLocation]!
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation { //Kullanıcının yerini pin ile göstermek istemiyorum, tıklanan yer neresi ise orayı göstermek istiyorum.
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil { // pin'i yeniden dizayn edip yanına "i" detail disclosure butonu ekledik.
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    } // annotation'ı özelleştirip navigasyon eklemeye yarıyor!
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedTitle != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                
                if let placemark = placemarks { // if let kullanarak eğer placemark nil değilse bu işlemleri yap diyorum. Bunu optionallardan kurtulmak için yapıyorum. Optionallardan kurtulmak için bunu yapabilirsin.
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    } // Navigasyonu çalıştırmak için MKPlacemark adlı objeye sahip olmam gerek.
                }
            } /* Navigasyonu çalıştırmak için gerekli objeyi alıyorum.*/
        }
        
    } // "i" detail disclosure'a tıklandığını anlamamıza yarıyor!
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        //Core Data'yı kullanmaya başladık!
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
    
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle") /* İstediğim 5 değeri kaydettim*/
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        do {
            try context.save()
            print("success")
        } catch {
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil) //Bir önceki ekrana döndük!
        navigationController?.popViewController(animated: true)
    }
}

