//
//  Spot.swift
//  ParseTest1
//
//  Created by Christina Moulton on 2015-03-14.
//  Copyright (c) 2015 Teak Mobile Inc. All rights reserved.
//

import Foundation
import MapKit

class Spot {
  let name: String
  let location: CLLocationCoordinate2D
  let id: Int?
  
  required init(aName: String, aLat: Double, aLon: Double, anId: Int?)
  {
    name = aName
    location = CLLocationCoordinate2D(latitude: aLat, longitude: aLon)
    id = anId
  }
}