//
//  SettingsViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 10/10/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import FacebookCore
import FacebookLogin


class SettingsViewController: UITableViewController {
    
    let profileSection = 0
    let hrmSection = 1
    let accountSection = 2
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.title="Me"
        self.navigationItem.title="Me"
        self.tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad() 
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (self.view.frame.height < 560){
            if (section == profileSection){
                return 40.0
            } else {
                return 20.0
            }
        } else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath.section == accountSection && indexPath.row == 0){
            showAbout()
        }
        if (indexPath.section == accountSection && indexPath.row == 1){
            logout()
        }
        if (indexPath.section == profileSection && indexPath.row == 0){
            //go to my history view
            showHistory()
        }
        if (indexPath.section == profileSection && indexPath.row == 1){
            //go to my history view
            showStats()
        }
        if (indexPath.section == hrmSection && indexPath.row == 0){
            showSensors()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if (section == accountSection){
            let name = UserProfile.current?.fullName
            if (name != nil){
                return "Logged in as: " + name!
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func logout(){
        
        //log out of fb
        let manager = LoginManager()
        manager.logOut()
        
        //move to login screen
        let vc : AnyObject! = self.storyboard!.instantiateViewController(withIdentifier: "loginVC")
        self.show(vc as! UIViewController, sender: vc)
    }
    
    func showAbout(){
        performSegue(withIdentifier:"SettingsToAbout", sender: nil)
    }
    
    func showHistory(){
        performSegue(withIdentifier: "SettingsToPersonalHistory", sender: nil)
    }
    
    func showStats(){
        performSegue(withIdentifier: "SettingsToStats", sender: nil)
    }
    
    func showSensors(){
        performSegue(withIdentifier: "SettingsToSensors", sender: nil)
    }
}
