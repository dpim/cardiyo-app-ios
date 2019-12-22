//
//  LikedByViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 1/21/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import FacebookLogin
import FacebookCore
import Alamofire
import AlamofireImage
import SwiftyJSON
import HealthKit

class LikedByViewController: UITableViewController {
    var recordId: String?
    var names: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title="Liked By"
        self.names = []
        self.fetchLikers()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.selectionStyle = .blue
        if (self.names.count > 0 && indexPath.row <= self.names.count){
            cell.textLabel?.text = "☺️ \(names[indexPath.row])"
        } else {
            cell.textLabel?.text = ""
        }
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }
    
    
    func fetchLikers(){
        let token = AccessToken.current!.authenticationToken
        let headers: HTTPHeaders = [
            "access_token": token,
            "Accept": "application/json"
        ]
        Alamofire.request("https://cyoapp.azurewebsites.net/v1/likersForRecord/"+self.recordId!, method: .get, headers: headers).responseJSON
            { response in
                do {
                    if (response.data != nil){
                        if ((response.data?.count)! > 0){
                            let json = try? JSONSerialization.jsonObject(with: response.data!, options: [])
                            if (json != nil){
                                let arr = json as! NSArray
                                for entry in arr {
                                    let entryDict = entry as! [String: Any?]
                                    let name = entryDict["name"]
                                    if (name != nil){
                                        let name_str = name as! String
                                        let name = self.truncateName(name: name_str)
                                        self.names.append(name)
                                }
                            }
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func truncateName(name: String)->String{
        var result = ""
        var parts = name.characters.split{$0 == " "}.map(String.init)
        let part1: String = parts[0]
        let part2: String = parts[1]
        let index = part2.index(part2.startIndex, offsetBy: 1)
        result = part1 + " " + part2.substring(to: index)+"."
        return result
    }
    
}
