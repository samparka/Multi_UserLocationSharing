//
//  ContentView.swift
//  Multi_UserLocationSharing
//
//  Created by sam parker on 2023/12/16.
//

import SwiftUI
import Firebase
import CoreLocation
import MapKit
import FirebaseFirestoreInternalWrapper

struct ContentView: View {
    @State var name = ""
    @ObservedObject var obs = observer()
    var body: some View {
        VStack{
            TextField("输入昵称", text:$name).textFieldStyle(RoundedBorderTextFieldStyle())
            if name != ""{
                NavigationLink(destination: mapView(name: self.name, geopoints: self.obs.data["data"] as! [String : GeoPoint]).navigationBarTitle("",displayMode:  .inline)){
                    Text("共享位置")
                }
            }
            
        }.padding()
        .navigationTitle("位置共享")
        NavigationView{
            TextField("输入昵称", text:$name).textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct mapView : UIViewRepresentable {
    var name = ""
    var geopoints : [String : GeoPoint]
    
    func makeCoordinator() -> Coordinator {
        return mapView.Coordinator(parent1: self)
        }
        
    let map = MKMapView()
    let manager = CLLocationManager()
    func makeUIView(context: UIViewRepresentableContext<mapView>) -> MKMapView {
        manager.delegate = context.coordinator
        manager.startUpdatingLocation()
        map.showsUserLocation = true
        let center = CLLocationCoordinate2D(latitude: 34.42675260, longitude: 132.74375120)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000)
        map.region = region
        manager.requestWhenInUseAuthorization()
        return map
        }
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<mapView>) {
        
        for i in geopoints{
            if i.key != name{
                let point = MKPointAnnotation()
                point.coordinate = CLLocationCoordinate2D(latitude: i.value.latitude, longitude: i.value.longitude)
                point.title = i.key
                uiView.removeAnnotations(uiView.annotations)
                uiView.addAnnotation(point)
            }
            
        }
        }
}
        class Coordinator : NSObject,CLLocationManagerDelegate{
            var parent : mapView
            init(parent1 : mapView){
                parent = parent1
            }
            //缺少是否开启定位判定
            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                let last = locations.last
                
                let db = Firestore.firestore()
                db.collection("locations").document("sharing").setData(["updates" :[self.parent.name : GeoPoint(latitude: (last?.coordinate.latitude)!, longitude: ( last?.coordinate.longitude)!)]],merge: true) { (err) in
                    if err != nil{
                        print((err?.localizedDescription)!)
                        return
                    }
                    print("success")
                }
                
//                print(last?.coordinate.latitude)
            }
}
class observer : ObservableObject{
    @Published  var data = [String : Any]()
    init(){
        let db = Firestore.firestore()
        db.collection("locations").document("sharing").addSnapshotListener{(snap, err) in
            if err != nil{
                print((err?.localizedDescription)!)
                return
            }
            let updates = snap?.get("updates") as! [String : GeoPoint]
            self.data["data"] = updates
        }
    }
}
//final class ContentViewModel: NSObject, ObservableObject, CLLocationManagerDelegate{
//    @Published var region = MKCoordinateRegion(center:CLLocationCoordinate2D(latitude: 34.42675260, longitude: 132.74375120),span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//    var locationmanager: CLLocationManager?
//    
//    func CheckIfLocationServicesIsAble(){
//        if CLLocationManager.locationServicesEnabled(){
//            locationmanager = CLLocationManager()
//            locationmanager?.delegate = self
//        }else{
//            print("location is off")
//        }
//    }
//   private func CheckLocationAuthorization(){
//        guard let locationmanager = locationmanager else {return}
//        switch locationmanager.authorizationStatus {
//        case .notDetermined:
//            locationmanager.requestWhenInUseAuthorization()
//        case .restricted:
//            print("location is restricted")
//        case .denied:
//            print("location is denied")
//        case .authorizedAlways, .authorizedWhenInUse:
//            region = MKCoordinateRegion(center: locationmanager.location!.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//        @unknown default:
//            break
//        }
//    }
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        CheckLocationAuthorization()
//    }
//}
//



//struct ContentView_Previews: PreviewProvider {
//        static var previews: some View {
//            ContentView()
//        }
//}
