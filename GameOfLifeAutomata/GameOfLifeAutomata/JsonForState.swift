import Foundation
import UIKit

struct Json: Encodable, Decodable {
    let id: UUID
    let createdAt: String?
    let updatedAt: String?
    let width: Int
    let height: Int
    let name: String
    let description: String?
    let origin: Point?
    let image: UIImage?
    let cells: [Bool]
    let user: String?
    let type: Bool?
    
    func fromJsonToState() -> State {
        var newArray = [BinaryCell]()
        for pos in 0..<(width * height) {
            if (cells.count > pos) {
                newArray.append(cells[pos] ? BinaryCell.active : BinaryCell.inactive)
            } else {
                newArray.append(BinaryCell.inactive)
            }
        }
        
        return State(name: self.name, id: self.id, viewport: Rect(origin: origin ?? Point(x: 0, y: 0), size: Size(width: self.width, height: self.height)), array: newArray, image: image ?? nil, type: type ?? nil)
    }
}

struct JsonForState: Codable {
    let code: UInt8?
    let state: Json
}

public protocol ImageCodable: Codable {}
extension UIImage: ImageCodable {}

extension ImageCodable where Self: UIImage {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(data: try container.decode(Data.self))!
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.pngData()!)
    }
}
