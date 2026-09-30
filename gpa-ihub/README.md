# gpa-ihub (Android Library)

## 개요

`gpa-ihub` 는 intelligencehub(`https://geospace.geoplan.io`) 에서 설정한 현장 구성
(층 · 앵커 · 영역) 을 동기화해, 그 공간 안에서 모바일 기기 자신의 위치를 실시간으로
측위하는 SDK 다.

BLE 광고로 지금 있는 층을 식별하고, 그 층에 설치된 UWB 앵커와 DL-TDoA 측위를 수행해
좌표를 통지한다. 층에 영역(zone) 이 등록돼 있으면 진입/이탈 이벤트도 함께 통지한다.

---

## 배포 형태

사내 Nexus 에 `.aar` 아티팩트로 배포한다.

| 항목 | 값 |
|---|---|
| groupId | `kr.geoplan.android.lib` |
| artifactId | `gpa-ihub` |

---

## 요구 사항

| 항목 | 값 |
|---|---|
| Android | `minSdk` **37** 이상 |
| 기기 | DL-TDoA 를 지원하는 UWB 탑재 기기 |
| 네트워크 | 필요 |
| 라이선스 | intelligencehub 발급 키 필요 |

라이선스 키 발급과 앵커 · 영역(zone) 설정은 intelligencehub(`https://geospace.geoplan.io`)
에서 한다.

### 측위 지원 범위

현재 버전은 **단일 층 · 단일 셀 구성**을 지원한다.
측위는 한 번에 한 층에서만 이뤄지며, 여러 층이 동시에 인식되면 그중 하나를 선택한다.

### 현재 지원 하드웨어

| 앵커 모델 | 지원 호스트 버전 |
|---|---|
| AN-460 | A04-005 이상 |
| AN-500 | A01-010 이상 |

보유 하드웨어의 모델과 호스트 버전은 intelligencehub 의 **하드웨어 관리** 탭에서 확인한다.

위 지원 호스트 버전은 **현재 릴리스 시점에 확인된 기기 기준**이다. intelligencehub
(`https://geospace.geoplan.io`) 업데이트에 따라 변경될 수 있으며, 상세 지원 범위는
intelligencehub 측에 문의한다.

---

## 1. Gradle 연동

`settings.gradle` 에 사내 Nexus 저장소를 추가한다. **접속 계정·비밀번호는 Geoplan 에 문의**한다.

```gradle
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven {
            credentials {
                username "<발급 계정>"       // Geoplan 문의
                password "<발급 비밀번호>"    // Geoplan 문의
            }
            url "http://geoplan.iptime.org:30005/nexus/content/repositories/geoplan_release"
            allowInsecureProtocol true
        }
    }
}
```

앱 모듈의 `build.gradle` 에 의존성을 추가한다.

```gradle
android {
    compileSdk 37
    defaultConfig {
        minSdk 37
    }
}

dependencies {
    implementation 'kr.geoplan.android.lib:gpa-ihub:1.1.0'
}
```

> `gpa-prm` · `gpa-dltdoa` 는 Gradle 이 자동으로 함께 가져오므로 별도로 추가하지 않는다.

---

## 2. 권한 설정

### AndroidManifest.xml

| 선언 | 없으면 |
|---|---|
| `android.permission.RANGING` | UWB 측위 불가. `onError(9)` |
| `android.permission.BLUETOOTH_SCAN` | 런타임 승인을 받을 수 없어 `onError(3)` |
| `android.permission.ACCESS_FINE_LOCATION` | 런타임 승인을 받을 수 없어 `onError(7)` |

```xml
<uses-permission android:name="android.permission.RANGING" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<uses-feature android:name="android.hardware.uwb" android:required="true" />
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

`INTERNET` 등 상시 필요한 권한은 라이브러리 매니페스트가 선언하므로 앱이 따로 넣지 않는다.

### 런타임 권한

- **런타임 권한은 앱이 직접 요청한다.** SDK 는 요청하지 않으므로, 사용자 응답을 받은 뒤
  `start()` 를 호출한다.
- **정밀 위치가 필수다.** 사용자가 "대략적인 위치" 를 선택하면 `onError(7)` 이 발생한다.
- 시스템 위치 서비스가 꺼져 있어도 `onError(7)` 이다.
- `RANGING` 은 **매니페스트 선언 유무만** 검사한다. 선언하고도 런타임 승인을 받지 못하면
  측위를 시작하는 시점에 `onError(4)` 로 드러난다.

`start()` 는 위 조건을 검사해 하나라도 걸리면 시작하지 않고 `onError` 로 사유를 알린다.

### 백그라운드에서 동작시키려면 (선택)

**라이브러리는 포그라운드 서비스를 만들지 않는다.** 그 알림은 앱 사용자가 직접 보는
UI 라 아이콘 · 문구 · 클릭 동작을 앱이 결정해야 하기 때문이다. 백그라운드 측위가
필요하면 앱이 포그라운드 서비스를 만들고 아래를 선언한다.

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

포그라운드 서비스 없이 백그라운드로 내려가면 스캔이 멎거나 프로세스가 회수될 수 있다.

---

## 3. 사용 방법

```java
public class MyPositioningService implements HubListener {

    private final IntelligenceHub hub;

    public MyPositioningService(Context context) {
        this.hub = IntelligenceHub.getInstance(context);
    }

    // 앱 시작 시 1회
    public static void setUp() {
        IntelligenceHub.setLicense("발급받은-라이선스-키");
    }

    // 1) 권한을 먼저 요청한다. SDK 는 권한을 요청하지 않는다.
    public void requestPermission(Activity activity) {
        ActivityCompat.requestPermissions(activity, new String[]{
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.RANGING
        }, REQUEST_CODE);
    }

    // 2) 사용자가 응답한 뒤에 시작한다.
    public void startPositioning() {
        hub.setListener(this);
        hub.start();          // 결과는 onStarted() 또는 onError() 로 온다
    }

    public void stopPositioning() {
        hub.stop();           // 정리가 끝나면 onStopped() 가 온다
    }

    // --- HubListener (백그라운드 스레드에서 호출됨) ---

    @Override public void onStarted() {}

    @Override public void onStopped() {
        // stop() 직후가 아니라 여기서 해제한다.
        // stop() 은 즉시 반환하므로 바로 떼면 이 콜백을 받지 못한다.
        hub.setListener(null);
    }

    @Override public void onTrackingStarted(long floorId) {}
    @Override public void onTrackingStopped(long floorId) {}

    @Override public void onPosition(long floorId, double x, double y, double z) {
        Log.d(TAG, "좌표: " + floorId + " / " + x + ", " + y + ", " + z);
    }

    @Override public void onAreaEvent(long floorId, String areaName, String inOut) {
        Log.d(TAG, "영역 " + inOut + ": " + areaName);   // inOut 은 "IN" 또는 "OUT"
    }

    @Override public void onError(int code, String msg) {
        Log.e(TAG, "에러 " + code + ": " + msg);
    }
}
```

- `setLicense(String)` 은 앱 시작 시 1회 호출한다.
- `start()` 는 예외를 던지지 않는다. 호출하면 `onStarted()` 또는 `onError(int, String)` 중
  하나가 온다. 라이선스를 서버에 확인하므로 네트워크 왕복만큼 늦어지며, 응답이 없으면
  `onError(11)` 이 온다.
- `stop()` 도 즉시 반환한다. 정리가 끝나면 `onStopped()` 가 오므로, 리스너 해제는 그때 한다.
- **콜백은 메인 스레드가 아닌 백그라운드 스레드에서 호출된다.** UI 갱신은 앱이 메인으로 옮긴다.

---

## 4. API 레퍼런스

공개 타입은 `IntelligenceHub` 와 `HubListener` 둘뿐이다.

### 클래스: `IntelligenceHub`

| 멤버 | 설명 |
|---|---|
| `static void setLicense(String license)` | 라이선스 등록. 보관만 하고 검증은 `start()` 에서 수행 |
| `static IntelligenceHub getInstance(Context context)` | 싱글톤 인스턴스 반환 |
| `static boolean isUwbHardwareAvailable(Context context)` | 기기의 UWB 하드웨어 유무 |
| `void setListener(HubListener listener)` | 리스너 등록. `null` 이면 해제 |
| `void start()` | 측위 시작. 예외를 던지지 않음 |
| `void stop()` | 측위 정지. 이미 정지 상태면 아무 일도 일어나지 않음 |
| `String getLibraryVersion()` | 버전 문자열. 예: `"1.1.0"` |

`isUwbHardwareAvailable()` 은 **UWB 칩이 있는지만** 확인하는 사전 힌트다. 칩이 있어도
DL-TDoA 를 지원하지 않는 기기가 있으므로 `true` 라고 측위가 보장되지는 않는다.
정확한 판정은 `start()` 가 수행하며, 지원하지 않으면 `onError(12)` 로 알린다.

SDK 가 리스너를 계속 붙잡고 있으므로, 더 이상 쓰지 않을 때 `setListener(null)` 로 해제한다.

### 인터페이스: `HubListener`

| 콜백 | 호출 시점 |
|---|---|
| `void onStarted()` | `start()` 성공 |
| `void onStopped()` | `stop()` 완료 |
| `void onTrackingStarted(long floorId)` | 층 진입 → 측위 시작 |
| `void onTrackingStopped(long floorId)` | 층 이탈 → 측위 종료 |
| `void onPosition(long floorId, double x, double y, double z)` | 좌표 갱신 (단위: 미터) |
| `void onAreaEvent(long floorId, String areaName, String inOut)` | 영역 진입/이탈. `inOut` 은 `"IN"` \| `"OUT"` |
| `void onError(int code, String msg)` | 오류 발생 |

`floorId` 는 intelligencehub 에 등록된 층의 식별자다. 좌표와 영역 이벤트가 어느 층에서
발생했는지 이 값으로 구분한다.

---

## 5. 에러 코드

`HubListener.onError(int code, String msg)` 의 `code` 값이다.

| 코드 | 의미 | 발생 시 동작 |
|---|---|---|
| 1 | 라이선스가 등록되지 않은 상태로 `start()` 를 호출함 | 상태 변화 없음 — 애초에 구동되지 않음 |
| 2 | 이미 측위 중인데 `start()` 를 다시 호출함 | 상태 변화 없음 — 기존 구동은 그대로 지속됨 |
| 3 | Bluetooth 사용 불가 (꺼짐 · 권한 없음 · 기기 미지원) | 구동 전이면 시작 안 됨 · **구동 중이면 stop됨** |
| 4 | 측위 시작 실패 (해당 층의 앵커 정보 없음 · `RANGING` 런타임 미승인) | 상태 변화 없음 — 에러 알림만, 그 층에서 계속 재시도됨 |
| 5 | DL-TDoA 세션 오류 | 상태 변화 없음 — 에러 알림만, SDK 가 스스로 다시 시작함 |
| 6 | 영역 판정 오류 | 상태 변화 없음 — 에러 알림만 |
| 7 | 위치 사용 불가 (권한 없음 · 정밀 위치 아님 · 위치 서비스 꺼짐) | 구동 전이면 시작 안 됨 · **구동 중이면 stop됨** |
| 8 | 정지가 끝나기 전에 `start()` 를 호출함 | 상태 변화 없음 — 진행 중이던 정지 절차 그대로 진행됨 |
| 9 | AndroidManifest.xml 의 `RANGING` 권한 선언 누락 | 상태 변화 없음 — 애초에 구동되지 않음 |
| 10 | 서버가 라이선스를 거부함 | 구동 전이면 시작 안 됨 · **구동 중이면 stop됨** |
| 11 | 라이선스 서버에 연결하지 못함 | 상태 변화 없음 — 애초에 구동되지 않음 |
| 12 | 기기가 DL-TDoA 를 지원하지 않음 | 상태 변화 없음 — 애초에 구동되지 않음 |
| 201 | BLE 스캔 시작이 너무 잦아 차단됨 (Android 전용) | 상태 변화 없음 — 애초에 구동되지 않음 |

**"구동 중이면 stop됨"** 이 붙은 코드(3 · 7 · 10)는 `start()` 실패뿐 아니라 측위가 시작된 뒤에도 발생할 수 있다.  
사용자가 Bluetooth 를 끄거나(3), 설정에서 위치 권한 · 정밀 위치를 내리거나(7), 서버가 라이선스를 거부하면(10) 그렇다.  
이때는 `onError` 에 이어 `onStopped()` 가 오며 **앱이 `stop()` 을 부르지 않아도 측위가 멈춘다.**  
다시 측위하려면 원인을 해결한 뒤 `start()` 를 다시 호출해야 한다 — **자동으로 재개되지 않는다.**

코드 **201** 은 Android 전용 대역(201~299)의 항목이다. 시스템의 BLE 스캔 시작 제한
(30초 내 5회)에 걸리지 않도록 라이브러리가 `start()` 를 미리 막은 것이다.
잠시 기다렸다가 다시 `start()` 를 호출한다.
