import Foundation

struct BivariateCellularAutomata: CellularAutomata {
    typealias Cell = BinaryCell
    
    let rule: (State) -> BinaryCell
    
    func simulate(_ state: State, generations: UInt) throws -> State {
        var state = state
        
        var topActive = state.viewport.center
        var leftActive = state.viewport.center
        var rightActive = state.viewport.center
        var bottomActive = state.viewport.center
        
        for _ in 0..<generations {
            
            var newState = state
            
            if (newState.viewport.origin.y == topActive.y) {
                newState.viewport = newState.viewport.resizing(toInclude: newState.viewport.origin - Point(x: 0, y: 1))
            }
            if (newState.viewport.origin.x == leftActive.x) {
                newState.viewport = newState.viewport.resizing(toInclude: newState.viewport.origin - Point(x: 1, y: 0))
            }
            if (newState.viewport.bottomRight.y == bottomActive.y) {
                newState.viewport = newState.viewport.resizing(toInclude: newState.viewport.bottomRight + Point(x: 0, y: 1))
            }
            if (newState.viewport.bottomRight.x == rightActive.x) {
                newState.viewport = newState.viewport.resizing(toInclude: newState.viewport.bottomRight + Point(x: 1, y: 0))
            }
            
            let cellToCheck = [((-1, 0), (0, -1), leftButtom(state), (1, 1)),
                             ((1, 0), (0, -1), rightButtom(state), (0, 1)),
                             ((-1, 0), (0, 1), leftTop(state), (1, 0)),
                             ((1, 0), (0, 1), rightTop(state), (0, 0)),
                             ((-1, 0), nil, left(state, 0, -1), (1, 0)),
                             ((1, 0), nil, right(state, -1, -1), nil),
                             ((0, -1), nil, buttom(state, -1, 0), (0, 1)),
                             ((0, 1), nil, top(state, -1, -1), nil)]
            
            for x in state.viewport.horizontalIndexes {
                for y in state.viewport.verticalIndexes {
                    var vicinity = State()
                    vicinity.viewport = Rect(origin: .zero, size: Size(width: 3, height: 3))
                    vicinity[.zero] = .inactive
                    vicinity[Point(x: 2, y: 2)] = .inactive
                    
                    if (state.viewport.origin.x < x && state.viewport.origin.y < y && state.viewport.bottomRight.x - 1 > x && state.viewport.bottomRight.y - 1 > y) {
                        vicinity = state[Rect(origin: Point(x: x - 1, y: y - 1), size: Size(width: 3, height: 3))]
                    } else {
                        for el in cellToCheck {
                            if el.1 != nil {
                                if (!state.viewport.contains(point: Point(x: x + el.0.0, y: y + el.0.1)) && !state.viewport.contains(point: Point(x: x + el.1!.0, y: y + el.1!.1))) {
                                    vicinity[Rect(origin: Point(x: el.3!.0, y: el.3!.1), size: Size(width: 2, height: 2))] = el.2
                                }
                            } else if el.0.1 == 0 {
                                if (!state.viewport.contains(point: Point(x: x + el.0.0, y: y))) {
                                    vicinity[Rect(origin: el.3 == nil ? .zero : Point(x: el.3!.0, y: el.3!.1), size: Size(width: 2, height: 3))] = el.2
                                }
                            } else {
                                if (!state.viewport.contains(point: Point(x: x, y: y + el.0.1))) {
                                    vicinity[Rect(origin: el.3 == nil ? .zero : Point(x: el.3!.0, y: el.3!.1), size: Size(width: 3, height: 2))] = el.2
                                }
                            }
                        }
                    }
                    
                    newState[Point(x: x, y: y)] = rule(vicinity)
                    if (newState[Point(x: x, y: y)] == .active) {
                        if (topActive.y > y) {
                            topActive = Point(x: x, y: y)
                        }
                        if (leftActive.x > x) {
                            leftActive = Point(x: x, y: y)
                        }
                        if (rightActive.x < x) {
                            rightActive = Point(x: x, y: y)
                        }
                        if (bottomActive.y < y) {
                            bottomActive = Point(x: x, y: y)
                        }
                    }
                }
            }
            
            state = newState
        }
        
        return state
    }
    
    init(rule: @escaping (State) -> BinaryCell) {
        self.rule = rule
    }
    
    func leftButtom(_ state: State, _ x: Int? = nil, _ y: Int? = nil) -> State {
        state[Rect(origin: state.viewport.origin, size: Size(width: 2, height: 2))]
    }
    
    func rightButtom(_ state: State, _ x: Int? = nil, _ y: Int? = nil) -> State {
        state[Rect(origin: state.viewport.topRight - Point(x: 1, y: 0), size: Size(width: 2, height: 2))]
    }
    
    func leftTop(_ state: State, _ x: Int? = nil, _ y: Int? = nil) -> State {
        state[Rect(origin: state.viewport.bottomLeft - Point(x: 0, y: 2), size: Size(width: 2, height: 2))]
    }
    
    func rightTop(_ state: State, _ x: Int? = nil, _ y: Int? = nil) -> State {
        state[Rect(origin: state.viewport.bottomRight - Point(x: 2, y: 2), size: Size(width: 2, height: 2))]
    }
    
    func left(_ state: State, _ x: Int? = nil, _ y: Int? = nil) -> State {
        state[Rect(origin: Point(x: x!, y: y! - 1), size: Size(width: 2, height: 3))]
    }
    
    func right(_ state: State, _ x: Int? = nil, _ y: Int? = nil) -> State {
        state[Rect(origin: Point(x: x! - 1, y: y! - 1), size: Size(width: 2, height: 3))]
    }
    
    func buttom(_ state: State, _ x: Int? = nil, _ y: Int? = nil) -> State {
        state[Rect(origin: Point(x: x! - 1, y: y!), size: Size(width: 3, height: 2))]
    }
    
    func top(_ state: State, _ x: Int? = nil, _ y: Int? = nil) -> State {
        state[Rect(origin: Point(x: x! - 1, y: y! - 1), size: Size(width: 3, height: 2))]
    }
}
