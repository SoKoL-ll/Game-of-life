import Foundation
import UIKit

enum CustomColors: String {
    case cell_background_color
    case point_active_color
    case point_inactive_color
    case scroll_background_color
    case table_background_color
    
    func color() -> UIColor {
        UIColor(named: self.rawValue)!
    }
}
