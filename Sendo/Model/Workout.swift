//
//  Workout.swift
//  Sendo
//
//  Created by Aimar Ugarte on 3/12/22.
//

import Foundation
import FirebaseDatabase

public struct Workout: Codable {
    
    let userId: String
    let name: String
    let description: String
    let sessions: [Session]
    let image: String
    
    init?(snapshot: DataSnapshot) {
        guard let dic = snapshot.value as? [String:Any] else {
            return nil
        }
        
        guard let userId = dic["userId"] as? String else {
            return nil
        }
        self.userId = userId
        
        if let name = dic["name"] as? String {
            self.name = name
        } else {
            self.name = ""
        }
        
        if let description = dic["description"] as? String  {
            self.description = description
        } else {
            self.description = ""
        }
        
        if let sessions = dic["sessions"] as? [Session] {
            self.sessions = sessions
        } else {
            self.sessions = []
        }
        
        if let image = dic["image"] as? String  {
            self.image = image
        } else {
            self.image = ""
        }
    }
}

public struct Session: Codable {
    
    let name: String
    let exercises: [Exercise]
    
    init?(snapshot: DataSnapshot) {
        guard let dic = snapshot.value as? [String:Any] else {
            return nil
        }
        
        if let name = dic["name"] as? String  {
            self.name = name
        } else {
            self.name = ""
        }
        
        if let exercises = dic["exercises"] as? [Exercise] {
            self.exercises = exercises
        } else {
            self.exercises = []
        }
    }
}
