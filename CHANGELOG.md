# Changelog

모든 주요 변경 사항은 이 파일에 기록됩니다.

## [1.0.0] - 2026-09-03

### 초기 SPM 배포

- **xcframework 기반 SPM 배포**: `gpi-ihub.xcframework` 를 SPM 의 binaryTarget 으로 제공.
- **BLE 층 식별 + UWB DL-TDoA 실내 측위**: 좌표와 영역 진출입 이벤트를 통지.
- **라이선스**: 측위를 시작하려면 intelligencehub 발급 키가 필요.

### 요구사항
- deployment target **iOS 27.0+**, **DL-TDoA 를 지원하는 UWB 탑재 기기**.
- Info.plist 키와 위치 권한 설정이 필요합니다. README 를 참고하세요.
