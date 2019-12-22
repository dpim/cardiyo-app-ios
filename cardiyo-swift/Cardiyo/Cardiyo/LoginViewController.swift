//
//  ViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 10/9/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin

class LoginViewController: UIViewController {

    @IBOutlet var myLoginButton: UIButton!
    @IBOutlet var logoView: UIImageView!
    @IBOutlet var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet var logoWidthConstraint: NSLayoutConstraint!

    override func viewWillAppear(_ animated: Bool)
    {
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: navigationController, action: nil)
        self.navigationItem.title = "Login"
        navigationItem.leftBarButtonItem = backButton
        UIView.animate(withDuration: 2.0, delay: 1, options: [.curveEaseIn, .repeat, .autoreverse], animations: {
            self.logoHeightConstraint.constant = 175;
            self.logoWidthConstraint.constant = 175;
            self.logoView.layoutIfNeeded()
        }, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        if AccessToken.current != nil {
            //logged in
        } else {
            // Handle clicks on the button
            myLoginButton.addTarget(self, action: #selector(loginButtonClicked), for: .touchUpInside)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    @IBAction func termsButtonPressed(){
        self.performSegue(withIdentifier: "LoginToTerms", sender: self);
    }
    
    // Once the button is clicked, show the login dialog
    @objc func loginButtonClicked() {
        UserProfile.updatesOnAccessTokenChange = true
        let loginManager = LoginManager()
        loginManager.logIn([ .publicProfile ], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print("login error")
            case .cancelled:
                print("User cancelled login.")
            case .success(let _grantedPermissions, let _declinedPermissions, let accessToken):
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
}
