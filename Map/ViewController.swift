//
//  ViewController.swift
//  Map
//
//  Created by iScene on 2015/07/14.
//  Copyright (c) 2015年 bar2. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

	@IBOutlet weak var mvMap: MKMapView!
	
	// ロケーション情報管理オブジェクト
	var lm: CLLocationManager!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		
		// ロケーション情報管理オブジェクト設定（デリゲート）
		lm = CLLocationManager()
		lm.delegate = self
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	// MARK: - MKMapViewDelegate Method
	
	// 地図表示の変更後
	func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
		
		// 中央位置の取得
		var crd = mapView.centerCoordinate
		
		// 領域の取得
		var spn = mapView.region.span
		
		// 表示
		NSLog("位置{%.2f, %.2f}, 領域{%.2f, %.2f}",
			crd.latitude, crd.longitude,
			spn.latitudeDelta, spn.longitudeDelta)
	}
	
	// アノテーション表示の管理
	func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
		
		// 現在地表示の場合
		if annotation.isKindOfClass(MKUserLocation) {
			return nil
		}
		
		
		// 再利用可能オブジェクト取得
		var pa = mapView.dequeueReusableAnnotationViewWithIdentifier("pin")
			as! MKPinAnnotationView!
		
		// 再利用可能オブジェクト有無判定
		if pa == nil {

			// オブジェクト生成
			pa = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
			
			// 設定
			// （ドロップ時アニメーション）
			pa.animatesDrop = true
			// （ピンの色）
			pa.pinColor = MKPinAnnotationColor.Green
			// （ピンタップ時の情報表示）
			pa.canShowCallout = true
		}
		
		return pa
	}
	
	
	// MARK: - CLLocationManagerDelegate Method
	
	// 認証ステータス変更後
	func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		
		// 位置情報の使用不許可時
		if status == CLAuthorizationStatus.NotDetermined {
			
			// 位置情報の使用許可要求
			lm.requestWhenInUseAuthorization()	// アプリ起動時のみ許可
		}
	}


	// MARK: - Action Method

	// returnキー押下
	@IBAction func pushKeyReturn(sender: AnyObject) {
		//
	}

	// 地名検索（ジオコーティング）
	@IBAction func searchPlace(sender: UITextField) {
		
		// ジオコーダーオブジェクト生成
		var gc = CLGeocoder()
		
		// 設定（ジオコーディング処理）
		var hnd: CLGeocodeCompletionHandler = { (placemarks: [AnyObject]!, error: NSError!) -> Void in
			
			// 該当なし
			if placemarks == nil {
				return
			}
			
			// 位置の設定
			var pmk = placemarks[0] as! CLPlacemark
			var lc = pmk.location.coordinate
			
			// 表示領域の設定
			var sp = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
			
			// 地図の表示
			var cr = MKCoordinateRegion(center: lc, span: sp)
			self.mvMap.setRegion(cr, animated: true)
		}
		
		// ジオコーディング実行
		gc.geocodeAddressString(sender.text, completionHandler: hnd)
	}
	
	// [3D]ボタン押下
	@IBAction func change3D(sender: AnyObject) {
		
		// 地図の中心地点
		var centerCoordinate = CLLocationCoordinate2D(
			latitude: 34.687277, longitude: 135.525856)
		
		// カメラのセット地点
		var fromEyeCoordinate = CLLocationCoordinate2D(
			latitude: 34.689659, longitude: 135.518367)
		
		// 500m上空からの視点
		var eyeAltitude: CLLocationDistance = 500.0
		
		// カメラをセット
		var camera = MKMapCamera(
			lookingAtCenterCoordinate: centerCoordinate,
			fromEyeCoordinate: fromEyeCoordinate,
			eyeAltitude: eyeAltitude)
		mvMap.setCamera(camera, animated: true)
	}
	
	// マップタイプ選択
	@IBAction func selectStyle(sender: UISegmentedControl) {
		
		// ボタン判定
		switch sender.selectedSegmentIndex {
		case 0:          // 標準地図
			mvMap.mapType = MKMapType.Standard
		case 1:          // 航空写真
			mvMap.mapType = MKMapType.Satellite
		case 2:          // ハイブリット
			mvMap.mapType = MKMapType.Hybrid
		default:
			break
		}
	}
	
	// トラッキングモード選択
	@IBAction func selectTracking(sender: UISegmentedControl) {
		
		// ボタン判定
		switch sender.selectedSegmentIndex {
		case 0:          // 追跡なし
			mvMap.setUserTrackingMode(MKUserTrackingMode.None, animated: true)
			
			// 現在地印の消去
			mvMap.showsUserLocation = false
			
		case 1:          // 位置追跡
			mvMap.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
			
		case 2:          // 位置、方位追跡
			mvMap.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true)
			
		default:
			break
		}
	}
	
	// 地図のロングプレス時
	@IBAction func dorpPin(sender: UILongPressGestureRecognizer) {
		
		// ジェスチャーの確定判定
		if sender.state == UIGestureRecognizerState.Ended {
			
			// MapView取得
			var mv = sender.view as! MKMapView
			
			// 位置情報を取得
			var pnt = sender.locationInView(mv)
			var crd = mv.convertPoint(pnt, toCoordinateFromView: mv)
			
			// アノテーション追加
			var ant = MKPointAnnotation()
			
			// 設定（位置：緯度・経度を指定）
			ant.coordinate = crd
			
			// 設定（表示テキスト）
			ant.title = getElevation(crd)	// 標高
			
			mv.addAnnotation(ant)
		}
	}
	
	// 標高値の取得
	// ・国土地理院「電子国土ポータル」のAPIを使用
	// 　http://portal.cyberjapan.jp/help/development.html#api
	func getElevation(point: CLLocationCoordinate2D) -> String {
		
		// HTTPリクエスト設定
		var add =
			"http://cyberjapandata2.gsi.go.jp/" +
				"general/dem/scripts/getelevation.php" +
			"?lon=\(point.longitude)&lat=\(point.latitude)&outtype=JSON"
		
		var url = NSURL(string: add)
		
		var req = NSURLRequest(
			URL: url!,
			cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
			timeoutInterval: 3.0)
		
		// サーバ同期接続
		var res = NSURLConnection.sendSynchronousRequest(
			req, returningResponse: nil, error: nil)!
		
		// JSONデータ取得
		var obj = NSJSONSerialization.JSONObjectWithData(
			res,
			options: NSJSONReadingOptions.MutableContainers,
			error: nil) as! NSDictionary
		
		var elv: AnyObject = obj["elevation"]!	// 標高（取得エラー時："-----"）
//		var hsr = obj["hsrc"] as! String		// データソース
		
		return "\(elv)m"
	}
}

