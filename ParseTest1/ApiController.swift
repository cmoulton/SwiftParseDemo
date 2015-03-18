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

enum KeyFields: String {
  case appID = "appID"
  case jsKey = "jsKey"
  case clientKey = "clientKey"
}

class APIController {
  var manager: Alamofire.Manager
  let keys: Dictionary<String, String>?
  
  required init()
  {
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    manager = Alamofire.Manager(configuration: configuration)
    if let path = NSBundle.mainBundle().pathForResource("keys", ofType: "plist")
    {
      if let dict: NSDictionary? = NSDictionary(contentsOfFile: path)
      {
        keys = dict as? Dictionary<String, String>
      }
    }
  }
  
  func getSpots(completionHandler: (Array<Spot>?, NSError?) -> Void) {
    let appID = keys?[KeyFields.appID.rawValue]
    let clientKey = keys?[KeyFields.clientKey.rawValue]
    if appID == nil || clientKey == nil
    {
      completionHandler(nil, NSError(domain: "parseAPICall", code: 200, userInfo: [NSLocalizedDescriptionKey: "Could not load API keys from keys.plist"]))
    }
    
    // add our auth headers
    manager.session.configuration.HTTPAdditionalHeaders = [
      "X-Parse-Application-Id": appID!,
      "X-Parse-Client-Key": clientKey!
    ]

    let path = "https://api.parse.com/1/classes/Spot/"
    manager.request(.GET, path)
      .responseSpotsArray { (request, response, spots, error) in
        completionHandler(spots, error)
    }
  }
  
  func getSpotsWithBasicAuth(completionHandler: (Array<Spot>?, NSError?) -> Void) {
    let appID = keys?[KeyFields.appID.rawValue]
    let jsKey = keys?[KeyFields.jsKey.rawValue]
    if appID == nil || jsKey == nil
    {
      completionHandler(nil, NSError(domain: "parseAPICall", code: 200, userInfo: [NSLocalizedDescriptionKey: "Could not load API keys from keys.plist"]))
    }
    
    let username = appID!
    // note: javascript key is different from REST API key, get it from
    // Parse project -> Settings (at top) -> Keys -> Javascript Key
    let password = "javascript-key=" + jsKey!
    
    let useCredential = true // toggle to switch to username/password
    if useCredential == false
    {
      // Username/password
    manager.request(.GET, "https://api.parse.com/1/classes/Spot/")
        .authenticate(user: username, password: password).responseSpotsArray { (request, response, spots, error) in
          completionHandler(spots, error)
      }
    }
    else
    {
      // NSURLCredential
      let credential = NSURLCredential(user: username, password: password, persistence: NSURLCredentialPersistence.ForSession)
      manager.request(.GET, "https://api.parse.com/1/classes/Spot/")
        .authenticate(usingCredential: credential)
      .responseSpotsArray { (request, response, spots, error) in
        completionHandler(spots, error)
    }
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
        println(jsonSpot)
        let id = jsonSpot["objectId"].intValue
        let name = jsonSpot["Name"].stringValue
        let lat = jsonSpot["Location"]["latitude"].doubleValue
        let lon = jsonSpot["Location"]["longitude"].doubleValue
        let spot = Spot(aName: name, aLat: lat, aLon: lon, anId: id)
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