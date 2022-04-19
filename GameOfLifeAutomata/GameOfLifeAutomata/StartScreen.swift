import Foundation
import SwiftUI

struct StartScreen: View {
    
    let loadSaveState: () -> Void
    let elementary: () -> Void
    let gameOfLife: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    List {
                        Text("Элементарный автомат").onTapGesture {
                            elementary()
                        }
                        Text("Игра в жизнь").onTapGesture {
                            gameOfLife()
                        }
                    }
                } label: {
                    Text("Новая игра")
                }
                Text("Продолжить с последнего сохранения").onTapGesture {
                    loadSaveState()
                }
            }
        }
    }
}
