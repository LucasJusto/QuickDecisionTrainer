import Foundation
import SpriteKit
import SwiftUI
import Combine

class ZBlock: SKSpriteNode {
    let z: Int
    var categoryBitMask: UInt32 = 0x1 << 0
    
    init(z: Int) {
        self.z = z
        super.init(texture: nil, color: #colorLiteral(red: 0.9450980392, green: 0.5450980392, blue: 0.1725490196, alpha: 1), size: CGSize(width: 50, height: 50))
        let labelNode = SKLabelNode(text: "\(z)")
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        self.addChild(labelNode)
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody?.collisionBitMask = 0x1 << 0
        self.physicsBody?.categoryBitMask = self.categoryBitMask
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class Player: SKSpriteNode {
    var x: CGFloat
    var y: CGFloat
    var categoryBitMask: UInt32 = 0x1 << 1
    
    public init() {
        x = (550/2)//center of the screen (550 width).
        y = 50
        super.init(texture: .none, color: .black, size: CGSize(width: 35, height: 5))
        self.position = CGPoint(x: x, y: y)
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.isDynamic = false
        self.physicsBody?.collisionBitMask = 0x1 << 0
        self.physicsBody?.contactTestBitMask = 0x1 << 0
        self.physicsBody?.categoryBitMask = self.categoryBitMask
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func moveLeft(){
        if self.position.x > -10 {
            self.position = CGPoint(x: self.position.x - 20, y: y)
        }
        else {
            self.position = CGPoint(x: 560, y: y)
        }
    }
    
    public func moveRight(){
        if self.position.x < 560 {
            self.position = CGPoint(x: self.position.x + 20, y: y)
        }
        else {
            self.position = CGPoint(x: -10, y: y)
        }
    }
}

public class GameController: ObservableObject {
    @Published var x: Int = 0//main number for the player (the base for every calculus across the rounds)
    @Published var y: Int = 0//random number generated to be added at the x
    @Published var rmx: Int = 0 //randomMax: the upper limit, the number which the player can't let x be higher than
    @Published var rmn: Int = 0 //randomMin: the down limit, the number which the player can't let x be lower than
    @Published var rounds: Int = 0
    @Published var timeToWin: Int = 120
    @Published var gameOver: Bool = false
    @Published var gravityMultiplier: CGFloat = 0.8 //controls zBlocks speed
    @Published var message: String?
    
    public init(){
        x = Int.random(in: 3...7)
        rmx = x + Int.random(in: 3...7)
        rmn = x - Int.random(in: 3...7)
        y = Int.random(in: rmx-x-2...rmx-x+10) //any number that will let x distance to rmx be in between [-2,10]
    }
    
    public func generateZBlocks() -> [Int]{
        /* Generates 3, 4 or 5 blocks to be the number Z (number chosen by the player to be subtracted from x). At least one of the zBlocks need to be a correct number
         (aka a number that if the player chooses will make it stays alive in the game).
         */
        
        var zBlocks: [Int] = [Int]()
        
        var numberOfZBlocks: Int = Int.random(in: 3...5)
        
        if x+y > rmx {
            //we only need the at least one correct number, if x+y > rmx. becuase if it is <= the player don't need subtract anything to stay in range [rmn,rmx].
            //not catching any zBlock is an option.
            let zCorrect = Int.random(in: x+y-rmx...x+y-rmn)//generates a number that will make x+y-zCorrect stay in the range [rmn,rmx]
            zBlocks.append(zCorrect)
            numberOfZBlocks -= 1
        }
        
        for _ in 1...numberOfZBlocks {
            zBlocks.append(Int.random(in: x+y-rmx-7...x+y-rmn+7))//generates a number that will make x+y-z stay in the range [rmn-7,rmx+7], could or couldnt be a correct number.
        }
        
        zBlocks.shuffle()
        return zBlocks
        
    }
    
    public func updateY() {
        //choosing the next random number to be added to x
        y = Int.random(in: rmx-x-2...rmx-x+10) //any number that will let x distance to rmx be in between [-2,10]
    }
    
    public func updateX(z: Int) {
        //this is the formula which the game goes around. x = the x from last iteration + random generated y - z number chosen by player to keep the x in between [rmn,rmx]
        x = x + y - z
        if x<rmn || x>rmx {
            //wrong number chosen
            self.message = "Unfortunately you chose the wrong number. Game over! 😢"
            self.gameOver = true
        }
        updateY()
        rounds += 1
        if Int.random(in: 1...4) == 2 {
            //25% chance to change limits
            updateRmx()
            updateRmn()
        }
    }
    
    public func updateRmx() {
        rmx = x + Int.random(in: 3...7)
    }
    public func updateRmn() {
        rmn = x - Int.random(in: 3...7)
    }
}

public struct NumberStatusView: View {
    @ObservedObject var gc: GameController
    
    public init(gc: GameController){
        self.gc = gc
    }
    
    public var body: some View {
        HStack{
            VStack {
                Text("\(gc.x)")
                    .font(.system(size: 35))
                    .bold()
                    .padding(.top,47)
                Text("x")
                    .font(Font.custom("Apple-Chancery", size: 30))
                    .offset(y: -20)
            }
            
            HStack{
                Text("+")
                    .font(.system(size: 30))
                    .bold()
                    .padding(5)
                
                Text("\(gc.y)")
                    .font(.system(size: 35))
                    .bold()
                
                Text("-")
                    .font(.system(size: 30))
                    .bold()
                    .padding(5)
                
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 50, height: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }
            
            Text("=")
                .font(.system(size: 35))
                .bold()
                .padding(15)
            
            Text("x")
                .font(Font.custom("Apple-Chancery", size: 40))
            Text("|")
                .font(.system(size: 35))
                .padding(.bottom,7)
            Text("\(gc.rmn)")
                .font(.system(size: 32))
                .bold()
            
            Text("<=")
                .font(.system(size: 20))
            
            Text("x")
                .font(Font.custom("Apple-Chancery", size: 40))
            
            Text("<=")
                .font(.system(size: 20))
            
            Text("\(gc.rmx)")
                .font(.system(size: 32))
                .bold()
            
            
        }
        .frame(width: 550, height: 110, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        .background(Color(#colorLiteral(red: 0.1725490196, green: 0.6666666667, blue: 0.9450980392, alpha: 1)))
    }
}

public struct SpeedButtonView: View {
    
    @ObservedObject var gc: GameController
    
    public init(gc: GameController) {
        self.gc = gc
    }
    
    public var body: some View {
        HStack(spacing: 20) {
            //button speed1
            if gc.gravityMultiplier == 0.8 {
                Image(nsImage: NSImage(named: "SelectedSpeed1.png") ?? NSImage())
                    .resizable()
                    .frame(width: 50, height: 50, alignment: .center)
                    .background(Color(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
            }
            else {
                ZStack {
                    Image(nsImage: NSImage(named: "Speed1.png") ?? NSImage())
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .background(Color(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
                    Button(action: {
                        gc.gravityMultiplier = 0.8
                    }, label: {
                        Text("")
                            .frame(width: 50, height: 50, alignment: .center)
                    })
                    .frame(width: 50, height: 50, alignment: .center)
                }
            }
            
            
            //button speed2
            if gc.gravityMultiplier == 1.2 {
                Image(nsImage: NSImage(named: "SelectedSpeed2.png") ?? NSImage())
                    .resizable()
                    .frame(width: 50, height: 50, alignment: .center)
                    .background(Color(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
            }
            else {
                ZStack {
                    Image(nsImage: NSImage(named: "Speed2.png") ?? NSImage())
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .background(Color(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
                    Button(action: {
                        gc.gravityMultiplier = 1.2
                    }, label: {
                        Text("")
                            .frame(width: 50, height: 50, alignment: .center)
                    })
                    .frame(width: 50, height: 50, alignment: .center)
                }
            }
            
            
            //button speed3
            if gc.gravityMultiplier == 3.0 {
                Image(nsImage: NSImage(named: "SelectedSpeed3.png") ?? NSImage())
                    .resizable()
                    .frame(width: 50, height: 50, alignment: .center)
                    .background(Color(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
            }
            else {
                ZStack {
                    Image(nsImage: NSImage(named: "Speed3.png") ?? NSImage())
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .background(Color(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
                    Button(action: {
                        gc.gravityMultiplier = 3.0
                    }, label: {
                        Text("")
                            .frame(width: 50, height: 50, alignment: .center)
                    })
                    .frame(width: 50, height: 50, alignment: .center)
                }
            }
        }
        .background(Color(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
    }
}

public struct InfoView: View {
    @ObservedObject var gc: GameController
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    public init(gc: GameController) {
        self.gc = gc
    }
    
    public var body: some View {
        HStack{
            VStack {
                Text("Round: \(gc.rounds)")
                    .foregroundColor(.black)
                    .padding(.bottom)
                    .font(.system(size: 20))
                Text("Win in: \(gc.timeToWin)s")
                    .foregroundColor(.black)
                    .font(.system(size: 20))
                    .onReceive(timer) { time in
                        if gc.timeToWin > 0 {
                            gc.timeToWin -= 1
                        }
                    }
            }
            Text("Speed Control: ")
                .foregroundColor(.black)
                .font(.system(size: 20))
                .padding(.leading, 50)
            SpeedButtonView(gc: gc)
        }
        .frame(width: 550, height: 110, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        .background(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
        .overlay(Rectangle().frame(width: nil, height: 3, alignment: .top).foregroundColor(.gray),alignment: .top)
    }
}

public class GameScene: SKScene, SKPhysicsContactDelegate {
    public var gc: GameController
    public var player: Player
    public var baseGravity: CGFloat = -0.1 //basically controlls the speed of the zBlocks
    public var ground: SKSpriteNode
    var subscription: AnyCancellable?
    
    public init(gc: GameController, keyEvent: AnyPublisher<NSEvent, Never>) {
        self.gc = gc
        player = Player()
        ground = SKSpriteNode(texture: nil, color: .gray, size: CGSize(width: 550, height: 2))
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 550, height: 1))
        ground.physicsBody?.isDynamic = false
        ground.position = CGPoint(x: 550/2, y: 0)
        ground.physicsBody?.categoryBitMask = 0x1 << 2
        ground.physicsBody?.collisionBitMask = 0x1 << 0
        ground.physicsBody?.contactTestBitMask = 0x1 << 0
        super.init(size: CGSize(width: 550, height: 580))
        self.backgroundColor = .white
        self.physicsWorld.gravity = CGVector(dx: 0, dy: gc.gravityMultiplier * baseGravity)
        self.physicsWorld.contactDelegate = self
        
        subscription = keyEvent.sink(receiveValue: handleKeyEvent(event:))
        
        
    }
    
    override public func sceneDidLoad() {
        super.sceneDidLoad()
        self.addChild(player)
        positioningZBlocks(list: gc.generateZBlocks())
        self.addChild(ground)
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        //zBlock collided with player?
        if collision == 0x1 << 1 | 0x1 << 0 {
            if contact.bodyA.categoryBitMask == player.categoryBitMask {
                numberChosen(zBlock: contact.bodyB.node as! ZBlock)
                contact.bodyB.node?.removeFromParent()
            }
            else {
                numberChosen(zBlock: contact.bodyA.node as! ZBlock)
                contact.bodyA.node?.removeFromParent()
            }
        }
        else {
            numberChosen(zBlock: ZBlock(z: 0))
        }
        let array = self.children.filter { (node) -> Bool in
            return node.name == "block"
        }
        
        self.removeChildren(in: array)
        positioningZBlocks(list: gc.generateZBlocks())
    }
    
    func numberChosen(zBlock: ZBlock) {
        gc.updateX(z: zBlock.z)
        zBlock.removeFromParent()
    }
    
    public func positioningZBlocks(list: [Int]) {
        var positions: [CGFloat] = [75, 175, 275, 375, 475]
        
        for zBlockNumber in list {
            let node = ZBlock(z: zBlockNumber)
            node.position = CGPoint(x: positions.remove(at: Int.random(in: 0...positions.count-1)), y: 535)
            node.name = "block"
            self.addChild(node)
        }
    }
    
    public func handleKeyEvent(event:NSEvent){
        if event.modifierFlags.contains(NSEvent.ModifierFlags.numericPad){
            if let theArrow = event.charactersIgnoringModifiers, let keyChar = theArrow.unicodeScalars.first?.value{
                switch Int(keyChar){
                case NSRightArrowFunctionKey:
                    player.moveRight()
                case NSLeftArrowFunctionKey:
                    player.moveLeft()
                default:
                    break
                }
            }
        }
    }
    
    override public func update(_ currentTime: TimeInterval) {
        if gc.timeToWin == 0 {
            gc.message = "Congratulations, you won! 😁🎉"
            gc.gameOver = true
        }
        if gc.gravityMultiplier * baseGravity != self.physicsWorld.gravity.dy {
            self.physicsWorld.gravity = CGVector(dx: 0, dy: gc.gravityMultiplier * baseGravity)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public struct GameView: View {
    @ObservedObject var gc: GameController
    var keyEvent: PassthroughSubject<NSEvent, Never>
    var scene: CurrentValueSubject<GameScene, Never>
    var keyEventPublisher: AnyPublisher<NSEvent, Never>
    
    public init() {
        //self.scene = GameScene(gc: gc, keyEvent: keyEvent)
        let gc = GameController()
        let keyEvent: PassthroughSubject<NSEvent, Never> = .init()
        let keyEventPublisher = keyEvent.share().eraseToAnyPublisher()
        let scene = GameScene(gc: gc, keyEvent: keyEventPublisher)
        self.keyEvent = keyEvent
        self.gc = gc
        self.scene = .init(scene)
        self.keyEventPublisher = keyEventPublisher
    }
    
    public var body: some View {
        if !gc.gameOver {
            VStack(spacing:0) {
                NumberStatusView(gc: gc)
                SpriteView(scene: scene.value)
                    .frame(width: 550, height: 580, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                InfoView(gc: gc)
            }
            .background(KeyEventHandling(keyEvent: keyEvent))
        }
        else {
            ZStack {
                Rectangle()
                    .foregroundColor(Color(#colorLiteral(red: 0.9450980392, green: 0.5450980392, blue: 0.1725490196, alpha: 1)))
                    .frame(width: 550, height: 800, alignment: .center)
                VStack {
                    Text(gc.message!)
                    .font(.system(size: 35))
                    .padding(25)
                    .frame(width: 375, height: 300, alignment: .center)
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(Color(#colorLiteral(red: 0.1725490196, green: 0.6666666667, blue: 0.9450980392, alpha: 1)))
                        Button(action:{
                            gc.gameOver = false
                            gc.rounds = 0
                            gc.x = Int.random(in: 3...7)
                            gc.updateRmn()
                            gc.updateRmx()
                            gc.updateY()
                            gc.timeToWin = 120
                            scene.value = GameScene(gc: self.gc, keyEvent: self.keyEventPublisher)
                        }, label: {Text("Play Again")})
                    }
                    .frame(width: 250, height: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                }
            }
        }
    }
}

struct KeyEventHandling: NSViewRepresentable {
    let keyEvent: PassthroughSubject<NSEvent, Never>
    
    class KeyView: NSView {
        var keyEvent: PassthroughSubject<NSEvent, Never>?
        
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            super.keyDown(with: event)
            keyEvent?.send(event)
        }
    }

    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.keyEvent = keyEvent
        DispatchQueue.main.async { // wait till next event cycle
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}


