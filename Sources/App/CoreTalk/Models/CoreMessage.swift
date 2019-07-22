
import Vapor

struct Route: Codable {
    var id: Int?
    var type: String?
    var jsonData: Data?
    
    init(jsonString: String) throws {
        let decoder = JSONDecoder()
        if let jsonData = jsonString.data(using: .utf8) {
            self = try decoder.decode(Route.self, from: jsonData)
            self.jsonData = jsonData
        }
    }
}

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

