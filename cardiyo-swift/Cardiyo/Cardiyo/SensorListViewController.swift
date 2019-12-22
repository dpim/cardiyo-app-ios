//
//  SensorListViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 10/15/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import Foundation
import UIKit
import SwiftySensors

class SensorListViewController: UITableViewController {
    fileprivate var selectedSensor: Sensor?
    fileprivate var previousRowIdx: IndexPath?
    fileprivate var sensors: [Sensor] = []
    var activityIndicatorView: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        let activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        self.tableView.backgroundView = activityIndicatorView
        self.activityIndicatorView = activityIndicatorView
        self.activityIndicatorView?.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        SensorManager.instance.state = .passiveScan

        SensorManager.instance.onSensorDiscovered.subscribe(on: self) { [weak self] sensor in
            guard let s = self else { return }
            if !s.sensors.contains(sensor) {
                s.sensors.append(sensor)
                s.tableView.reloadData()
            }
            SensorManager.instance.state = .passiveScan
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sensors = SensorManager.instance.sensors
        tableView.reloadData()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let sensor = appDelegate.currentSensor {
                self.selectedSensor = sensor
                if let row = sensors.index(of: sensor){
                    self.previousRowIdx = IndexPath(row: row, section: 0)
                    if (row >= sensors.count){ return }
                    if let cell = self.tableView.cellForRow(at: self.previousRowIdx!){
                        cell.accessoryType = .checkmark
                    }
                } else {
                    self.selectedSensor = nil
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (sensors.count > 0){
            self.title = "External sensors"
            self.activityIndicatorView?.stopAnimating()
        } else {
            self.title = "Scanning..."
        }
        return sensors.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sensorCell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        if (sensors.count > 0){
            let sensor = sensors[indexPath.row]
            sensorCell.textLabel?.text = sensor.peripheral.name
        }
        return sensorCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sensor = sensors[indexPath.row]
        if let previousSensor = self.selectedSensor, let previousIdx = self.previousRowIdx {
            self.disconnectSensor(sensor: previousSensor, indexPath: previousIdx)
        }
        if sensor.peripheral.state == .connected {
            disconnectSensor(sensor: sensor, indexPath: indexPath)
            self.previousRowIdx = nil;
            self.selectedSensor = nil
        } else if sensor.peripheral.state == .disconnected {
            connectToSensor(sensor: sensor, indexPath: indexPath)
            self.previousRowIdx = indexPath;
            self.selectedSensor = sensor
        }
    }
    
    func disconnectSensor(sensor: Sensor, indexPath: IndexPath){
        let cell = self.tableView.cellForRow(at: indexPath)
        SensorManager.instance.disconnectFromSensor(sensor)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.currentSensor = nil
        }
        cell?.accessoryType = .none
    }
    
    func connectToSensor(sensor: Sensor, indexPath: IndexPath){
        let cell = self.tableView.cellForRow(at: indexPath)
        SensorManager.instance.connectToSensor(sensor)
        cell?.accessoryType = .checkmark
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.currentSensor = sensor
        }
    }
    
}
