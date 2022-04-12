import Foundation
import SwiftUI

struct StateForGlobalLibrary: UIViewRepresentable {
    typealias UIViewType = UITextView
    
    var state: State
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.text = state.name
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
    }
}
