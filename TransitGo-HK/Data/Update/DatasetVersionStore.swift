//
//  DatasetVersionStore.swift
//  TransitGo-HK
//
//  Created by Ken on 10/8/2026.
//

import Foundation

struct DatasetVersionStore {
    
    private let key = "installedDatasetVersion"
    
    var installedVersion: String? {
        UserDefaults.standard.string(forKey: key)
    }
    
    func save(version: String) {
        UserDefaults.standard.set(version, forKey: key)
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
}
