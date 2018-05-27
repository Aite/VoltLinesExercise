//
//  MarkersViewModel.swift
//  VoltLinesExercise
//
//  Created by Alaa Al-Zaibak on 27.05.2018.
//  Copyright © 2018 Alaa Al-Zaibak. All rights reserved.
//

import UIKit

class MarkerListViewModel: NSObject {
    /* Holds a list of the `MarkerViewModel`s
     */
    var markerViewModels: [MarkerViewModel]

    init(markers: [MarkerViewModel]) {
        self.markerViewModels = markers
    }

    convenience init(stops: [Stop]) {
        var markerViewModels = [MarkerViewModel]()
        for stop in stops {
            let markerViewModel = MarkerViewModel(withStop: stop)
            markerViewModels.append(markerViewModel)
        }

        self.init(markers: markerViewModels)
    }
}