import Foundation
import UIKit

class PreviewStates: ObservableObject {
    @Published var previewStatesArray = [State]()
}

class PreviewStatesWithBarrier {
    let queue = DispatchQueue(label: "my queue", attributes: .concurrent)
    var previewStates = PreviewStates()
    
    func append(_ previewState: State) {
        queue.async(flags: .barrier) {
            DispatchQueue.main.sync {
                self.previewStates.previewStatesArray.append(previewState)
            }
        }
    }
    
    func append(_ previewStatesToAdd: [State]) {
        queue.async(flags: .barrier) {
            DispatchQueue.main.sync {
                self.previewStates.previewStatesArray.append(contentsOf: previewStatesToAdd)
            }
        }
    }
    
    func firstIndex(of state: State) -> Int? {
        var pos: Int?
        queue.sync {
            pos = self.previewStates.previewStatesArray.firstIndex(of: state)
        }
        return pos
    }
    
    func map<T>(_ function: @escaping (State) -> T) -> [T] {
        var mapped: [T] = []
        queue.sync {
            mapped = self.previewStates.previewStatesArray.map({ function($0) })
        }
        return mapped
    }
}

class CloudStorageManager {
    var previewStatesWithBarrier = PreviewStatesWithBarrier()
    var previewStatesInitialOrigins = [Point]()
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func translateToInitial(state: State) -> State {
        var state = state
        let index = previewStatesWithBarrier.firstIndex(of: state) ?? 0
        state.translate(
            to: self.previewStatesInitialOrigins[index]
        )
        return state
    }
    
    func saveStateOnDisk(state: State, code: UInt8?) {
        DispatchQueue.global(qos: .utility).async {
            let fileUrl = self.getOutputFileUrl(file: "snapshot.txt")
            guard let fileUrl = fileUrl else {
                return
            }
            do {
                let data = try self.encoder.encode(
                    JsonForState(
                        code: code,
                        state: state.toJson()))
                try data.write(to: fileUrl)
            } catch {
                print("Error saving automata on disk")
            }
        }
    }
    
    func fetchStateFromDisk(onCompletion: @escaping (JsonForState?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileUrl = self.getOutputFileUrl(file: "snapshot.txt")
                guard let fileUrl = fileUrl else {
                    DispatchQueue.main.sync {
                        onCompletion(nil)
                    }
                    return
                }
                let data = try Data(contentsOf: fileUrl)
                let automata = try self.decoder.decode(JsonForState.self, from: data)
                DispatchQueue.main.sync {
                    onCompletion(automata)
                }
            } catch {
                DispatchQueue.main.sync {
                    onCompletion(nil)
                }
                print("Error fetching state from disk.")
            }
        }
    }
        
    func savePreviewsOnDisk() {
        DispatchQueue.global(qos: .userInitiated).async {
            let states = self.previewStatesWithBarrier.map {
                self.translateToInitial(state: $0)
            }
            let fileUrl = self.getOutputFileUrl(file: "state.txt")
            guard let fileUrl = fileUrl else {
                return
            }
            
            var decodedStates: [State] = []
            if self.fileExists(fileUrl: fileUrl) {
                decodedStates = self.readPreviewsFrom(fileUrl: fileUrl)
            }
            decodedStates.append(contentsOf: states)
            let previewsJson = decodedStates.map({ $0.toJson() })
            do {
                let data = try self.encoder.encode(previewsJson)
                try data.write(to: fileUrl)
            } catch {
                print(error)
                print("Error writing.")
            }
        }
    }
    
    func fetchPreviewsFromDisk() {
        DispatchQueue.global(qos: .userInteractive).async {
            let fileUrl = self.getOutputFileUrl(file: "state.txt")
            guard let fileUrl = fileUrl else {
                return
            }
            if (!self.fileExists(fileUrl: fileUrl)) {
                return
            }
            let decodedStates = self.readPreviewsFrom(fileUrl: fileUrl)
            var statesToAdd = [State]()
            for state in decodedStates {
                self.previewStatesInitialOrigins.append(state.viewport.origin)
                statesToAdd.append(state)
            }
            self.previewStatesWithBarrier.append(statesToAdd)
        }
    }
    
    func readPreviewsFrom(fileUrl: URL) -> [State] {
        do {
            let data = try Data(contentsOf: fileUrl)
            let previewsJson = try self.decoder.decode([Json].self, from: data)
            let previewStatesIds = self.previewStatesWithBarrier.map({ $0.id })
            let decodedStates = previewsJson.map { $0.fromJsonToState() }.filter { !previewStatesIds.contains($0.id) }
            return decodedStates
        } catch {
            print("Error parsing data from json or file is clear")
            return []
        }
    }
    
    func fileExists(fileUrl: URL) -> Bool {
        return FileManager.default.fileExists(atPath: fileUrl.path)
    }
    
    func getOutputFileUrl(file: String) -> URL? {
        let fm = FileManager.default
        if let _ = fm.ubiquityIdentityToken {
            //print("work")
        }
        
        let pathUrl = fm.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
 
        return pathUrl?.appendingPathComponent(file)
    }
}
