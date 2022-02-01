//
//  App.swift
//  Recepie
//
//  Created by Muhammed salih T A on 01/02/22.
//

import Foundation
/// High level features related to app. Like target name or environment.
enum AppConfig {
    static var processEnvironment: [String: String] {
        return ProcessInfo.processInfo.environment
    }
}
extension AppConfig {
    enum Testing {
        static let RESPONSE = "RESPONSE."
        static let isUITesting = {
            AppConfig.processEnvironment["IS_UI_TESTING"] == "1"
        }()
        static let shouldUseLocalTestData = {
            AppConfig.processEnvironment["USE_LOCAL_TEST_DATA"] == "1"
        }()
        static func responsePath(item:String) ->String? {
            return AppConfig.processEnvironment["RESPONSE."+item]
        }
    }
}
