import Foundation
import SwiftUI

struct StartScreen: View {
    
    let chooseType: () -> Void
    let loadSaveState: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 70) {
            Button(action: {
                chooseType()
            }) {
                Text("Начать новую игру")
                    .fontWeight(.bold)
                    .font(.title)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .padding(10)
                    .border(Color.purple, width: 5)
            }
            Button(action: {
                loadSaveState()
            }) {
                Text("Продолжить с последнего сохранения")
                    .fontWeight(.bold)
                    .font(.system(size: 13))
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .padding(10)
                    .border(Color.purple, width: 5)
            }
        }
    }
}
