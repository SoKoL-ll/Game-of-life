import Foundation

struct Json: Encodable, Decodable {
    let id: UUID
    let createdAt: String?
    let updatedAt: String?
    let width: Int
    let height: Int
    let name: String
    let description: String?
    let origin: Point?
    let cells: [Bool]
    let user: String?
    
    func fromJsonToState() -> State {
        var newArray = [BinaryCell]()
        for pos in 0..<(width * height) {
            if (cells.count > pos) {
                newArray.append(cells[pos] ? BinaryCell.active : BinaryCell.inactive)
            } else {
                newArray.append(BinaryCell.inactive)
            }
        }
        
        return State(name: self.name, id: self.id, viewport: Rect(origin: origin ?? Point(x: 0, y: 0), size: Size(width: self.width, height: self.height)), array: newArray)
    }
}

struct JsonForState: Codable {
    let code: UInt8?
    let state: Json
}
