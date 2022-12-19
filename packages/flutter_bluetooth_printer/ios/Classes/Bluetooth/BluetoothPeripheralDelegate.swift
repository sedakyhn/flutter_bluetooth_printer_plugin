import Foundation
import CoreBluetooth

class BluetoothPeripheralDelegate: NSObject, CBPeripheralDelegate {

    private var services: Set<String>!
    private var characteristics: Set<CBUUID>?

    private let writablecharacteristicUUID = "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F"

    var wellDoneCanWriteData: ((CBPeripheral) -> ())?
    var didWriteData: ((CBPeripheral, Error?) -> ())?

    private(set) var writablePeripheral: CBPeripheral?
    private(set) var writablecharacteristic: CBCharacteristic? {
        didSet {
            if let wc = writablecharacteristic, let wp = writablePeripheral {
                wp.setNotifyValue(true, for: wc)
                wellDoneCanWriteData?(wp)
            }
        }
    }

    convenience init(_ services: Set<String>, characteristics: Set<String>?) {
        self.init()
        self.services = services
        self.characteristics = (characteristics?.map { CBUUID(string: $0) }).map { Set($0) }
    }

    func disconnect(_ peripheral: CBPeripheral) {

        guard let wp = writablePeripheral else {
            return
        }

        if wp.identifier == peripheral.identifier {

            writablePeripheral = nil
            writablecharacteristic = nil
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        guard error == nil else { return }

        guard let prServices = peripheral.services else {
            return
        }

        prServices.filter { services.contains($0.uuid.uuidString) }.forEach {
            peripheral.discoverCharacteristics(nil, for: $0)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        writablePeripheral = peripheral
        writablecharacteristic = service.characteristics?.filter { $0.uuid.uuidString == writablecharacteristicUUID }.first
    }
    
    var lastWriteError: Error?
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil){
            print(error!)
            lastWriteError = error
            return
        }
        didWriteData?(peripheral, error)
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        let error = lastWriteError
        lastWriteError = nil
        didWriteData?(peripheral, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
}

public typealias DidConnected = (() ->())
