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

private let _APIControllerSharedInstance = APIController()

class APIController {
  class var sharedInstance: APIController {
    return _APIControllerSharedInstance
  }
  
  var manager: Alamofire.Manager
  let keys: Dictionary<String, String>?
  var sessionToken: String?
  
  // MARK: Lifecycle
  required init()
  {
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    manager = Alamofire.Manager(configuration: configuration)
    if let path = NSBundle.mainBundle().pathForResource("keys", ofType: "plist"), dict: NSDictionary? = NSDictionary(contentsOfFile: path)
    {
      keys = dict as? Dictionary<String, String>
    }
    else
    {
      keys = nil
    }
    let appID = keys?[KeyFields.appID.rawValue]
    let clientKey = keys?[KeyFields.clientKey.rawValue]
    if appID != nil && clientKey != nil
    {
      // TODO: handle
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
  
  // MARK: Login
  func isUserLoggedIn() -> Bool {
    if (sessionToken == nil || sessionToken!.isEmpty)
    {
      return false
    }
    // TODO: need to validate session token
    return true
  }
  
  func signUp(username: String!, password: String!, completionHandler: (Bool, NSError?) -> Void) {
    let path = "https://api.parse.com/1/users/"
    manager.request(.POST, path, parameters: ["username": username, "password": password], encoding: .JSON)
      .responseUserSessionToken { (request, response, token, error) in
        self.sessionToken = token
        completionHandler(self.isUserLoggedIn(), error)
    }
  }
  
  func login(username: String!, password: String!, completionHandler: (Bool, NSError?) -> Void) {
    let path = "https://api.parse.com/1/login/"
    manager.request(.GET, path, parameters: ["username": username, "password": password])
      .responseUserSessionToken { (request, response, token, error) in
        self.sessionToken = token
        completionHandler(self.isUserLoggedIn(), error)
    }
  }
  
  // MARK: Spots
  func getSpots(completionHandler: (Array<Spot>?, NSError?) -> Void) {
    let path = "https://api.parse.com/1/classes/Spot/"
    manager.request(.GET, path)
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
  
  class func sessionTokenFromUserResponseSerializer() -> Serializer {
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
      
      return (json["sessionToken"].string, nil)
    }
  }
  
  func responseUserSessionToken(completionHandler: (NSURLRequest, NSHTTPURLResponse?, String?, NSError?) -> Void) -> Self {
    return response(serializer: Request.sessionTokenFromUserResponseSerializer(), completionHandler: { (request, response, sessionToken, error) in
      completionHandler(request, response, sessionToken as? String, error)
    })
  }

  
}