import SwiftUI

struct ListStatesForGlobal: View {
    typealias GetFromGlobalLibrary = (State) -> Void
    
    let getFromGlobalLibrary: GetFromGlobalLibrary
    @StateObject var previewStates: PreviewStates
                
    var body: some View {
        List(previewStates.previewStatesArray) { state in
            StateForGlobalLibrary(state: state)
            .frame(
                width: 1000,
                height: 20
            )
            .onTapGesture {
                getFromGlobalLibrary(state)
            }
        }
    }
}
