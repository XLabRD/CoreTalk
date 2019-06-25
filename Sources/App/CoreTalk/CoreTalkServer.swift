import Vapor



class CoreTalkServer {
    //setup
    static let EndPoint = "coretalk"
    //setup        
    private var connections = ConnectionPool()
    private var services = ServicePool()
    
    init(with coreTalkServices: [CoreTalkService]) {
        
        for service in coreTalkServices {
            self.services.attach(service: service)
        }
        
        print("[SocketServer] Initialized and ready.")
    }
    
    public func sockets(_ websockets: NIOWebSocketServer)  {
        
        websockets.get(CoreTalkServer.EndPoint) { ws, req in
            
            let connection = Connection(socket: ws)
            print("[SocketServer] Socket open.")
            self.connections.attach(connection: connection)
            connection.send(object: CoreHandshake())
            
            
            ws.onClose.always {
                print("[SocketServer] Socket Closed.")
                self.connections.detach(socket: ws)
            }
            
            ws.onText { ws, text in
                let ct = CoreTalkMessage(raw: text)
                guard var source = self.connections.findConnection(from: ws) else {
                    return
                }
                
                let result =  self.services.handle(message: ct, source: &source, pool: self.connections)
                if result != .ok {
                    switch result {
                    case .invalidFormat:
                        let err = CoreTalkError(type: .InvalidFormat)
                        source.send(object: err)
                    case .permissionDenied:
                        let err = CoreTalkError(type: .PermissionDenied)
                        source.send(object: err)
                    case .serviceNotFound:
                        let err = CoreTalkError(type: .ServiceNotFound)
                        source.send(object: err)
                    default:
                        let err = CoreTalkError(type: .Unknown)
                        source.send(object: err)
                    }
                    
                }
                
            }
            
            ws.onError { ws, error in
                print("[WebSocketServer] Unable to start server")
            }
        }
    }
}