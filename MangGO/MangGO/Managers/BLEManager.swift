//
//  BLEManager.swift
//  MangGO
//
//  Created by Feivel Qutby on 12/08/26.
//

import Foundation
import CoreBluetooth
import Combine

struct BLEMeasurement: Codable {
    let weight: Double
}

enum BLEEvent {
    case loadCellReady
    case loadCellOffline
    case servoReady
    case servoOffline
    case hardwareReady
    case measurementStarted
    case capture1
    case capture2
    case measurement(BLEMeasurement)
    case measurementComplete
}

final class BLEManager: NSObject, ObservableObject {
    
    @Published private(set) var isConnected = false
    @Published private(set) var lastMeasurement: BLEMeasurement?
    @Published private(set) var lastEvent: BLEEvent?
    
    private var centralManager: CBCentralManager!
    private var esp32Peripheral: CBPeripheral?
    
    private var commandCharacteristic: CBCharacteristic?
    private var eventCharacteristic: CBCharacteristic?
    
    private let serviceUUID =
    CBUUID(string: "12345678-1234-1234-1234-123456789000")
    
    // iPhone → ESP32
    private let commandUUID =
    CBUUID(string: "12345678-1234-1234-1234-123456789001")
    
    // ESP32 → iPhone
    private let eventUUID =
    CBUUID(string: "12345678-1234-1234-1234-123456789002")
    
    override init() {
        super.init()
        
        centralManager = CBCentralManager(
            delegate: self,
            queue: .main
        )
    }
    
    // MARK: - Scanning
    
    func start() {
        guard centralManager.state == .poweredOn else {
            return
        }
        
        startScanning()
    }
    
    private func startScanning() {
        
        print("Scanning for MangGO-ESP32...")
        
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ]
        )
    }
    
    // MARK: - Commands
    
    func sendCommand(_ command: String) {
        
        guard let peripheral = esp32Peripheral,
              let characteristic = commandCharacteristic else {
            
            print("BLE command failed: ESP32 not ready")
            return
        }
        
        let data = Data(command.utf8)
        
        peripheral.writeValue(
            data,
            for: characteristic,
            type: .withResponse
        )
        
        print("iPhone → ESP32: \(command)")
    }
    
    // MARK: - Event Handling
    
    private func handleEvent(from data: Data) {
        
        guard let message = String(
            data: data,
            encoding: .utf8
        ) else {
            return
        }
        
        print("ESP32 → iPhone: \(message)")
        
        switch message {
            
        case "LOAD_CELL_READY":
            lastEvent = .loadCellReady
            
        case "LOAD_CELL_OFFLINE":
            lastEvent = .loadCellOffline
            
        case "SERVO_READY":
            lastEvent = .servoReady
            
        case "SERVO_OFFLINE":
            lastEvent = .servoOffline
            
        case "HARDWARE_READY":
            lastEvent = .hardwareReady
            
        case "MEASUREMENT_STARTED":
            lastEvent = .measurementStarted
            
        case "CAPTURE_1":
            lastEvent = .capture1
            
        case "CAPTURE_2":
            lastEvent = .capture2
            
        case "MEASUREMENT_COMPLETE":
            lastEvent = .measurementComplete
            
        default:
            guard let measurementData = message.data(
                using: .utf8
            ) else {
                return
            }
            do {
                let measurement =
                try JSONDecoder().decode(
                    BLEMeasurement.self,
                    from: measurementData
                )
                
                lastMeasurement = measurement
                
                lastEvent = .measurement(measurement)
                
                print("Weight: \(measurement.weight) g")
                
            } catch {
                
                print(
                    "Unknown BLE message: \(message)"
                )
                
                print(
                    "Decode error: \(error)"
                )
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(
        _ central: CBCentralManager
    ) {
        
        switch central.state {
            
        case .poweredOn:
            
            print("Bluetooth is ON")
            startScanning()
            
        case .poweredOff:
            
            print("Bluetooth is OFF")
            
        case .unsupported:
            
            print("Bluetooth not supported")
            
        case .unauthorized:
            
            print("Bluetooth permission denied")
            
        case .unknown:
            
            print("Bluetooth state unknown")
            
        case .resetting:
            
            print("Bluetooth resetting")
            
        @unknown default:
            
            print("Unknown Bluetooth state")
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        print("📡 FOUND DEVICE")
        print("Name:", peripheral.name ?? "nil")
        print("UUID:", peripheral.identifier)
        print("RSSI:", RSSI)
        print("Advertisement:", advertisementData)
        
        // Stop scanning once MangGO ESP32 is found
        central.stopScan()
        
        // Save the peripheral
        esp32Peripheral = peripheral
        peripheral.delegate = self
        
        // Connect to ESP32
        print("🔗 Connecting to MangGO-ESP32...")
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        
        print("Connected to MangGO-ESP32!")
        
        isConnected = true
        
        peripheral.delegate = self
        
        peripheral.discoverServices(
            [serviceUUID]
        )
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        
        print("ESP32 disconnected")
        
        isConnected = false
        
        commandCharacteristic = nil
        eventCharacteristic = nil
        
        start()
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        
        print("Failed to connect:", error?.localizedDescription ?? "unknown")
        
        isConnected = false
        
        start()
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        
        if let error {
            
            print(
                "Service discovery error:",
                error
            )
            
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            
            print(
                "Found service:",
                service.uuid
            )
            
            guard service.uuid == serviceUUID else {
                continue
            }
            
            peripheral.discoverCharacteristics(
                [commandUUID, eventUUID],
                for: service
            )
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        
        if let error {
            
            print(
                "Characteristic discovery error:",
                error
            )
            
            return
        }
        
        guard let characteristics =
                service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            
            print(
                "Found characteristic:",
                characteristic.uuid
            )
            
            if characteristic.uuid == commandUUID {
                
                commandCharacteristic =
                characteristic
                
                print(
                    "Command characteristic found!"
                )
            }
            
            if characteristic.uuid == eventUUID {
                
                eventCharacteristic =
                characteristic
                
                print(
                    "Event characteristic found!"
                )
                
                peripheral.setNotifyValue(
                    true,
                    for: characteristic
                )
            }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {

        if let error {
            print("Notification setup error:", error)
            return
        }

        guard characteristic.uuid == eventUUID else {
            return
        }

        if characteristic.isNotifying {

            print("🔔 Event notifications ENABLED")

            sendCommand("REQUEST_HARDWARE_STATUS")
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        
        if let error {
            
            print(
                "BLE receive error:",
                error
            )
            
            return
        }
        
        guard characteristic.uuid == eventUUID else {
            return
        }
        
        guard let data =
                characteristic.value else {
            return
        }
        
        handleEvent(from: data)
    }
}
