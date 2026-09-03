# gpi-ihub (Swift Package)

`gpi-ihub` 실내 측위 SDK 의 **배포 전용 저장소**다.
사전 컴파일된 `XCFramework` 를 SPM 패키지로 제공하며, 실기기(arm64) 와
시뮬레이터(arm64, x86_64) 를 모두 지원한다.
배포 버전은 `gpi-ihub.xcframework/VERSION_X.X.X` 파일로 확인한다.

BLE 광고로 층을 식별하고, 해당 층의 UWB 앵커와 DL-TDoA 측위를 수행해 좌표를 통지한다.
층에 영역(zone) 이 등록돼 있으면 진입/이탈 이벤트도 함께 통지한다.

---

## 요구 사항

| 항목 | 값 |
|---|---|
| iOS | 27.0 이상 |
| 기기 | DL-TDoA 를 지원하는 UWB 탑재 기기 |
| 네트워크 | 필요 |
| 라이선스 | intelligencehub 발급 키 필요 |

라이선스 키 발급과 앵커 · 영역(zone) 설정은 intelligencehub(`https://geospace.geoplan.io`)
에서 한다.

### 측위 지원 범위

현재 버전은 **단일 층 · 단일 셀 구성**을 지원한다.
측위는 한 번에 한 층에서만 이뤄지며, 여러 층이 동시에 인식되면 그중 하나를 선택한다.

---

## 1. SPM 연동

1. Xcode 상단 메뉴 **[File] → [Add Package Dependencies...]**
2. 검색창에 저장소 주소 입력
   `https://github.com/Geoplan-Mobile/gpi-ihub`
   *(Private 저장소이므로 사용할 GitHub 계정이 Collaborator 로 등록돼 있어야 한다.)*
3. **Dependency Rule** 설정 후 **[Add Package]**

> `gpi-dltdoa` · `gpi-prm` · `gpi-logger` 는 SPM 이 자동으로 함께 가져오므로 별도로 추가하지 않는다.

---

## 2. 권한 설정

### Info.plist

| 키 | 없으면 |
|---|---|
| `NSBluetoothAlwaysUsageDescription` | BLE 스캔 불가. `onError(9)` |
| `NSLocationWhenInUseUsageDescription` | 위치 권한을 받을 수 없어 `onError(7)` |
| `NSLocationTemporaryUsageDescriptionDictionary` | 정밀 위치 승격을 요청할 수 없어 `onError(7)` |
| `NSNearbyInteractionUsageDescription` | 앱 심사에서 거부됨 |

### 런타임 권한

- **위치 권한은 앱이 직접 요청한다.** SDK 는 요청하지 않으므로,
  `CLLocationManager.requestWhenInUseAuthorization()` 응답을 받은 뒤 `start()` 를 호출한다.
- **정밀 위치가 필수다.** 사용자가 "대략적인 위치" 를 선택하면 `onError(7)` 이 발생한다.
  `requestTemporaryFullAccuracyAuthorization(withPurposeKey:)` 로 승격을 요청한다.
- 시스템 위치 서비스가 꺼져 있어도 `onError(7)` 이다.
- Bluetooth 권한 프롬프트는 SDK 가 자동으로 띄운다.

`start()` 는 위 조건을 검사해 하나라도 걸리면 시작하지 않고 `onError` 로 사유를 알린다.

### 백그라운드에서 동작시키려면 (선택)

백그라운드 측위 여부는 앱이 정한다. **SDK 는 요구하지 않으며, 포그라운드 전용으로 써도 된다.**
필요하다면 아래 셋을 추가한다.

| 추가할 것 | 값 |
|---|---|
| Info.plist `UIBackgroundModes` | `bluetooth-central` |
| Info.plist `NSLocationAlwaysAndWhenInUseUsageDescription` | 사용 목적 문구 |
| 런타임 권한 요청 | `requestAlwaysAuthorization()` |

하나라도 빠지면 앱이 백그라운드로 내려가는 시점에 층 인식이 멈춘다.
`bluetooth-central` 만 선언하고 권한이 `Always` 가 아니면 SDK 가 로그로 경고하지만
시작을 막지는 않는다.

**셋을 모두 갖춰도 백그라운드에서는 좌표(`onPosition`)가 나오지 않는다.** UWB 세션이
백그라운드에서 동작하지 않기 때문이며, 이 설정으로 유지되는 것은 층 인식까지다.
포그라운드로 돌아오면 세션이 다시 이어져 좌표가 재개된다.

---

## 3. 사용 방법

```swift
import gpi_ihub
import CoreLocation

final class MyPositioningService: HubListener {

    private let hub = IntelligenceHub.getInstance()
    private let locationManager = CLLocationManager()

    // 앱 시작 시 1회
    static func setUp() {
        IntelligenceHub.setLicense("발급받은-라이선스-키")
    }

    // 1) 위치 권한을 먼저 요청한다. SDK 는 권한을 요청하지 않는다.
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // 2) 사용자가 응답한 뒤에 시작한다.
    func startPositioning() {
        hub.setListener(self)
        hub.start()          // 결과는 onStarted() 또는 onError() 로 온다
    }

    func stopPositioning() {
        hub.stop()           // 정리가 끝나면 onStopped() 가 온다
    }

    // MARK: - HubListener (백그라운드 큐에서 호출됨)

    func onStarted() {}

    func onStopped() {
        // stop() 직후가 아니라 여기서 해제한다.
        // stop() 은 즉시 반환하므로 바로 떼면 이 콜백을 받지 못한다.
        hub.setListener(nil)
    }

    func onTrackingStarted(_ floorId: Int64) {}
    func onTrackingStopped(_ floorId: Int64) {}

    func onPosition(_ floorId: Int64, _ x: Double, _ y: Double, _ z: Double) {
        print("좌표: \(floorId) / \(x), \(y), \(z)")
    }

    func onAreaEvent(_ floorId: Int64, _ areaName: String, _ inOut: String) {
        print("영역 \(inOut): \(areaName)")     // inOut 은 "IN" 또는 "OUT"
    }

    func onError(_ code: Int, _ msg: String) {
        print("에러 \(code): \(msg)")
    }
}
```

- `setLicense(_:)` 는 앱 시작 시 1회 호출한다.
- `start()` 는 예외를 던지지 않는다. 호출하면 `onStarted()` 또는 `onError(_:_:)` 중 하나가 온다.
  라이선스를 서버에 확인하므로 네트워크 왕복만큼 늦어지며, 응답이 없으면 10초 뒤 `onError(11)` 이 온다.
- `stop()` 도 즉시 반환한다. 정리가 끝나면 `onStopped()` 가 오므로, 리스너 해제는 그때 한다.
- **콜백은 메인 스레드가 아닌 백그라운드 큐에서 호출된다.**

---

## 4. API 레퍼런스

공개 타입은 `IntelligenceHub` 와 `HubListener` 둘뿐이다.

### 클래스: `IntelligenceHub`

| 멤버 | 설명 |
|---|---|
| `static func setLicense(_ license: String)` | 라이선스 등록. 보관만 하고 검증은 `start()` 에서 수행 |
| `static func getInstance() -> IntelligenceHub` | 싱글톤 인스턴스 반환 |
| `static func isAvailableDlTdoa() -> Bool` | 기기의 DL-TDoA 지원 여부 |
| `func setListener(_ listener: HubListener?)` | 리스너 등록. `nil` 이면 해제 |
| `func start()` | 측위 시작. 예외를 던지지 않음 |
| `func stop()` | 측위 정지. 이미 정지 상태면 아무 일도 일어나지 않음 |
| `func getLibraryVersion() -> String` | 버전 문자열. 예: `"1.0.0"` (조회 실패 시 `"unknown"`) |

SDK 가 리스너를 계속 붙잡고 있으므로, 더 이상 쓰지 않을 때 `setListener(nil)` 로 해제한다.

### 프로토콜: `HubListener`

| 콜백 | 호출 시점 |
|---|---|
| `onStarted()` | `start()` 성공 |
| `onStopped()` | `stop()` 완료 |
| `onTrackingStarted(_ floorId: Int64)` | 층 진입 → 측위 시작 |
| `onTrackingStopped(_ floorId: Int64)` | 층 이탈 → 측위 종료 |
| `onPosition(_ floorId: Int64, _ x: Double, _ y: Double, _ z: Double)` | 좌표 갱신 (단위: 미터) |
| `onAreaEvent(_ floorId: Int64, _ areaName: String, _ inOut: String)` | 영역 진입/이탈. `inOut` 은 `"IN"` \| `"OUT"` |
| `onError(_ code: Int, _ msg: String)` | 오류 발생 |

`floorId` 는 intelligencehub 에 등록된 층의 식별자다. 좌표와 영역 이벤트가 어느 층에서
발생했는지 이 값으로 구분한다.

---

## 5. 에러 코드

`HubListener.onError(_ code: Int, _ msg: String)` 의 `code` 값이다.

| 코드 | 의미 |
|---|---|
| 1 | 라이선스가 등록되지 않은 상태로 `start()` 를 호출함 |
| 2 | 이미 측위 중인데 `start()` 를 다시 호출함 |
| 3 | Bluetooth 사용 불가 (꺼짐 · 권한 없음 · 기기 미지원) |
| 4 | 측위 시작 실패 (해당 층의 앵커 정보 없음) |
| 5 | DL-TDoA 세션 오류 |
| 6 | 영역 판정 오류 |
| 7 | 위치 사용 불가 (권한 없음 · 정밀 위치 아님 · 위치 서비스 꺼짐) |
| 8 | 정지가 끝나기 전에 `start()` 를 호출함 |
| 9 | Info.plist 키 누락 |
| 10 | 서버가 라이선스를 거부함 |
| 11 | 서버에 연결하지 못함 |
| 12 | 기기가 DL-TDoA 를 지원하지 않음 |

코드 3 · 7 · 10 은 `start()` 실패뿐 아니라 **측위가 시작된 뒤에도 발생한다.**
사용자가 Bluetooth 를 끄거나(3), 설정에서 위치 권한 · 정밀 위치를 내리거나(7),
서버가 라이선스를 거부하면(10) 그렇다.

이때는 `onError` 에 이어 `onStopped()` 가 오며 **앱이 `stop()` 을 부르지 않아도
측위가 멈춘다.** 다시 측위하려면 원인을 해결한 뒤 `start()` 를 다시 호출해야 한다.
