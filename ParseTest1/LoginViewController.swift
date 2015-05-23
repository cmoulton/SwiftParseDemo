//
//  LoginViewController.swift
//  ParseTest1
//
//  Created by Christina Moulton on 2015-03-18.
//  Copyright (c) 2015 Teak Mobile Inc. All rights reserved.
//

import Foundation
import UIKit

class LoginViewController: UIViewController {

  @IBOutlet weak var userField: UITextField?
  @IBOutlet weak var passwordField: UITextField?
  
  
  @IBAction func signIn(sender: UIButton) {
    if (validateFields() == false) {
      return
    }
    APIController.sharedInstance.login(self.userField!.text, password: self.passwordField!.text, completionHandler: { (success, error) in
      if error != nil
      {
        // TODO: improved error handling
        var alert = UIAlertController(title: "Error", message: "Could not login :( \nError message:\n \(error!.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
      }
      if success {
        self.dismissViewControllerAnimated(true, completion: nil)
      }
    })
  }
  
  @IBAction func signUp(sender: UIButton) {
    if (validateFields() == false) {
      return
    }
    APIController.sharedInstance.signUp(self.userField!.text, password: self.passwordField!.text, completionHandler: { (success, error) in
      if error != nil
      {
        // TODO: improved error handling
        var alert = UIAlertController(title: "Error", message: "Could not sign up :( \nError message:\n \(error!.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
      }
      if success {
        self.dismissViewControllerAnimated(true, completion: nil)
      }
    })
  }
  
  func validateFields() -> Bool
  {
    if userField?.text.isEmpty == true {
      var alert = UIAlertController(title: "Error", message: "Username is required", preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
      return false
    }
    if passwordField?.text.isEmpty == true {
      var alert = UIAlertController(title: "Error", message: "Password is required", preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
      return false
    }

    return true
  }

}
