//
//  ApiController.swift
//  ParseTest1
//
//  Created by Christina Moulton on 2015-03-14.
//  Copyright (c) 2015 Teak Mobile Inc. All rights reserved.
//

/* Results to GET https://api.parse.com/1/classes/Spot/ look like:

{
  "results": [
    {
      "Location": {
        "__type": "GeoPoint",
        "latitude": 43.4304344,
        "longitude": -80.4763151
      },
      "Name": "My Cafe",
      "createdAt": "2015-03-14T16:08:03.430Z",
      "objectId": "uwhQUedJxo",
      "updatedAt": "2015-03-14T16:09:04.355Z"
    }
  ]
}
*/

import Foundation
import Alamofire
import SwiftyJSON

class APIController {
  class func getSpots(completionHandler: (Array<Spot>?, NSError?) -> Void) {
    let path = "https://api.parse.com/1/classes/Spot/"
    Alamofire.request(.GET, path)
      .responseSpotsArray { (request, response, spots, error) in
        completionHandler(spots, error)
    }
  }
}

extension Alamofire.Request {
  class func spotsArrayResponseSerializer() -> Serializer {
    return { request, response, data in
      if data == nil {
        return (nil, nil)
      }
      
      var jsonError: NSError?
      let jsonData:AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: &jsonError)
      if jsonData == nil || jsonError != nil
      {
        return (nil, jsonError)
      }
      let json = JSON(jsonData!)
      if json.error != nil || json == nil
      {
        return (nil, json.error)
      }
      println(json)
      if let errorString = json["error"].string
      {
        return (nil, NSError(domain: "parseAPICall", code: 200, userInfo: [NSLocalizedDescriptionKey: errorString]))
      }
      
      var allSpots:Array = Array<Spot>()
      let results = json["results"]
      for (index, jsonSpot) in results
      {
        let id = jsonSpot["objectId"].intValue
        let name = jsonSpot["name"].stringValue
        let lat = jsonSpot["Location"]["latitude"].doubleValue
        let long = jsonSpot["Location"]["longitude"].doubleValue
        let spot = Spot(aName: name, aLat: lat, aLong: long, anId: id)
        allSpots.append(spot)
      }
      return (allSpots, nil)
    }
  }
  
  func responseSpotsArray(completionHandler: (NSURLRequest, NSHTTPURLResponse?, Array<Spot>?, NSError?) -> Void) -> Self {
    return response(serializer: Request.spotsArrayResponseSerializer(), completionHandler: { (request, response, spots, error) in
      completionHandler(request, response, spots as? Array<Spot>, error)
    })
  }
  
}