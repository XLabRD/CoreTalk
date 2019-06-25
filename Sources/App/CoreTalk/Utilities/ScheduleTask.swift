//
//  ScheduleTask.swift
//  App
//
//  Created by Francisco Lobo on 6/25/19.
//

import Vapor

class ScheduleQueue {
    static let defaultQueue = ScheduleQueue()
    private var queue = [ScheduledTask]()
    
    func enqueue(task: ScheduledTask) {
        self.queue.append(task)
        
        task.cleanupCallBack = {
            let indexOf = self.queue.firstIndex(of: task)
            if let idx = indexOf {
                self.queue.remove(at: idx)
            } else {
                print("[ScheduleTask] Lost reference of task!")
            }
        }
    }
    
}

class ScheduledTask: Equatable {
    typealias CleanupCallBack = () -> Void
    let timer = DispatchSource.makeTimerSource()
    var initialized = false
    var event: () -> Void
    var cleanupCallBack: CleanupCallBack?
    private var hash = UUID()
    
    static func perform(in time: DispatchTimeInterval, do event:@escaping () -> Void) {
        let _ =  ScheduledTask(in: time, do: event)
    }
    
    init(in time: DispatchTimeInterval, do event:@escaping () -> Void) {
        self.event = event
        timer.schedule(deadline: .now(), repeating: time, leeway: .seconds(0))
        timer.setEventHandler(handler: { [weak self] in
            
            if self?.initialized == true {
                self?.fireEvent()
                self?.timer.suspend()
                if let cleanup = self?.cleanupCallBack {
                    cleanup()
                }
            }
            self?.initialized = true
        })
        
        timer.resume()
        let dq = ScheduleQueue.defaultQueue
        dq.enqueue(task: self)
        
    }
    
    static func == (lhs: ScheduledTask, rhs: ScheduledTask) -> Bool {
        if lhs === rhs { return true }
        return false
    }
    
    
    func fireEvent() {
        event()
    }
}
