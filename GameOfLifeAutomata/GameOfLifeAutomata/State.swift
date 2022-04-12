import Foundation
import UIKit

struct State: CellularAutomataState, CustomStringConvertible, Identifiable, Equatable {
    typealias Cell = BinaryCell
    typealias SubState = Self
    
    let id: UUID
    var image: UIImage?
    var name: String
    var array: [Cell]
    var viewport: Rect {
        willSet {
            self.array = resize(self.array, self.viewport, newValue)
        }
    }
    
    init() {
        self.name = ""
        self.image = nil
        self.id = UUID()
        self.viewport = .zero
        self.array = []
    }
    
    public init(name: String, id: UUID, viewport: Rect, array: [Cell]) {
        self.name = name
        self.id = id
        self.viewport = viewport
        self.array = array
    }
    var description: String {
        var result: String = ""
        for y in self.viewport.verticalIndexes {
            for x in self.viewport.horizontalIndexes {
                result += self[Point(x: x, y: y)] == .inactive ? "􀀀" : "􀀁"
                result += "\n"
            }
        }
        if !result.isEmpty {
            result.removeLast()
        }
        return result
    }
    
    public subscript(_ point: Point) -> BinaryCell {
        get {
            if let index = arrayIndex(point, self.viewport) {
                return self.array[index]
            }
            return .inactive
        }
        set {
            guard let index = arrayIndex(point, self.viewport) else {
                return
            }
            
            let newViewport = self.viewport.resizing(toInclude: point)
            self.array = resize(self.array, self.viewport, newViewport)
            self.viewport = newViewport
            
            return self.array[index] = newValue
        }
    }
    public subscript(_ rect: Rect) -> State {
        get {
            guard let start = arrayIndex(rect.origin, self.viewport) else {
                return State()
            }
            var array: [BinaryCell] = []
            for j in 0..<rect.size.height {
                for i in start + j * (self.viewport.size.width)..<(start + rect.size.width) + j * (self.viewport.size.width) {
                    array.append(self.array[i])
                }
            }
            var newState = State()
            newState.viewport = rect
            newState.array = array
            return newState
        }
        set {
            for j in 0..<rect.size.height {
                for i in 0..<min(rect.size.width, newValue.viewport.size.width) {
                    let pos = rect.origin + Point(x: i, y: j)
                    guard let stateInd = arrayIndex(pos, self.viewport) else {
                        return
                    }
                    let newInd = i + j * newValue.viewport.size.width
                    self.array[stateInd] = newValue.array[newInd]
                }
            }
        }
    }
    
    public mutating func translate(to newOrigin: Point) {
        self.viewport = Rect(origin: newOrigin, size: self.viewport.size)
    }
    
    private func arrayIndex(_ point: Point, _ viewport: Rect) -> Int? {
        guard viewport.contains(point: point) else { return nil }
        let newPoint = point - viewport.origin
        return newPoint.x + newPoint.y * viewport.size.width
    }
    
    private func resize(_ array: [Cell], _ oldViewport: Rect, _ newViewport: Rect) -> [Cell] {
        var newArray = Array<Cell> (repeating: .inactive, count: newViewport.area)
        
        for point in oldViewport.indices {
            if let oldArrayIndex = arrayIndex(point, oldViewport),
               let newArrayIndex = arrayIndex(point, newViewport) {
                newArray[newArrayIndex] = array[oldArrayIndex]
            }
        }
        return newArray
    }
    
    func resizeState(_ newViewport: Rect) -> State {
        var newState = State()
        newState.viewport = newViewport
        newState.array = Array<Cell> (repeating: .inactive, count: newViewport.area)
        
        for point in viewport.indices {
            if let oldInd = arrayIndex(point, viewport),
               let newInd = arrayIndex(point, newViewport) {
                newState.array[newInd] = array[oldInd]
            }
        }
        return newState
    }
    
    func toJson() -> Json {
        let height = self.viewport.size.height
        let width = self.viewport.size.width
        let name = self.name
        let newArray = array.map({ $0 == BinaryCell.active ? true : false })
        return Json(id: self.id,
                    createdAt: nil,
                    updatedAt: nil,
                    width: width,
                    height: height,
                    name: name,
                    description: nil,
                    origin: self.viewport.origin,
                    cells: newArray,
                    user: nil)
    }
}
