import Foundation

class NetworkAccessManager {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue())
    
    init() {
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func getGlobalLibraryStates(onCompletion: @escaping ([State]) -> Void) {
        let url = URL(string: "https://itmo2021.wimag.io/items")
        guard let url = url else {
            return
        }
        let dataTask = session.dataTask(with: url) { data, response, error in
            guard let data = data else {
                return
            }
            do {
                let statesJson = try self.decoder.decode([Json].self, from: data)
                let states = statesJson.map({ $0.fromJsonToState() })
                
                DispatchQueue.main.async {
                    onCompletion(states)
                }
            } catch {
                print("Error of parsing jsons")
            }
        }
        dataTask.resume()
    }
}
