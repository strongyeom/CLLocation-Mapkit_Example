//
//  ViewController.swift
//  CLLocation+Mapkit_Example
//
//  Created by 염성필 on 2023/08/23.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        locationManager.delegate = self
       
        checkDeviceLocationAuthorization()
    }
    
    func checkDeviceLocationAuthorization() {
        
        DispatchQueue.global().async {
            // 위치 서비스를 이용 할 수 있다면
            if CLLocationManager.locationServicesEnabled() {
                
                let authorization: CLAuthorizationStatus
                
                if #available(iOS 14.0, *) {
                    // 열거형에 해당하는 element를 authorization 할당
                    authorization = self.locationManager.authorizationStatus
                } else {
                    authorization = CLLocationManager.authorizationStatus()
                }
                print("checkDeviceLocationAuthorization - authorization",authorization.rawValue)
                // 실질적으로 main 화면에 alert을 띄어주는 부분이기 때문에 mainThread에서 작업한다.
                DispatchQueue.main.async {
                    self.checkCurrentLocationAutorization(status: authorization)
                }
            }
        }
        
    }
    
    // 권한 설정에 따른 호출 메서드
    func checkCurrentLocationAutorization(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("아무것도 권한 설정이 안되어있다")
            // p.list에 저장한 알럿 띄우기
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("애기들 권한 막아놈")
        case .denied:
            print("권한 거부")
        case .authorizedAlways:
            print("항상 권한 허용")
        case .authorizedWhenInUse:
            print("한번만 권한 허용")
            // 성공적으로 위치를 받아오면 델리게이트로 설정한 didUpdateLocations() 실행
            locationManager.startUpdatingLocation()
        case .authorized:
            print("authorized")
        @unknown default:
            print("추가된 것이 있을때")
        }
    }
    
    
}

extension ViewController: CLLocationManagerDelegate {
    // 성공했을 경우
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("위치 권한을 성공적으로 받아왔을때",locations)
        
    }
    // 실패했을 경우
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 권한을 받아오지 못했을때")
    }
    
    // 권한에 달라짐에 따라 호출
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("위치 권한이 바뀔때마다 호출 된다.")
        // 권한이 바뀔때마다 다시 권한 적용
        checkDeviceLocationAuthorization()
    }
}

