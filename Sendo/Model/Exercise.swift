//
//  Exercise.swift
//  Sendo
//
//  Created by Aimar Ugarte on 24/10/21.
//

import Foundation
import FirebaseDatabase

public struct Exercise: Codable {
    
    let id: String
    let name: String
    let title: String
    let type: String
    let description: String
    let steps: [String]
    let tips: [String]
    let primary: [String]
    let secondary: [String]
    let equipment: [String]
    let images: [String]
    
    init?(snapshot: DataSnapshot) {
        guard let dic = snapshot.value as? [String:Any] else {
            return nil
        }
        
        guard let id = dic["id"] as? String else {
            return nil
        }
        self.id = id
        
        if let name = dic["name"] as? String {
            self.name = name
        } else {
            self.name = ""
        }
        
        if let title = dic["title"] as? String {
            self.title = title
        } else {
            self.title = ""
        }
        
        if let type = dic["type"] as? String {
            self.type = type
        } else {
            self.type = ""
        }
        
        if let description = dic["primer"] as? String {
            self.description = description
        } else {
            self.description = ""
        }
        
        if let steps = dic["steps"] as? [String] {
            self.steps = steps
        } else {
            self.steps = []
        }
        
        if let tips = dic["tips"] as? [String] {
            self.tips = tips
        } else {
            self.tips = []
        }
        
        if let primary = dic["primary"] as? [String] {
            self.primary = primary
        } else {
            self.primary = []
        }
        
        if let secondary = dic["secondary"] as? [String] {
            self.secondary = secondary
        } else {
            self.secondary = []
        }
        
        if let equipment = dic["equipment"] as? [String] {
            self.equipment = equipment
        } else {
            self.equipment = []
        }
        
        if let images = dic["png"] as? [String] {
            self.images = images
        } else {
            self.images = []
        }
    
    }
}
