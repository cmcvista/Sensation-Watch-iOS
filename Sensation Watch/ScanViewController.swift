//
//  ScanViewController.swift
//  Sensation Watch
//
//  Created by Chriz Chow on 2/25/17.
//  Copyright © 2017 Sensation. All rights reserved.
//

import UIKit
import Foundation

class ScanViewController : UIViewController, UITableViewDelegate, bleScannerDelegate {
    
    lazy var bScanObj = bleScanner()
    @IBOutlet weak var deviceTable: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: - i18n Strings for displaying on UI:
    let str_BT_ON = NSLocalizedString("Bluetooth Status: On", comment: "bluetooth on")
    let str_BT_OFF = NSLocalizedString("Bluetooth Status: Off", comment: "bluetooth off")
    let str_BT_NS = NSLocalizedString("Bluetooth is NOT supported", comment: "bluetooth unsupport")
    let str_BT_STRANGE = NSLocalizedString("Bluetooth is Strange", comment: "bluetooth strange")
    
    override func viewDidLoad() {
        
        //link the devicetable:
        //deviceTable.delegate = self
        deviceTable.dataSource = self
        
        //change color to sky blue:
        navigationController!.navigationBar.barTintColor =
            UIColor.init(red: 0.529, green: 0.807, blue: 0.990, alpha: 0.01) //sky blue
        
    }
    
    override func viewDidAppear(_ animated: Bool){
        //initialize the ble scanner:
        bScanObj = bleScanner()
        bScanObj.delegate = self
        
        //start the ble scanner:
        bScanObj.startScanner()
        
    }
    
    // MARK: - Implementing Delegates of BLE Scanner
    func updateState(state: bleStatus){
        switch(state){
        case bleStatus.Bluetooth_ON:
            statusLabel.text = str_BT_ON
            bScanObj.startDeviceScanning()      //we want scanning upon bt on
            
        case bleStatus.Bluetooth_OFF:
            statusLabel.text = str_BT_OFF
            bScanObj.clearDevicesTable()        //avoid unexpected click
            
        case bleStatus.Bluetooth_UNSUPPORTED:
            statusLabel.text = str_BT_NS
            
        default:
            statusLabel.text = str_BT_STRANGE
            
        }
    }
    
    func updateDeviceTable(){
        deviceTable.reloadData()
    }
    
    
    // MARK: - Navigation
    
    // Do preparation before navigation, this will be triggred before going to next screen:
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //Pass the BleDevice Object to the next View Controller:
        if(segue.identifier == "ConnectDevice"){
            let deviceCtrlVC = segue.destination as! DeviceControlViewController
            if let selectedDeviceCell = sender as? BleDeviceTableViewCell {
                let indexPath = deviceTable.indexPath(for: selectedDeviceCell)!
                let selectedDevice = bScanObj.devices[(indexPath as NSIndexPath).row]
                let selectedName = selectedDevice.advertisementData["kCBAdvDataLocalName"] as? String
                
                //transfer the CoreBluetooth manager and peripheral to new class:
                deviceCtrlVC.devCtrlObj.transferManagerPeripheral(
                    manger: bScanObj.manager!,
                    peripheral: selectedDevice.peripheral,
                    peripheralName: selectedName!)
                
                //Stop scanning to save power:
                bScanObj.stopScanning()
                
                
            }
        }
        
    }
    
    
}

// MARK: - Implementing Delegates of UITableViewDataSource
extension ScanViewController: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bScanObj.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "BleDeviceTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! BleDeviceTableViewCell
        
        // Fetches the appropriate meal for the data source layout.
        let device = bScanObj.devices[(indexPath as NSIndexPath).row]
        let localName = device.advertisementData["kCBAdvDataLocalName"] as? String
        cell.deviceName.text = localName ?? "Unnamed Device"
        cell.RSSI.text = "\(bleScanner.signalPercentage(device: device))%"
        
        //highlight "Sensation"
        if(cell.deviceName.text!.contains("Sensation")){
            cell.backgroundColor = UIColor.yellow
            cell.deviceIcon.image = #imageLiteral(resourceName: "device_known")
            
        }else{
            cell.backgroundColor = UIColor.white
            cell.deviceIcon.image = #imageLiteral(resourceName: "device_unknown")
        }
        
        return cell
    }

    
}
