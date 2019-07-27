import Vapor



class CoreTalkServer {
    private var connections = ClientManager()
    private var services: ServiceManager
    private var gateKeeper = GateKeeper()
        
    init(with serviceManager: ServiceManager) {
        self.services = serviceManager
        
        print("[SocketServer] Boot Complete")
    }
    
    public func sockets(_ server: NIOWebSocketServer)  {
        
        server.get(CoreTalkSettings.EndPoint) { ws, req in
            
            let connection = Connection(socket: ws)
            print("[SocketServer] Socket open")
            connection.currentHostName = req.http.remotePeer.hostname
            self.connections.attach(connection: connection)
            connection.send(object: CoreHandshake())
            let event = CoreTalkEvent(kind: .connections, sourceConnection: connection, sourceService: nil, changes: nil)
            self.services.publish(event: event)
                        
            
            ws.onClose.always {
                print("[SocketServer] Socket Closed")
                let event = CoreTalkEvent(kind: .disconnections,
                                          sourceConnection: connection,
                                          sourceService: nil,
                                          changes: nil)
                self.services.publish(event: event)
                self.connections.detach(socket: ws)                
            }
            
            ws.onText { ws, text in                
                guard var source = self.connections[ws] else {
                    return
                }
                
                guard let route = try? Route(jsonString: text) else {
                    let err = CoreTalkError(type: .InvalidFormat)
                    source.send(object: err)
                    return
                }
                
                let result =  self.services.handle(route: route, source: &source, pool: self.connections, req: req)

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
                print("[WebSocketServer] Unable to start server. Error: \(error)")
            }
        }
    }
}
