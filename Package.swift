// swift-tools-version: 5.9
//
// Sample 앱의 Local Package 의존성 입구.
// 실제 xcframework 빌드는 gpi-ihub.xcodeproj 가 담당하고,
// 이 매니페스트는 Sample 이 source 를 직접 컴파일해 디버그/검증할 수 있도록 한다.
//
// 외부 사용 앱은 이 매니페스트가 아니라 release repo (Geoplan-Mobile/gpi-ihub) 의
// Package.swift 를 통해 binary xcframework 를 가져간다.
//
// [주의] 아래 의존성은 gpi-ihub.xcodeproj 의 SPM 의존성과 **같은 버전으로 이중 선언**해야 한다.
//        release_tools/build_xcframework.sh 첫 단계에서 두 자리의 일치 여부를 검증한다.
//

import PackageDescription

let package = Package(
    name: "gpi-ihub",
    platforms: [
        // 배포 하한은 의존성 하한(gpi-dltdoa · gpi-prm · gpi-logger 의 iOS 15.0) 위의 18.0 —
        // 26 이하 베이스라인 앱도 의존성 추가가 가능하다.
        // 측위 엔진(gpi-dltdoa) 이 iOS 27.0+ 기기에서만 동작하므로, 측위 경로
        // (CellSession → FloorSession → IntelligenceHub) 는 @available(iOS 27.0, *) 로
        // 한정돼 있다 — 27 미만 앱이 측위 API 를 쓰면 컴파일러가 막는다.
        .iOS("18.0"),
    ],
    products: [
        .library(
            name: "gpi-ihub",
            targets: ["gpi-ihub"]
        ),
    ],
    dependencies: [
        // DL-TDoA 측위 엔진. binary framework 의 transitive 의존이라 minor 자동 상승도 위험 →
        // exact 로 고정. 갱신 시 본 매니페스트와 xcodeproj 양쪽을 의도적으로 함께 올린다.
        .package(
            url: "https://github.com/Geoplan-Mobile/gpi-dltdoa.git",
            exact: "2.1.0"
        ),
        // PRM 엔진 — release repo 의 binary xcframework (wrapper 패키지).
        // wrapper 의 carrier 가 GEOSwift 를 전파하므로 GEOSwift 를 직접 선언하지 않는다.
        // dltdoa 와 같은 이유(binary framework 의 transitive 의존) 로 exact 고정.
        .package(
            url: "https://github.com/Geoplan-Mobile/gpi-prm.git",
            exact: "2.0.0"
        ),
        // 공용 로그 모듈. os.Logger + 파일 로그 이중 기록.
        // 여러 소비자가 공유하는 leaf 라이브러리라 minor 자동 상승 허용 (from:).
        .package(
            url: "https://github.com/Geoplan-Mobile/gpi-logger.git",
            from: "1.0.1"
        ),
    ],
    targets: [
        .target(
            name: "gpi-ihub",
            dependencies: [
                .product(name: "gpi-dltdoa", package: "gpi-dltdoa"),
                .product(name: "gpi-prm", package: "gpi-prm"),
                .product(name: "gpi-logger", package: "gpi-logger"),
            ],
            path: "gpi-ihub"     // xcodeproj 와 동일한 소스 폴더 (dltdoa 패턴).
        ),
    ]
)
