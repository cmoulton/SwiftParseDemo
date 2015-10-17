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
  let keys: NSDictionary?
  
  required init() {
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    manager = Alamofire.Manager(configuration: configuration)
    if let path = NSBundle.mainBundle().pathForResource("keys", ofType: "plist") {
      keys = NSDictionary(contentsOfFile: path)
    } else {
      keys = nil
    }
  }
  
  func getSpotsWithBasicAuth(completionHandler: (Result<[Spot], NSError>) -> Void) {
    let appID = keys?[KeyFields.appID.rawValue] as? String
    let jsKey = keys?[KeyFields.jsKey.rawValue] as? String
    let clientKey = keys?[KeyFields.clientKey.rawValue] as? String
    if appID == nil || jsKey == nil {
      let error = NSError(domain: "parseAPICall", code: 200, userInfo: [NSLocalizedDescriptionKey: "Could not load API keys from keys.plist"])
      completionHandler(.Failure(error))
      return
    }
    
    let username = appID!
    // note: javascript key is different from REST API key, get it from
    // Parse project -&gt; Settings (at top) -&gt; Keys -&gt; Javascript Key
    let password = "javascript-key=" + jsKey!
    
    // add our auth headers
    manager.session.configuration.HTTPAdditionalHeaders = [
      "X-Parse-Application-Id": appID!,
      "X-Parse-Client-Key": clientKey!
    ]
    
    manager.request(.GET, "https://api.parse.com/1/classes/Spot/")
      .validate()
      .authenticate(user: username, password: password)
      .responseSpotsArray { response in
        completionHandler(response.result)
    }
  }
  
  func getSpotsWithBasicAuthCredential(completionHandler: (Result<[Spot], NSError>) -> Void) {
    let appID = keys?[KeyFields.appID.rawValue] as? String
    let jsKey = keys?[KeyFields.jsKey.rawValue] as? String
    if appID == nil || jsKey == nil {
      let error = NSError(domain: "parseAPICall", code: 200, userInfo: [NSLocalizedDescriptionKey: "Could not load API keys from keys.plist"])
      completionHandler(.Failure(error))
      return
    }
    
    let username = appID!
    // note: javascript key is different from REST API key, get it from
    // Parse project -&gt; Settings (at top) -&gt; Keys -&gt; Javascript Key
    let password = "javascript-key=" + jsKey!
    
    let credential = NSURLCredential(user: username, password: password, persistence: NSURLCredentialPersistence.ForSession)
    
    manager.request(.GET, "https://api.parse.com/1/classes/Spot/")
      .authenticate(usingCredential: credential)
      .responseSpotsArray { response in
        completionHandler(response.result)
    }
  }
}

extension Alamofire.Request {
  func responseSpotsArray(completionHandler: (Response<[Spot], NSError>) -> Void) -> Self {
    let serializer = ResponseSerializer<[Spot], NSError> { request, response, data, error in
      guard let responseData = data else {
        let failureReason = "Array could not be serialized because input data was nil."
        let error = Error.errorWithCode(.DataSerializationFailed, failureReason: failureReason)
        return .Failure(error)
      }
      
      let JSONResponseSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
      let result = JSONResponseSerializer.serializeResponse(request, response, responseData, error)
      
      if result.isSuccess {
        if let value = result.value {
          let json = SwiftyJSON.JSON(value)
          if let errorString = json["error"].string {
            return .Failure(NSError(domain: "parseAPICall", code: 200, userInfo: [NSLocalizedDescriptionKey: errorString]))
          }
          var allSpots = Array<Spot>()
          let results = json["results"]
          for (_, jsonSpot) in results
          {
            let id = jsonSpot["objectId"].intValue
            let name = jsonSpot["Name"].stringValue
            let lat = jsonSpot["Location"]["latitude"].doubleValue
            let lon = jsonSpot["Location"]["longitude"].doubleValue
            let spot = Spot(aName: name, aLat: lat, aLon: lon, anId: id)
            allSpots.append(spot)
          }
          return .Success(allSpots)
        }
      }
      
      // Check for error after trying to parse JSON, since sometimes we get descriptive errors in the JSON
      guard error == nil else {
        return .Failure(error!)
      }
      
      let error = Error.errorWithCode(.JSONSerializationFailed, failureReason: "JSON could not be converted to object")
      return .Failure(error)
    }
    
    return response(responseSerializer:serializer, completionHandler: completionHandler)
  }
}