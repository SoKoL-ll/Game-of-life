import Foundation
import UIKit

protocol CATiledDataSource: AnyObject {
    var viewport: Rect { get }
    func getCell(at point: Point) -> Bool
    func pasteMode(from state: State, screen image: UIImageView)
    func setStatefromSnapshot(from state: State)
    func deleteSnapshot(at ind: Int)
    func getTypeOfPoint() -> Bool
}
