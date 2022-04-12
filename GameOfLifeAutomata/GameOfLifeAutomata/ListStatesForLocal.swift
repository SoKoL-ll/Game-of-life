import SwiftUI

struct ListStatesForLocal: View {
    typealias GetFromLocalLibrary = (State) -> Void
    
    let getFromLocalLibrary: GetFromLocalLibrary
    @StateObject var previewStates: PreviewStates
                
    var body: some View {
        List(previewStates.previewStatesArray) { state in
            Image(uiImage: state.image!)
                .resizable()
                .frame(width: CGFloat(state.viewport.size.width) * 50, height: CGFloat(state.viewport.size.height) * 50, alignment: .center)
            .frame(
                width: CGFloat(state.viewport.size.width) * 50,
                height: CGFloat(state.viewport.size.height) * 50
            )
            .onTapGesture {
                getFromLocalLibrary(state)
            }
        }
    }
}
