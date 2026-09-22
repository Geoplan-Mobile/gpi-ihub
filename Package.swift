// swift-tools-version: 5.9
//
// release repo 배포 매니페스트 (wrapper 패턴).
// binaryTarget 은 자체적으로 의존성을 선언할 수 없어, 의존성을 실어보내는
// carrier target(gpi-ihub-deps) 을 함께 둔다. 소비 앱은 gpi-ihub 하나만
// 의존하면 되고, gpi-ihub-deps 의 존재를 인지하지 못한다.
//
// [주의] 아래 의존성은 xcframework 를 빌드한 소스 저장소의 선언과 **같은 버전이어야 한다.**
//        이쪽은 자동 검증이 없으므로 의존성을 올릴 때 손으로 맞춘다.
//

import PackageDescription

let package = Package(
    name: "gpi-ihub",
    platforms: [
        // 배포 하한은 의존성 하한(gpi-dltdoa · gpi-prm · gpi-logger 의 iOS 15.0) 위의 18.0 —
        // 26 이하 베이스라인 앱도 의존성 추가가 가능하다.
        // 다만 측위 엔진이 iOS 27.0+ 기기에서만 동작해 SDK API 는 @available(iOS 27.0, *) 로
        // 한정돼 있다 — 27 미만 앱은 호출부를 #available 로 감싸야 한다.
        .iOS("18.0"),
    ],
    products: [
        .library(
            name: "gpi-ihub",
            targets: ["gpi-ihub", "gpi-ihub-deps"]
        ),
    ],
    dependencies: [
        // DL-TDoA 측위 엔진. binary framework 의 transitive 의존이라 minor 자동 상승도 위험 →
        // exact 로 고정.
        .package(
            url: "https://github.com/Geoplan-Mobile/gpi-dltdoa.git",
            exact: "2.1.0"
        ),
        // PRM 엔진 — binary xcframework (wrapper 패키지).
        // wrapper 의 carrier 가 GEOSwift 를 전파하므로 GEOSwift 를 직접 선언하지 않는다.
        // dltdoa 와 같은 이유로 exact 고정.
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
        .binaryTarget(
            name: "gpi-ihub",
            path: "gpi-ihub.xcframework"
        ),
        .target(
            name: "gpi-ihub-deps",
            dependencies: [
                .product(name: "gpi-dltdoa", package: "gpi-dltdoa"),
                .product(name: "gpi-prm", package: "gpi-prm"),
                .product(name: "gpi-logger", package: "gpi-logger"),
            ]
        ),
    ]
)
