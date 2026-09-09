# Changelog

모든 주요 변경 사항은 이 파일에 기록됩니다.

## [1.0.1] - 2026-09-09

### 변경

- **iOS 최소 배포 타깃**: iOS 27.0+에서 **iOS 18.0+**로 낮춰, iOS 18 이상 앱에서 패키지를 추가할 수 있도록 변경.
- **SDK API 가용성**: DL-TDoA 측위 진입점인 `IntelligenceHub`는 계속 **iOS 27.0+** 전용이다. iOS 18~26을 함께 지원하는 앱은 `IntelligenceHub` 호출부를 `#available(iOS 27.0, *)`로 보호해야 한다.
- **지원 하드웨어 호스트 버전**: AN-460은 A04-005 이상, AN-500은 A01-010 이상으로 갱신.

### 호환성

- 공개 API와 iOS 27+에서의 동작은 변경되지 않았다.

## [1.0.0] - 2026-09-03

### 초기 SPM 배포

- **xcframework 기반 SPM 배포**: `gpi-ihub.xcframework` 를 SPM 의 binaryTarget 으로 제공.
- **BLE 층 식별 + UWB DL-TDoA 실내 측위**: 좌표와 영역 진출입 이벤트를 통지.
- **라이선스**: 측위를 시작하려면 intelligencehub 발급 키가 필요.

### 요구사항
- deployment target **iOS 27.0+**, **DL-TDoA 를 지원하는 UWB 탑재 기기**.
- Info.plist 키와 위치 권한 설정이 필요합니다. README 를 참고하세요.
