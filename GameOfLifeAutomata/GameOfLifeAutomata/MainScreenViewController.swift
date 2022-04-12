import UIKit
import SwiftUI

class MainScreenViewController: UIViewController, CATiledDataSource, UIScrollViewDelegate {
    var viewport: Rect {self.state.viewport}
    
    
    let cloudStorageManager = CloudStorageManager()
    let networkAccessManager = NetworkAccessManager()
    var globalLibraryPreviewStates = PreviewStates()
    var globalLibraryController: UIHostingController<ListStatesForGlobal>?
    
    var listStateForLocal: ListStatesForLocal?
    var localLibraryController: UIHostingController<ListStatesForLocal>?
    var listStateForGlobal: ListStatesForGlobal?

    
    var nameAutomata: String = "Game of Life"
    var ruleForElementary: UInt8 = 10
    var conditionSimulate = false
    var typeSimulation = true
    var typeOfPoint = true
    var verticalForElementary = 0
    var state = State()
    var stateForPaste = State()
    var playPauseButton: UIBarButtonItem!
    var snapshots: [(UIImage, State)] = []
    var CATiled: CATiledView = CATiledView(frame: .zero)
    let CATiledSize = 100
    var time: Time = .fast
    var CATiledViewWidth: NSLayoutConstraint!
    var CATiledViewHeight: NSLayoutConstraint!
    let scrollView = UIScrollView()
    var buffer = State()
    var pasteView: UIView!
    var angleForPaste = CGFloat(0)
    var angleForSelect = CGFloat(0)
    
    var selectView: UIView!
    var isInserting = false
    var isHighlighting = false
    var initialCenter = CGPoint()
    var finalCenter = CGPoint()
    var pointForStart = CGPoint()
    var rectSize = CGSize()
    var finalTopLeftCorner = CGPoint()
    var previousTouch = CGPoint()
    var moveView: UIView!
    let longTapGestureRecognizer = UILongPressGestureRecognizer(target: nil, action: nil)
    var screensLibrary: ScreensViewController!
    
    var isResizingUL = false
    var isResizingUR = false
    var isResizingDL = false
    var isResizingDR = false
    
    enum Time: UInt32 {
        case fast = 0
        case low = 2
        case balance = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CustomColors.scroll_background_color.color()
        screensLibrary = ScreensViewController()
        createBar()
        createScrollView()
        createCATTiled()
        createConstrate()
        listStateForLocal = ListStatesForLocal(
            getFromLocalLibrary: { (state: State) -> Void in
                self.pasteMode(from: state, screen: UIImageView(image: state.image!))
            },
            previewStates: self.cloudStorageManager.previewStatesWithBarrier.previewStates)
        
        listStateForGlobal = ListStatesForGlobal(
            getFromGlobalLibrary: { (state: State) -> Void in
                self.setStatefromSnapshot(from: state)
            },
            previewStates: self.globalLibraryPreviewStates)
        globalLibraryController = UIHostingController(rootView: listStateForGlobal!)
        globalLibraryController?.title = "Global library"
        
        localLibraryController = UIHostingController(rootView: listStateForLocal!)
        localLibraryController?.title = "Local library"
        
        networkAccessManager.getGlobalLibraryStates(onCompletion: {
            self.globalLibraryPreviewStates.previewStatesArray.append(contentsOf: $0)
        })

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.state = self.resizeState(self.state)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    //MARK: Создание основных элементов управления
    
    /// Создание зоны для симуляций
    func createCATTiled() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.shortTap(_:)))
        self.longTapGestureRecognizer.addTarget(self, action: #selector(self.selectRect(sender:)))
        self.scrollView.addSubview(CATiled)
        self.CATiled.backgroundColor = CustomColors.scroll_background_color.color()
        self.CATiled.translatesAutoresizingMaskIntoConstraints = false
        self.CATiled.tiledLayer.tileSize = CGSize(width: 100, height: 100)
        self.CATiled.addGestureRecognizer(tapGestureRecognizer)
        self.CATiled.addGestureRecognizer(self.longTapGestureRecognizer)
        self.CATiled.dataSource = self
    }
    
    /// создание scroll view
    func createScrollView() {
        self.view.addSubview(scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = 0.01
        self.scrollView.maximumZoomScale = 5.0
        self.scrollView.zoomScale = 0.3
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = CustomColors.scroll_background_color.color()
    }
    
    /// Создание констрейнтов
    func createConstrate() {
        self.CATiledViewWidth = self.CATiled.widthAnchor.constraint(equalToConstant: 1400)
        self.CATiledViewHeight = self.CATiled.heightAnchor.constraint(equalToConstant: 3000)
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            
            self.CATiled.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.CATiled.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
            self.CATiled.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor),
            self.CATiled.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor),
            self.CATiledViewWidth,
            self.CATiledViewHeight
        ])
    }
    
    /// Создание панели навигации и панели инструментов
    func createBar() {
        let snapshot = UIButton()
        snapshot.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.saveSnapshot(sender:)))
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(openScreenVC(sender:)))
        longGesture.minimumPressDuration = 2
        snapshot.addGestureRecognizer(tapGesture)
        snapshot.addGestureRecognizer(longGesture)
        self.navigationItem.title = self.nameAutomata
        self.playPauseButton = UIBarButtonItem(image: UIImage(systemName: "play"), style: .plain, target: self, action: #selector(self.startStopSimulate(sender:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(self.showDropMenu(sender:)))
        self.toolbarItems = [
            UIBarButtonItem(customView: snapshot),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "backward.end.alt"), style: .plain, target: self, action: #selector(self.rollbackToTheLastSnapshot(sender:))),
            playPauseButton,
            UIBarButtonItem(image: UIImage(systemName: "forward.end"), style: .plain, target: self, action: #selector(self.simulateGeneration(sender:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(self.showShapeLibrary(sender:)))
        ]
    }
    
    //MARK: Действия для кнопок
    /// Сохранить снапшот текущего состояния
    @objc func saveSnapshot(sender: UIAlertAction) {
        selectView = UIView(frame: CATiled.bounds)
        CATiled.addSubview(selectView)
        snapshots.append((selectView.takeScreenshot(view: CATiled), self.state))
        selectView.removeFromSuperview()
    }
    
    @objc func openScreenVC(sender: UILongPressGestureRecognizer) {
        self.screensLibrary.data = snapshots
        self.screensLibrary.modalPresentationStyle = .pageSheet
        self.screensLibrary.dataSource = self
        if !(self.navigationController?.viewControllers.contains(screensLibrary) ?? false) {
            self.show(self.screensLibrary, sender: sender)
            self.screensLibrary.table.reloadData()
        }
    }
    
    /// Остановить / запустить симуляцию
    @objc func startStopSimulate(sender: UIBarButtonItem) {
        if conditionSimulate {
            playPauseButton.image = UIImage(systemName: "play")
            conditionSimulate = false
        } else {
            playPauseButton.image = UIImage(systemName: "stop")
            conditionSimulate = true
            self.simulate()
        }
    }
    
    /// Симулировать автомат
    private func simulate() {
        if typeSimulation {
            DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
                let automata = BivariateCellularAutomata(rule: self.ruleForGoL(vicinity:))
                while (self.conditionSimulate) {
                    self.state = try! automata.simulate(self.state, generations: 1)
                    sleep(time.rawValue)
                    DispatchQueue.main.async {
                        self.drawState()
                    }
                }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
                var automata = ElementaryCellularAutomata(rule: self.ruleForElementary)
                while (self.conditionSimulate) {
                    self.state = try! automata.setVertAndSimulate(self.state, generations: 1, y: verticalForElementary)
                    verticalForElementary += 1
                    sleep(time.rawValue)
                    DispatchQueue.main.async {
                        self.drawState()
                    }
                }
            }
        }
    }
    /// Откатить поле до последнего снепшота
    @objc func rollbackToTheLastSnapshot(sender: UIAlertAction) {
        if self.snapshots.count > 0 {
            self.state = self.snapshots.last!.1
            snapshots.removeLast()
            CATiled.setNeedsDisplay()
        }
    }
    
    /// Переход на одно поколение вперед
    @objc func simulateGeneration(sender: UIAlertAction) {
        if (!typeSimulation) {
            var automata = ElementaryCellularAutomata(rule: self.ruleForElementary)
            self.state = try! automata.setVertAndSimulate(self.state, generations: 1, y: verticalForElementary)
            verticalForElementary += 1
            self.drawState()
        } else {
            let automata = BivariateCellularAutomata(rule: self.ruleForGoL(vicinity:))
            self.state = try! automata.simulate(self.state, generations: 1)
            self.drawState()
        }
    }
    
    /// Ввод кода Вольфрама для элементарного автомата
    @objc func enterRule(sender: UIAlertAction) {
        let alertController = UIAlertController(title: "Введите код Вольфрама", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Введите правило"
        })
        alertController.addAction(UIAlertAction(title: "Ввод", style: .default, handler: { [weak alertController] (_) in
            self.ruleForElementary = UInt8(alertController?.textFields![0].text ?? "0") ?? 0
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// Реализация панели навигации
    @objc func showDropMenu(sender: UIBarButtonItem) {
        let menuAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let options = UIAlertAction(title: "Выбрать автомат", style: .default, handler: self.simulationOptions(sender:))
        options.setValue(UIImage(systemName: "gearshape"), forKey: "image")
        menuAlertController.addAction(options)

        let saveOnDisk = UIAlertAction(title: "Сохранить текущее поле на диск", style: .default, handler: saveStateOnDisk(sender:))
        menuAlertController.addAction(saveOnDisk)
        
        let size = UIAlertAction(title: "Изменить размеры поля", style: .default, handler: self.resizeField(sender:))
        size.setValue(UIImage(systemName: "crop"), forKey: "image")
        menuAlertController.addAction(size)
        
        let typePoint = UIAlertAction(title: "Изменить вид ячейки", style: .default, handler: self.replaceTypeOfPoint(sender:))
        if typeOfPoint {
            typePoint.setValue(UIImage(systemName: "square.fill"), forKey: "image")
        } else {
            typePoint.setValue(UIImage(systemName: "circle.fill"), forKey: "image")
        }
        menuAlertController.addAction(typePoint)
        let speed = UIAlertAction(title: "Изменить скорость рисования", style: .default, handler: self.chooseSpeed(sender:))
        speed.setValue(UIImage(systemName: "stopwatch"), forKey: "image")
        menuAlertController.addAction(speed)
        
        if (!typeSimulation) {
            let setRule = UIAlertAction(title: "Ввести правило для симуляции", style: .default, handler: self.enterRule(sender:))
            setRule.setValue(UIImage(systemName: "info.circle"), forKey: "image")
            menuAlertController.addAction(setRule)
        }
        
        let clear = UIAlertAction(title: "Очистить поле", style: .destructive, handler: self.alertForClear(sender:))
        clear.setValue(UIImage(systemName: "xmark.octagon"), forKey: "image")
        menuAlertController.addAction(clear)
        
        let cancel = UIAlertAction(title: "Отменить", style: .cancel, handler: nil)
        menuAlertController.addAction(cancel)
        self.present(menuAlertController, animated: true, completion: nil)
    }
    
    /// меню для библиотеки фигур
    @objc func showDropMenuForLibrary(sender: UIBarButtonItem) {
        let menuAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let saveToDisk = UIAlertAction(title: "Сохранить на диск", style: .default) { _ in
            self.cloudStorageManager.savePreviewsOnDisk()
        }
        menuAlertController.addAction(saveToDisk)
        
        let fetchFromDisk = UIAlertAction(title: "Выгрузить с диска", style: .default) { _ in
            self.cloudStorageManager.fetchPreviewsFromDisk()
        }
        menuAlertController.addAction(fetchFromDisk)
        
        let openGlobalLibrary = UIAlertAction(title: "Глобальная библиотека", style: .default) { _ in
            guard let globalLibraryController = self.globalLibraryController else {
                return
            }
            self.navigationController?.pushViewController(globalLibraryController, animated: true)
        }
        menuAlertController.addAction(openGlobalLibrary)
        
        let cancel = UIAlertAction(title: "Отменить", style: .cancel, handler: nil)
        menuAlertController.addAction(cancel)
        self.present(menuAlertController, animated: true, completion: nil)
    }
    
    /// Сохранить состояние на диск
    @objc func saveStateOnDisk(sender: UIAlertAction) {
        self.cloudStorageManager.saveStateOnDisk(
            state: self.state,
            code: self.ruleForElementary)
    }
    
    /// Изменить тип клеток
    @objc func replaceTypeOfPoint(sender: UIAlertAction) {
        typeOfPoint = !typeOfPoint
        drawState()
        CATiled.setNeedsDisplay()
    }
    
    /// выбор скорости
    @objc func chooseSpeed(sender: UIAlertAction) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let fast = UIAlertAction(title: "Быстро", style: .default, handler: self.setFast(sender:))
        fast.setValue(UIImage(systemName: "hare.fill"), forKey: "image")
        alertController.addAction(fast)

        let low = UIAlertAction(title: "Медленно", style: .default, handler: self.setLow(sender:))
        low.setValue(UIImage(systemName: "tortoise.fill"), forKey: "image")
        alertController.addAction(low)
        
        let balance = UIAlertAction(title: "Сбалансированно", style: .default, handler: self.setBalane(sender:))
        balance.setValue(UIImage(systemName: "speedometer"), forKey: "image")
        alertController.addAction(balance)
        
        let cancel = UIAlertAction(title: "Отменить", style: .cancel, handler: nil)
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// Низкая скорость
    @objc func setLow(sender: UIAlertAction) {
        self.time = .low
    }
    
    /// Быстрая скорость
    @objc func setFast(sender: UIAlertAction) {
        self.time = .fast
    }
    
    /// Средняя скорость
    @objc func setBalane(sender: UIAlertAction) {
        self.time = .balance
    }
    
    /// Активация и деактивация элемента при нажатии
    @objc func shortTap(_ sender: UITapGestureRecognizer? = nil) {
        if (!self.conditionSimulate) {
            let point = sender?.location(in: CATiled)
            let x = Int(Int(point!.x) / self.CATiledSize)
            let y = Int(Int(point!.y) / self.CATiledSize)
            let automataPoint = Point(x: x, y: y)
            state[automataPoint] = (state[automataPoint] == .active) ? .inactive : .active
            CATiled.setNeedsDisplay(CGRect(origin: CGPoint(x: Int(automataPoint.x * self.CATiledSize), y: Int(automataPoint.y * self.CATiledSize)),
                                             size: CGSize(width: self.CATiledSize, height: self.CATiledSize)))
        }
    }
    
    //Активировать поле для выбора зоны
    @objc func selectRect(sender: UILongPressGestureRecognizer) {
        self.isHighlighting = true
        angleForSelect = 0
        if (sender.state == .began) {
            let point = sender.location(in: self.CATiled)
            let x = max(0, Int(point.x - 150))
            let y = max(0, Int(point.y - 150))
            
            self.selectView = UIView(frame: CGRect(x: x, y: y, width: 200, height: 200))
            self.selectView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.4)
            self.selectView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.26).cgColor
            self.selectView.layer.borderWidth = 4
            self.selectView.translatesAutoresizingMaskIntoConstraints = false
            
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.resizeSelectView(sender:)))
            self.selectView.addGestureRecognizer(panGestureRecognizer)
            self.CATiled.addSubview(self.selectView)
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.setDone(sender:)))
            
            self.toolbarItems = [
                UIBarButtonItem.flexibleSpace(),
                UIBarButtonItem(image: UIImage(systemName: "rotate.left"), style: .plain, target: self, action: #selector(self.rotateLeftSelect(sender:))),
                UIBarButtonItem(image: UIImage(systemName: "rotate.right"), style: .plain, target: self, action: #selector(self.rotateRightSelect(sender:))),
                UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down.on.square"), style: .plain, target: self, action: #selector(self.saveSelectRect(sender:))),
                UIBarButtonItem(image: UIImage(systemName: "doc.on.clipboard"), style: .plain, target: self, action: #selector(self.copySelect(sender:))),
                UIBarButtonItem(image: UIImage(systemName: "arrow.down.doc"), style: .plain, target: self, action: #selector(self.pasteSelected(sender:))),
                UIBarButtonItem(image: UIImage(systemName: "cursorarrow.and.square.on.square.dashed"), style: .plain, target: self, action: #selector(self.cutSelect(sender:))),
                UIBarButtonItem(image: UIImage(systemName: "square.slash"), style: .plain, target: self, action: #selector(self.clearSelectRect(sender:))),
                UIBarButtonItem.flexibleSpace()
            ]
        }
        sender.isEnabled = false
    }
    
    /// Поворот вью выделения против часовой
    @objc func rotateLeftSelect(sender: UIBarButtonItem) {
        angleForSelect -= .pi / 2
        selectView.transform = CGAffineTransform(rotationAngle: angleForSelect)
        rectSize = selectView.frame.size
        setSelectViewToPoints()
    }
    
    /// Поворот вью выделения по часовой
    @objc func rotateRightSelect(sender: UIBarButtonItem) {
        angleForSelect += .pi / 2
        self.selectView.transform = CGAffineTransform(rotationAngle: angleForSelect)
        rectSize = selectView.frame.size
        setSelectViewToPoints()
    }
    /// копировать в буфер обмена
    @objc func copySelect(sender: UIBarButtonItem) {
        let screenshot = self.selectView.takeScreenshot(view: self.CATiled)
        let origin = Point(x: Int(self.selectView.frame.origin.x / 100), y: Int(self.selectView.frame.origin.y / 100))
        let size = Size(width: Int(self.selectView.frame.size.width / 100), height: Int(self.selectView.frame.size.height / 100))
        let rect = Rect(origin: origin, size: size)
        self.buffer.viewport = rect
        self.buffer[Rect(origin: origin, size: size)] = self.state[Rect(origin: origin, size: size)]
        self.buffer.image = screenshot
        
    }
    
    /// вставить из буфера обмена
    @objc func pasteSelected(sender: UIBarButtonItem) {
        selectView.removeFromSuperview()
        pasteMode(from: buffer, screen: UIImageView(image: buffer.image!))
    }
    
    /// вырезать фигуру
    @objc func cutSelect(sender: UIBarButtonItem) {
        let screenshot = self.selectView.takeScreenshot(view: self.CATiled)
        let origin = self.selectView.frame.origin
        let size = self.selectView.frame.size
        let xStart = Int(origin.x / 100)
        let yStart = Int(origin.y / 100)
        
        let state = self.state[Rect(origin: Point(x: xStart, y: yStart), size: Size(width: Int(size.width / 100), height: Int(size.height / 100)))]
        
        var emptyState = State()
        emptyState = self.resizeState(emptyState)
        emptyState[Point(x: xStart, y: yStart)] = .inactive
        self.state[Rect(origin: Point(x: xStart, y: yStart), size: Size(width: Int(size.width / 100), height: Int(size.height / 100)))] = emptyState
        
        self.selectView.removeFromSuperview()
        drawState()
        CATiled.setNeedsDisplay()
        self.pasteMode(from: state, screen: UIImageView(image: screenshot))
    }
    
    /// Сохранить выбранную фигуру
    @objc func saveSelectRect(sender: UIBarButtonItem) {
        let screenshot = self.selectView.takeScreenshot(view: self.CATiled)
        let origin = self.selectView.frame.origin
        let size = self.selectView.frame.size
        let xStart = Int(origin.x / 100)
        let yStart = Int(origin.y / 100)
        cloudStorageManager.previewStatesInitialOrigins.append(Point(x: xStart, y: yStart))
        var state = self.state[Rect(origin: Point(x: xStart, y: yStart), size: Size(width: Int(size.width / 100), height: Int(size.height / 100)))]
        state.image = screenshot
        cloudStorageManager.previewStatesWithBarrier.append(state)
        createBar()
        self.selectView.removeFromSuperview()
        self.longTapGestureRecognizer.isEnabled = true
    }
    
    /// Показать библиотеку с фигурами
    @objc func showShapeLibrary(sender: UIBarButtonItem) {
        localLibraryController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(self.showDropMenuForLibrary(sender:)))
        localLibraryController?.modalPresentationStyle = .overFullScreen
        navigationController?.pushViewController(localLibraryController!, animated: true)
    }
    
    /// Убрать зону для выбора зоны
    @objc func desableSelectRect(sender: UIBarButtonItem) {
        self.createBar()
        self.CATiled.gestureRecognizers?[1].isEnabled = true
        if (self.isInserting) {
            self.moveView.removeFromSuperview()
            self.isInserting = false
        } else if (self.isHighlighting) {
            self.selectView.removeFromSuperview()
            self.isHighlighting = false
        }
        self.isResizingDL = false
        self.isResizingDR = false
    }
    
    /// Изменить только активные точки
    @objc func setOnlyActive(sender: UIBarButtonItem) {
        let origin = Point(x: Int(self.selectView.frame.origin.x / 100), y: Int(self.selectView.frame.origin.y / 100))
        let size = Size(width: Int(self.selectView.frame.size.width / 100), height: Int(self.selectView.frame.size.height / 100))
        for y in 0..<size.height {
            for x in 0..<size.width {
                let point = self.stateForPaste[self.stateForPaste.viewport.origin + Point(x: x, y: y)]
                if (point == .active) {
                    self.state[origin + Point(x: x, y: y)] = point                }
            }
        }
        createBar()
        self.selectView.removeFromSuperview()
        self.longTapGestureRecognizer.isEnabled = true
        self.drawState()
        self.CATiled.setNeedsDisplay()
    }
    
    /// Повернуть вью для вставки против часовой
    @objc func rotatePasteLeft(sender: UIBarButtonItem) {
        angleForPaste -= .pi / 2
        self.selectView.transform = CGAffineTransform(rotationAngle: angleForPaste)
        rectSize = selectView.frame.size
        self.stateForPaste = self.rotateState(self.stateForPaste, false)
        setSelectViewToPoints()
    }
    /// Повернуть вью для вставки по  часовой
    @objc func rotatePasteRight(sender: UIBarButtonItem) {
        angleForPaste += .pi / 2
        self.selectView.transform = CGAffineTransform(rotationAngle: angleForPaste)
        rectSize = selectView.frame.size
        self.stateForPaste = self.rotateState(self.stateForPaste, true)
        setSelectViewToPoints()
    }
    
    /// Заменить область полностью
    @objc func setFullReplase(sender: UIBarButtonItem) {
        let origin = Point(x: Int(self.selectView.frame.origin.x / 100), y: Int(self.selectView.frame.origin.y / 100))
        let size = Size(width: Int(self.selectView.frame.size.width / 100), height: Int(self.selectView.frame.size.height / 100))
        self.state[Rect(origin: origin, size: size)] = self.stateForPaste
        createBar()
        self.selectView.removeFromSuperview()
        self.longTapGestureRecognizer.isEnabled = true
        self.drawState()
        self.CATiled.setNeedsDisplay()
    }
    
    /// Очистить выбранную зону
    @objc func clearSelectRect(sender: UIBarButtonItem) {
        let origin = Point(x: Int(self.selectView.frame.origin.x / 100), y: Int(self.selectView.frame.origin.y / 100))
        let size = Size(width: Int(self.selectView.frame.size.width / 100), height: Int(self.selectView.frame.size.height / 100))
        var emptyState = State()
        emptyState = self.resizeState(emptyState)
        emptyState[Point(x: origin.x + size.width - 1, y: origin.y + size.height - 1)] = .inactive
        self.state[Rect(origin: origin, size: size)] = emptyState
        self.drawState()
        createBar()
        self.selectView.removeFromSuperview()
        self.longTapGestureRecognizer.isEnabled = true
    }
    
    /// Завершить операцию
    @objc func setDone(sender: UIBarButtonItem) {
        self.drawState()
        createBar()
        self.selectView.removeFromSuperview()
        self.longTapGestureRecognizer.isEnabled = true
    }
    /// Изменить размер поля для выбора зоны
    @objc func resizeSelectView(sender: UIPanGestureRecognizer) {
        let point = sender.location(in: self.CATiled)
        let translation = sender.translation(in: self.CATiled)
        if (sender.state == .began) {
            self.initialCenter = self.selectView.center
            self.pointForStart = point
            self.rectSize = self.selectView.frame.size
        }
        
        if (sender.state != .ended) {
            checkResizing()
            let change = CGPoint(x: self.previousTouch.x - point.x, y: self.previousTouch.y - point.y)

            if (isResizingUL) {
                self.selectView.frame = CGRect(x: self.selectView.frame.minX - change.x,
                                               y: self.selectView.frame.minY - change.y,
                                               width: self.selectView.frame.size.width + change.x,
                                               height: self.selectView.frame.size.height + change.y)
                self.rectSize = self.selectView.frame.size
                self.finalTopLeftCorner = self.selectView.frame.origin
            } else if (isResizingUR) {
                self.selectView.frame = CGRect(x: self.selectView.frame.minX,
                                               y: self.selectView.frame.minY - change.y,
                                               width: self.selectView.frame.size.width - change.x,
                                               height: self.selectView.frame.size.height + change.y)
                self.rectSize = self.selectView.frame.size
            } else if (isResizingDL) {
                self.selectView.frame = CGRect(x: self.selectView.frame.minX - change.x,
                                               y: self.selectView.frame.minY,
                                               width: self.selectView.frame.size.width + change.x,
                                               height: self.selectView.frame.size.height - change.y)
                self.rectSize = self.selectView.frame.size
            } else if (isResizingDR) {
                self.selectView.frame = CGRect(x: self.selectView.frame.minX,
                                               y: self.selectView.frame.minY,
                                               width: self.selectView.frame.size.width - change.x,
                                               height: self.selectView.frame.size.height - change.y)
                self.rectSize = self.selectView.frame.size
            } else {
                let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
                self.finalCenter = newCenter
                self.selectView.center = newCenter
            }
            previousTouch = point
        }
        
        if (sender.state == .ended) {
            self.setSelectViewToPoints()

            self.isResizingUL = false
            self.isResizingUR = false
            self.isResizingDL = false
            self.isResizingDR = false
        }
    }
    
    /// Проставить вью выделения по точкам
    func setSelectViewToPoints() {
        var size = self.rectSize
        size.width = max(100, CGFloat(lroundf(Float(size.width) / 100) * 100))
        size.height = max(100, CGFloat(lroundf(Float(size.height) / 100) * 100))
        self.selectView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        var x = lroundf(Float(self.finalCenter.x / 100)) * 100
        var y = lroundf(Float(self.finalCenter.y / 100)) * 100
        
        if (Int(self.selectView.frame.size.width / 100) % 2 != 0) {
            x += 50
        }
        if (Int(self.selectView.frame.size.height / 100) % 2 != 0) {
            y += 50
        }
        self.selectView.center = CGPoint(x: x, y: y)
        self.finalCenter = self.selectView.center
    }
    
    //MARK: Вспомогательные функции
    /// Перевод режима в игру в жизнь
    func setGameOfLifeAutomata(sender: UIAlertAction) {
        self.nameAutomata = "Game of Life"
        self.navigationItem.title = self.nameAutomata
        typeSimulation = true
    }
    
    /// Правило для игры в жизнь
    func ruleForGoL(vicinity: State) -> BinaryCell {
        var cnt: Int = 0
        let cell: BinaryCell = vicinity.array[4]
        for i in 0..<vicinity.array.count {
            if vicinity.array[i] == .active {
                cnt += 1
            }
        }
        if cell == .active {
            cnt -= 1
        }
        
        if cnt == 3 && cell == .inactive {
            return .active
        } else if (cnt == 2 || cnt == 3) && cell == .active {
            return .active
        } else {
            return .inactive
        }
    }
    
    /// Перевод режима в элементарный автомат
    func setElementaryAutomata(sender: UIAlertAction) {
        self.nameAutomata = "Elementary Automata"
        self.navigationItem.title = self.nameAutomata
        typeSimulation = false
    }
    
    /// Проверка изменения selectView
    func checkResizing() {
        let topLeftCorner = CGPoint(x: self.selectView.center.x - self.rectSize.width / 2, y: self.selectView.center.y - self.rectSize.height / 2)
        let topRightCorner = CGPoint(x: self.selectView.center.x + self.rectSize.width / 2, y: self.selectView.center.y - self.rectSize.height / 2)
        let bottomLeftCorner = CGPoint(x: self.selectView.center.x - self.rectSize.width / 2, y: self.selectView.center.y + self.rectSize.height / 2)
        let bottomRightCorner = CGPoint(x: self.selectView.center.x + self.rectSize.width / 2, y: self.selectView.center.y + self.rectSize.height / 2)
        
        if (self.pointForStart.x <= topLeftCorner.x + 15 && self.pointForStart.x >= topLeftCorner.x &&
            self.pointForStart.y <= topLeftCorner.y + 15 && self.pointForStart.y >= topLeftCorner.y) {
            self.isResizingUL = true
        } else if (self.pointForStart.x >= topRightCorner.x - 15 && self.pointForStart.x <= topRightCorner.x &&
                   self.pointForStart.y <= topRightCorner.y + 15 && self.pointForStart.y >= topRightCorner.y) {
            self.isResizingUR = true
        } else if (self.pointForStart.x <= bottomLeftCorner.x + 15 && self.pointForStart.x >= bottomLeftCorner.x &&
                   self.pointForStart.y >= bottomLeftCorner.y - 15 && self.pointForStart.y <= bottomLeftCorner.y) {
            self.isResizingDL = true
        } else if (self.pointForStart.x >= bottomRightCorner.x - 15 && self.pointForStart.x <= bottomRightCorner.x &&
                   self.pointForStart.y >= bottomRightCorner.y - 15 && self.pointForStart.y <= bottomRightCorner.y) {
            self.isResizingDR = true
        }
    }
    
    /// Выбор режима симуляции
    func simulationOptions(sender: UIAlertAction) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let elementaryAutomata = UIAlertAction(title: "Элементарный автомат", style: .default, handler: self.setElementaryAutomata(sender:))
        alertController.addAction(elementaryAutomata)

        let gameLife = UIAlertAction(title: "Игра в жизнь", style: .default, handler: self.setGameOfLifeAutomata(sender:))
        alertController.addAction(gameLife)
        
        let cancel = UIAlertAction(title: "Отменить", style: .cancel, handler: nil)
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// Изменить размер поля симуляции
    func resizeField(sender: UIAlertAction) {
        let alertViewController = UIAlertController(title: "Введите новые размеры поля", message: nil, preferredStyle: .alert)
        
        alertViewController.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Ширина"
        })
        alertViewController.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Высота"
        })
        alertViewController.addAction(UIAlertAction(title: "Ввод", style: .default, handler: { [unowned alertViewController] (_) in
            let width = Int(alertViewController.textFields![0].text ?? "0") ?? 0
            let height = Int(alertViewController.textFields![1].text ?? "0") ?? 0
            self.state = self.state.resizeState(Rect(origin: Point(x: 0, y: 0), size: Size(width: width, height: height)))
            self.CATiledViewWidth.constant = CGFloat(width * self.CATiledSize)
            self.CATiledViewHeight.constant = CGFloat(height * self.CATiledSize)
            self.CATiled.setNeedsDisplay()
        }))
        
        self.present(alertViewController, animated: true, completion: nil)
    }

    /// Очистить поле
    func clearState(sender: UIAlertAction) {
        let width = self.state.viewport.size.width
        let height = self.state.viewport.size.height
        self.state = State()
        self.state.viewport = Rect(origin: Point(x: 0, y: 0), size: Size(width: width, height: height))
        self.CATiledViewWidth.constant = CGFloat(width * 100)
        self.CATiledViewHeight.constant = CGFloat(height * 100)
        self.verticalForElementary = 0
        self.CATiled.setNeedsDisplay()
    }

    /// Подтверждение очистки поля
    func alertForClear(sender: UIAlertAction) {
        let clearAlert = UIAlertController(title: "Вы уверены?", message: nil, preferredStyle: .alert)
        
        clearAlert.addAction(UIAlertAction(title: "Да", style: .destructive, handler: clearState(sender:)))
        clearAlert.addAction(UIAlertAction(title: "Нет", style: .default, handler: nil))
        
        self.present(clearAlert, animated: true, completion: nil)
    }
    
    /// Проставить дефолтный размер для поля
    func resizeState(_ state: State) -> State {
        var stateResult = state
        stateResult.viewport = Rect(origin: Point(x: 0, y: 0), size: Size(width: 14, height: 30))
        self.verticalForElementary = 0
        return stateResult
    }
    
    /// Прорисовка поля симуляции
    func drawState() {
        for x in self.state.viewport.verticalIndexes {
            for y in self.state.viewport.horizontalIndexes {
                let rect = CGRect(x: x * self.CATiledSize, y: y * self.CATiledSize, width: self.CATiledSize, height: self.CATiledSize)
                self.CATiled.setNeedsDisplay(rect)
            }
        }
    }
    
    /// Поворот State
    func rotateState(_ state: State, _ flag: Bool) -> State {
        var newState = State()
        newState.viewport = Rect(origin: Point(x: state.viewport.origin.x, y: state.viewport.origin.y), size: Size(width: state.viewport.size.height, height: state.viewport.size.width))
        for x in 0..<state.viewport.size.width {
            for y in 0..<state.viewport.size.height {
                newState[newState.viewport.origin + Point(x: y, y: x)] = state[state.viewport.origin + Point(x: x, y: y)]
            }
        }
        if (flag) {
            for y in newState.viewport.verticalIndexes {
                var left = newState.viewport.origin.x
                var right = newState.viewport.size.width + newState.viewport.origin.x - 1
                while (left < right) {
                    let point = newState[Point(x: left, y: y)]
                    newState[Point(x: left, y: y)] = newState[Point(x: right, y: y)]
                    newState[Point(x: right, y: y)] = point
                    left += 1
                    right -= 1
                }
            }
        } else {
            for x in newState.viewport.horizontalIndexes {
                var left = newState.viewport.origin.y
                var right = newState.viewport.size.height + newState.viewport.origin.y - 1
                while (left < right) {
                    let point = newState[Point(x: x, y: left)]
                    newState[Point(x: x, y: left)] = newState[Point(x: x, y: right)]
                    newState[Point(x: x, y: right)] = point
                    left += 1
                    right -= 1
                }
            }
        }
        return newState
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        CATiled
    }
    
    //MARK: CATiledDataSource function implementation
    func getCell(at point: Point) -> Bool {
        return self.state[point] == .active
    }
    
    @objc func changePlace(sender: UIPanGestureRecognizer) {
        let point = sender.location(in: self.CATiled)
        let translation = sender.translation(in: self.CATiled)
        if (sender.state == .began) {
            self.initialCenter = self.selectView.center
            self.pointForStart = point
            self.rectSize = self.selectView.frame.size
        }
        
        if (sender.state != .ended) {
            let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
            self.finalCenter = newCenter
            self.selectView.center = newCenter
            previousTouch = point
        }
    
        if (sender.state == .ended) {
            self.setSelectViewToPoints()
        }
    }
    
    /// Режим вставки
    func pasteMode(from state: State, screen image: UIImageView) {
        self.navigationController?.popToViewController(self, animated: true)
        self.drawState()
        angleForPaste = 0
        self.stateForPaste = state
        self.selectView = image
        self.selectView.frame = CGRect(x: state.viewport.origin.x, y: state.viewport.origin.y, width: state.viewport.size.width * 100, height: state.viewport.size.height * 100)
        self.selectView.alpha = 0.5
        self.selectView.layer.borderColor = UIColor.black.withAlphaComponent(0.8).cgColor
        self.selectView.layer.borderWidth = 5
        self.selectView.isUserInteractionEnabled = true
        self.CATiled.addSubview(self.selectView)
        self.CATiled.setNeedsLayout()
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(changePlace(sender:)))
        self.selectView.addGestureRecognizer(panGestureRecognizer)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.setDone(sender:)))
        
        self.toolbarItems = [
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "rotate.left"), style: .plain, target: self, action: #selector(self.rotatePasteLeft(sender:))),
            UIBarButtonItem(image: UIImage(systemName: "rotate.right"), style: .plain, target: self, action: #selector(self.rotatePasteRight(sender:))),
            UIBarButtonItem(image: UIImage(systemName: "equal.square"), style: .plain, target: self, action: #selector(self.setFullReplase(sender:))),
            UIBarButtonItem(image: UIImage(systemName: "plus.square"), style: .plain, target: self, action: #selector(self.setOnlyActive(sender:))),
            UIBarButtonItem.flexibleSpace()
        ]
    }
    
    /// Выбрать состояние поля из снапшота
    func setStatefromSnapshot(from state: State) {
        self.state = state
        drawState()
        self.navigationController?.popToViewController(self, animated: true)
    }
    
    /// Удалить снапшот
    func deleteSnapshot(at ind: Int) {
        snapshots.remove(at: ind)
    }
    
    /// Получить тип точки
    func getTypeOfPoint() -> Bool {
        return typeOfPoint
    }
}

extension UIView {
    
    /// Скриншот вырбанного состояния для библиотеки
    func takeScreenshot(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, self.window?.screen.scale ?? 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: -self.frame.minX, y: -self.frame.minY)
        let origin = Point(x: Int(self.frame.minX / 100), y: Int(self.frame.minY / 100))
        let size = Size(width: Int(self.frame.width / 100), height: Int(self.frame.height / 100))
        drawSubstate(origin: origin, size: size, view: view)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        context.translateBy(x: self.frame.minX, y: self.frame.minY)
        UIGraphicsEndImageContext()

        return image ?? UIImage()
    }
    
    func drawSubstate(origin: Point, size: Size, view: UIView) {
        for x in origin.x..<(origin.x + size.width) {
            for y in origin.y..<(origin.y + size.height) {
                view.draw(CGRect(x: x * 100, y: y * 100, width: 100, height: 100))
            }
        }
    }
}
