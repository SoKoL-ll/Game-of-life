import Foundation
import SwiftUI

struct ChooseScreen: View {
    
    let elementary: () -> Void
    let gameOfLife: () -> Void
    var body: some View {
        VStack(alignment: .center, spacing: 70) {
            Button(action: {
               elementary()
            }) {
                Text("Элементарный Автомат")
                    .fontWeight(.bold)
                    .font(.title)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .padding(10)
                    .border(Color.purple, width: 5)
            }
            Button(action: {
               gameOfLife()
            }) {
                Text("Игра в жизнь")
                    .fontWeight(.bold)
                    .font(.title)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .padding(10)
                    .border(Color.purple, width: 5)
            }
        }
    }
}
