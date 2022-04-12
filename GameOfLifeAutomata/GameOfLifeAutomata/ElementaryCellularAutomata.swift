import Foundation

struct ElementaryCellularAutomata: CellularAutomata {
    let rule: UInt8
    var numbOfVert: Int
    public func simulate(_ state: State, generations: UInt) throws -> State {
        var _state = state
        for _ in 0..<generations {
            guard _state.viewport.area != 0 else {
                return state
            }
            _state.viewport = _state.viewport
                .resizing(toInclude: state.viewport.bottomLeft + Point(x: -1, y: 0))
                .resizing(toInclude: state.viewport.bottomRight)
            for x in _state.viewport.horizontalIndexes {
                let prev = _state[Point(x: x - 1, y: numbOfVert)].rawValue
                let now = _state[Point(x: x, y: numbOfVert)].rawValue
                let after = _state[Point(x: x + 1, y: numbOfVert)].rawValue
                _state[Point(x: x, y: numbOfVert + 1)] = BinaryCell(
                    rawValue: self.rule >> (prev << 2 | now << 1 | after << 0) & 1
                    )!
            }
        }
        return _state
    }
    public mutating func setVertAndSimulate(_ state: State, generations: UInt, y: Int) throws -> State {
        self.numbOfVert = y
        return try simulate(state, generations: generations)
    }
    
    public init(rule: UInt8) {
        self.rule = rule
        self.numbOfVert = 0
    }
}
