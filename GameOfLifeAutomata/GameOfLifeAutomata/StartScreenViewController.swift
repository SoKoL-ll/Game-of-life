import Foundation
import UIKit
import SwiftUI

class StartScreenViewController: UIViewController {
    var hostingController: UIHostingController<StartScreen>?
    var secondHostingController: UIHostingController<ChooseScreen>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let mainViewController = MainScreenViewController()
        
        let chooseType = { () -> Void in
            let elementary = { () -> Void in
                self.navigationController?.setViewControllers([mainViewController], animated: true)
                mainViewController.setElementaryAutomata(sender: UIAlertAction())
                self.secondHostingController!.dismiss(animated: true, completion: nil)
            }
            
            let gameOfLife = { () -> Void in
                self.navigationController?.setViewControllers([mainViewController], animated: true)
                mainViewController.setGameOfLifeAutomata(sender: UIAlertAction())
                self.secondHostingController!.dismiss(animated: true, completion: nil)
            }
            self.hostingController!.dismiss(animated: true, completion: nil)
            let chooseScreen = ChooseScreen(elementary: elementary, gameOfLife: gameOfLife)
            self.secondHostingController = UIHostingController(rootView: chooseScreen)
            self.secondHostingController?.modalPresentationStyle = .overFullScreen
            self.present(self.secondHostingController!, animated: true, completion: nil)
        }

        let fetchStateFromDiskCompletion = { (automata: JsonForState?) -> Void in
            guard let automata = automata else {
                mainViewController.setGameOfLifeAutomata(sender: UIAlertAction())
                return
            }
            mainViewController.state = automata.state.fromJsonToState()
            if automata.code == nil {
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
        
        let startScreen = StartScreen(chooseType: chooseType, loadSaveState: loadSaveState)
        hostingController = UIHostingController(rootView: startScreen)
        
        hostingController?.modalPresentationStyle = .overFullScreen
        present(hostingController!, animated: true, completion: nil)
    }
}

