
import Vapor

protocol CoreTalkRepresentable: Codable {
    var verb: String? { get  }
    var raw: String? { get set }
    var body: [String:Any]? { get }
}


extension CoreTalkRepresentable {
    var verb:String? {
        get {
            guard let raw = self.raw else {
                return nil
            }
            do {
                let data = raw.data(using: .utf8)!
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let object = json as? [String: Any] {
                    return object.keys.first
                }
            } catch {
                return nil
            }
            return nil
        }
    }
    
    var body:[String:Any]? {
        get {
            guard let raw = self.raw else {
                return nil
            }
            do {
                let data = raw.data(using: .utf8)!
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let object = json as? [String: Any] {
                    if let verb = self.verb {
                        return object[verb] as? [String:Any]
                    }
                }
            } catch {
                return nil
            }
            return nil
        }
    }
    
}

struct CoreTalkMessage: CoreTalkRepresentable  {    
    var raw: String?
}

extension Date {
     func ctStringValue() -> String {
        let formatter = DateFormatter()
        //SETUP
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        let myString = formatter.string(from: self)
        return myString
    }
}


struct WireMessage { //Send to client
    static func encode<T: Encodable>(object: T) -> String {
        let jsonData = try! JSONEncoder().encode(object)
        return String(data: jsonData, encoding: .utf8)!
    }
}


//SETUP
struct CoreHandshake: Encodable {
    let name = "CoreTalk"
    let version = "0.1"
    let timeStamp = Date().ctStringValue()    
}
