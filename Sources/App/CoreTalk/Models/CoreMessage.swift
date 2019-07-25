
import Vapor

struct Route: Codable {
    var id: Int?
    var type: String?
    var jsonData: Data?
    
    enum RouteError: Error {
        case decodingError
    }
    
    init(jsonString: String) throws {
        let decoder = JSONDecoder()
        if let jsonData = jsonString.data(using: .utf8) {
            self = try decoder.decode(Route.self, from: jsonData)
            self.jsonData = jsonData
        }
    }
    
    func decode<E:Codable>(to type:E.Type) throws -> E {
        
        guard let jsonData = self.jsonData else {
            throw RouteError.decodingError
        }
        
        return try JSONDecoder().decode(E.self, from: jsonData)
    }
}

struct CoreHandshake: Encodable {
    let name = CoreTalkSettings.ServerName
    let version = CoreTalkSettings.ServerVersion
    let timeStamp = Date().coreTalkDateString()    
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

