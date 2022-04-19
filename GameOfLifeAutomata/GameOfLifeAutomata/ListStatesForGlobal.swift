import SwiftUI

struct ListStatesForGlobal: View {
    typealias GetFromGlobalLibrary = (State) -> Void
    
    let getFromGlobalLibrary: GetFromGlobalLibrary
    @StateObject var previewStates: PreviewStates
                
    var body: some View {
        List(previewStates.previewStatesArray) { state in
            Text(state.name)
            .onTapGesture {
                getFromGlobalLibrary(state)
            }
        }
    }
}
