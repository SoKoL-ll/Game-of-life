import Foundation
import UIKit
import SwiftUI

class StartScreenViewController: UIViewController {
    var hostingController: UIHostingController<StartScreen>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let mainViewController = MainScreenViewController()
        let elementary = { () -> Void in
            self.navigationController?.setViewControllers([mainViewController], animated: true)
            mainViewController.state = mainViewController.resizeState(mainViewController.state)
            mainViewController.setElementaryAutomata(sender: UIAlertAction())
            self.hostingController!.dismiss(animated: true, completion: nil)
        }
        
        let gameOfLife = { () -> Void in
            self.navigationController?.setViewControllers([mainViewController], animated: true)
            mainViewController.state = mainViewController.resizeState(mainViewController.state)
            mainViewController.setGameOfLifeAutomata(sender: UIAlertAction())
            self.hostingController!.dismiss(animated: true, completion: nil)
        }

        let fetchStateFromDiskCompletion = { (automata: JsonForState?) -> Void in
            guard let automata = automata else {
                mainViewController.state = mainViewController.resizeState(mainViewController.state)
                mainViewController.setGameOfLifeAutomata(sender: UIAlertAction())
                return
            }
            if (automata.state.type ?? true) {
                mainViewController.setGameOfLifeAutomata(sender: UIAlertAction())
            } else {
                mainViewController.setElementaryAutomata(sender: UIAlertAction())
                mainViewController.ruleForElementary = automata.code!
            }
            mainViewController.setStatefromSnapshot(from:automata.state.fromJsonToState())
        }
        
        let loadSaveState = { () -> Void in
            mainViewController.cloudStorageManager.fetchStateFromDisk(
                onCompletion: fetchStateFromDiskCompletion
            )
            self.navigationController?.setViewControllers([mainViewController], animated: true)
            self.hostingController!.dismiss(animated: true, completion: nil)
        }
        
        let startScreen = StartScreen(loadSaveState: loadSaveState, elementary: elementary, gameOfLife: gameOfLife)
        
        hostingController = UIHostingController(rootView: startScreen)
        
        hostingController?.modalPresentationStyle = .overFullScreen
        present(hostingController!, animated: true, completion: nil)
    }
}

