import Foundation
import UIKit

class CATiledView: UIView {
    public weak var dataSource: CATiledDataSource?
    
    override class var layerClass: AnyClass { CATiledLayer.self }
    
    var tiledLayer: CATiledLayer { layer as! CATiledLayer }
    
    override var contentScaleFactor: CGFloat {
        didSet { super.contentScaleFactor = 1 }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.setFillColor(CustomColors.scroll_background_color.color().cgColor)
        context.fill(rect)
        
        if (dataSource?.getCell(at: Point(x: Int(rect.minX / 100), y: Int(rect.minY / 100))) ?? false) {
            context.setFillColor(CustomColors.point_active_color.color().cgColor)
        } else {
            context.setFillColor(CustomColors.point_inactive_color.color().cgColor)
            
        }
        
        if (dataSource?.getTypeOfPoint() ?? false) {
            context.fillEllipse(in: rect.inset(by: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)))
        } else {
            context.fill(rect)
            context.stroke(rect)
        }
    }
}
