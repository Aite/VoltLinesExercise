//
//  Departure.swift
//  VoltLinesExercise
//
//  Created by Alaa Al-Zaibak on 29.05.2018.
//  Copyright © 2018 Alaa Al-Zaibak. All rights reserved.
//

import UIKit

class Departure: NSObject {
    var remainingMinutes : Int
    var destination : String

    init(remainingMinutes: Int, destination: String) {
        self.remainingMinutes = remainingMinutes
        self.destination = destination
    }
}
