//
//  ViewController.swift
//  bleGamer
//
//  Created by roger deutsch on 3/20/23.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController , CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    
    @IBOutlet var outputMessages: UITextView!
    @IBOutlet var deviceText: UITextField!
    @IBOutlet var sendText: UITextField!
    
    var currentPeripheral : CBPeripheral!
    var centralManager : CBCentralManager?
    let inputStringUUID = CBUUID(string: "622B2C55-7914-4140-B85B-879C5E252DA0")
    let outputStringUUID = CBUUID(string: "643954A4-A6CC-455C-825C-499190CE7DB0")
    var inputCharacteristic : CBCharacteristic?
    var outputCharacteristic : CBCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // viewDidLoad() runs BEFORE CentralManager initialization
        //Initialize CoreBluetooth Central Manager
        self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            
        }
        else {
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func ScanForBle(_ sender : UIButton){
        // when the following scan method runs, the centralManager() discover method
        // gets called (method is marked with a comment below)
        outputMessages.text += "Getting device...\n"
        self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    
    @IBAction func Connect(_ sender : UIButton){
        centralManager?.connect(currentPeripheral)
        
    }
    
    @IBAction func Read(_ sender: UIButton){
        outputMessages.text += "Attempting read...\n"
        guard let peripheral = currentPeripheral,
              let outputCharacteristic = outputCharacteristic else{
            outputMessages.text += "Connection error!\n"
            return
        }
        peripheral.readValue(for: outputCharacteristic)
        
    }
    
    @IBAction func Send(_ sender : UIButton){
        guard let peripheral = currentPeripheral,
              let inputCharacteristic = inputCharacteristic else{
            outputMessages.text += "Connection error!\n"
            return
        }
        outputMessages.text += "Sending...\n"
        
        let sendMsg = (sendText.text ?? "no data to send") + "\n"
        var data = sendMsg.data(using: String.Encoding.ascii)
        peripheral.writeValue(data ?? Data(), for:inputCharacteristic, type: .withoutResponse)
            
//            sendMsg?.fastestEncoding.rawValue, for: inputCharacteristic, type: .withoutResponse)
    }
    
    @IBAction func Disconnect(_ sender: UIButton){
        centralManager?.cancelPeripheralConnection(currentPeripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // This is the Discover method which will list all the peripherals it
        // finds with
        
        // We only care about 1 named BLE device
        if (peripheral.name != nil && peripheral.name != ""){
            outputMessages.text += "name: \(String(describing: peripheral.name ?? "empty name"))\n"
            if peripheral.name?.lowercased() == deviceText.text?.lowercased()
            {
                // we've found the device we are looking for
                // so we save it for later use and
                outputMessages.text += "Got: \(String(describing: peripheral.name ?? "empty name"))\n"
                currentPeripheral = peripheral
                central.stopScan()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        outputMessages.text += "Successfully connected.\n"
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else{
            outputMessages.text += "Found 0 services on device.\n"
            return
        }
        for service in services{
            outputMessages.text += "Discovering services...\n"
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else{
            outputMessages.text += "Found 0 characteristics on service.\n"
            return
        }
        
        for item in characteristics{
            switch item.uuid{
            case inputStringUUID:
                inputCharacteristic = item
            case outputStringUUID:
                outputCharacteristic = item
                self.currentPeripheral.setNotifyValue(true, for: item)
            default:
                break
            }
            outputMessages.text += "\(item.uuid.uuidString)\n"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        outputMessages.text += "Data was updated...\n"
        if characteristic.uuid == outputStringUUID,
           let data = characteristic.value{
            outputMessages.text += (String(data: data, encoding: .utf8) ?? "") + "\n" + data.description + "\n"
            
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }
}

