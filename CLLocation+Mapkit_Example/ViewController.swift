//
//  ViewController.swift
//  CLLocation+Mapkit_Example
//
//  Created by 염성필 on 2023/08/23.
//

import UIKit
import CoreLocation
import MapKit
import SnapKit

enum MovieTheaterEnum: String {
    case lotte = "롯데시네마"
    case megaBox = "메가박스"
    case cgv = "CGV"
    case all
    
}

class ViewController: UIViewController {
    
    let locationManager = CLLocationManager()
    let mapView = MKMapView()
    let theaterList = TheaterList()
    
    
    
    
    let currentButton = {
        let button = UIButton()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
        let image = UIImage(systemName: "location.fill", withConfiguration: imageConfig)
        button.setTitle("", for: .normal)
        button.setImage(image, for: .normal)
        return button
    }()
    
    var authorization: CLAuthorizationStatus = .notDetermined
    var movieTheaterType: MovieTheaterEnum = .all
    
    // 델리게이트 didUpdateLocations() 메서드에서 만들어진 위 경도를 활용하기 위해 변수 만듬
    var startPoint: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        
        locationManager.delegate = self
        settingNavigationBar()
        settingMapView()
        settingCurrentBtn()
        checkDeviceLocationAuthorization()
        
        
        
    }
    
    // 필터링한 어노테이션만 보여주기
    func filterMovieAnnotation(type: MovieTheaterEnum) {
        // mapView 싹 지우기
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        // 필터된 Theater 담기
        var filterdResult: [Theater]
        // 모든 type을 한번에 스캔 하기 위해서 배열로 만듬
        let theaterTypeList = theaterList.mapAnnotations.map { $0.type }
        // 어떤 조건에 의해서 반복문을 만들 것인가
        if theaterTypeList.contains(type.rawValue) {
            // 필터가 된 것들만 filterdResult에 담기
            filterdResult = theaterList.mapAnnotations.filter { $0.type.contains(type.rawValue) }
        } else {
            // 포함되지 않았으면 몽땅 담아라
            filterdResult = theaterList.mapAnnotations
        }
       
        // 이게 어떤 클로저문 안에서 반복적으로 하나씩 다 만들어진 다음에 -> [MKPointAnnotation]이 형식이 되어야함
        let theatherAnnotationPositions = filterdResult.map { value -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = value.location
            annotation.coordinate = CLLocationCoordinate2D(latitude: value.latitude, longitude: value.longitude)
            return annotation
        }
        
        self.mapView.addAnnotations(theatherAnnotationPositions)
    }

func settingMapView() {
    // View에 mapView 올리기
    view.addSubview(mapView)
    
    // mapView 레이아웃 설정
    mapView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
    }
}

func settingNavigationBar() {
    title = "지역 영화관"
    // 코드로 navigationBar 영역부분 분리도 주기
    navigationController?.navigationBar.scrollEdgeAppearance = UINavigationBarAppearance()
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filterBarButtonClicked(_:)))
    
}

@objc func filterBarButtonClicked(_ sender: UIBarButtonItem) {
    print("필터 버튼 눌림")
    
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
    let lotte = UIAlertAction(title: "롯데시네마", style: .default) { _ in
        print("롯데시네마 눌림")
        self.filterMovieAnnotation(type: .lotte)
        
    }
    
    let megaBox = UIAlertAction(title: "메가박스", style: .default) { _ in
        print("메가박스 눌림")
        self.filterMovieAnnotation(type: .megaBox)
    }
    
    let cgv = UIAlertAction(title: "cgv", style: .default) { _ in
        print("cgv 눌림")
        self.filterMovieAnnotation(type: .cgv)
    }
    
    let allMovieTheater = UIAlertAction(title: "전체영화관", style: .default) { _ in
        print("전체영화관 눌림")
        // 옵셔널 바인딩
        guard let currentPoint = self.startPoint else { return }
        self.filterMovieAnnotation(type: .all)
        // 전체영화관 눌렸을때 현재 위치의 Annotation도 추가하기위해 setRegionAndAnnotation 메서드 사용
        self.setRegionAndAnnotation(center: currentPoint)
        
        
    }
    let cancel = UIAlertAction(title: "취소", style: .cancel)
    
    [lotte, megaBox, cgv, allMovieTheater, cancel].forEach {
        alert.addAction($0)
    }
    
    present(alert, animated: true)
}

func settingCurrentBtn() {
    view.addSubview(currentButton)
    currentButton.addTarget(self, action: #selector(currentLocationBtnClicked(_:)), for: .touchUpInside)
    currentButton.tintColor = .red
    currentButton.snp.makeConstraints { make in
        make.top.equalTo(view.safeAreaInsets).offset(150)
        make.trailing.equalTo(view.safeAreaInsets).inset(30)
    }
}

// 권한이 거부되어있다면 iOS 설정 화면으로 이동하는 Alert 띄우기
@objc func currentLocationBtnClicked(_ sender: UIButton) {
    print("현재 위치 불러오기 ", authorization.rawValue)
    
    let status = authorization
    
    if status == CLAuthorizationStatus.denied {
        showLocationSettingAlert()
    } else if status == CLAuthorizationStatus.authorizedWhenInUse {
        let alert = UIAlertController(title: "위치 설정 완료", message: "현재 위치로 설정 되어있습니다.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default)
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
}

// 내가 위치한 지역과 핀(Annotation) 설정
func setRegionAndAnnotation(center: CLLocationCoordinate2D) {
    // 디바이스 현재 위도 경도 CLLocationCoordinate2D(latitude: 37.517926, longitude: 126.886371)
    // 37.526384, 126.896269
    let region = MKCoordinateRegion(center: center, latitudinalMeters: 12000, longitudinalMeters: 12000)
    // mapView에 보여주기
    mapView.setRegion(region, animated: true)
    
    // 현재 위치 핀 찍기
    let annotation = MKPointAnnotation()
    annotation.title = "임시 거점"
    annotation.coordinate = center
    mapView.addAnnotation(annotation)
    
}

// 권한 - 허용안함을 눌렀을때 Alert 띄우고 iOS 설정 화면으로 이동
func showLocationSettingAlert() {
    let alert = UIAlertController(title: "위치 정보 설정", message: "설정>개인 정보 보호 > 위치 여기로 이동해서 당장 진행시켜", preferredStyle: .alert)
    let goSetting = UIAlertAction(title: "위치 설정하기", style: .default) { _ in
        // iOS 설정 페이지로 이동 : openSettingsURLString
        if let appSetting = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSetting)
        }
    }
    let cancel = UIAlertAction(title: "취소", style: .cancel) { _ in
        // 청취사 위 경도 지정
        let kungchsa = CLLocationCoordinate2D(latitude: 37.517926, longitude: 126.886371)
        
        self.setRegionAndAnnotation(center: kungchsa)
    }
    
    alert.addAction(goSetting)
    alert.addAction(cancel)
    present(alert, animated: true)
}

// 상태가 바뀔때마다 권한 확인
func checkDeviceLocationAuthorization() {
    
    DispatchQueue.global().async {
        // 위치 서비스를 이용 할 수 있다면
        if CLLocationManager.locationServicesEnabled() {
            
            
            // authorization: CLAuthorizationStatus
            if #available(iOS 14.0, *) {
                // 열거형에 해당하는 element를 authorization 할당
                self.authorization = self.locationManager.authorizationStatus
            } else {
                self.authorization = CLLocationManager.authorizationStatus()
            }
            print("checkDeviceLocationAuthorization - authorization",self.authorization.rawValue)
            // 실질적으로 main 화면에 alert을 띄어주는 부분이기 때문에 mainThread에서 작업한다.
            DispatchQueue.main.async {
                
                self.checkCurrentLocationAutorization(status: self.authorization)
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
        showLocationSettingAlert()
    case .authorizedAlways:
        print("항상 권한 허용")
    case .authorizedWhenInUse:
        print("한번만 권한 허용")
        // 성공적으로 위치를 받아오면 델리게이트로 설정한 didUpdateLocations() 실행
        filterMovieAnnotation(type: .all)
        print("맵뷰에 어떤게 올라가 있나요? ",mapView.annotations.map { $0.title!})
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
        if let coordinate = locations.last?.coordinate {
            setRegionAndAnnotation(center: coordinate)
            print("현재 위치 : \(mapView.annotations.map { $0.title!})")
            startPoint = coordinate
        }
        
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

