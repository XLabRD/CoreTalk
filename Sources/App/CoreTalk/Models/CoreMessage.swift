
import Vapor
//
//


protocol CoreTalkRepresentable where Self: Codable {
    associatedtype BodyType
    
    var verb: String? { get  }
    var raw: String? { get set }
    var body: [String: BodyType]? { get }
}


extension CoreTalkRepresentable {
    var verb:String? {
        get {
            guard let raw = self.raw else {
                print("[CoreTalkRepresentable] FOUND NIL")
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
    
    var body:[String:BodyType]? {
        get {
            guard let raw = self.raw else {
                return nil
            }
            do {
                let data = raw.data(using: .utf8)!
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let object = json as? [String: Any] {
                    if let verb = self.verb {
                        return object[verb] as? [String: BodyType]
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
    typealias BodyType = Any
    
    var raw: String?
}


//SETUP
struct CoreHandshake: Encodable {
    let name = CoreTalkSettings.ServerName
    let version = CoreTalkSettings.ServerVersion
    let timeStamp = Date().ctStringValue()    
}

struct AKN: Encodable {
    let ok: String
    
    init(request:String?) {
        guard let request = request else {
            self.ok = "unkown"
            return
        }
        
        self.ok = request
    }
    
}

struct ServerMessage: Encodable {
    let message: String
    let code: Int?
}

