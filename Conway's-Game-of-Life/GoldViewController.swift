//
//  GoldViewController.swift
//  Conway's-Game-of-Life
//
//  Created by Artur Carneiro on 04/11/19.
//  Copyright © 2019 Artur Carneiro. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GoldViewController: UIViewController, SCNSceneRendererDelegate {
    
    // MARK: Variables
    
    private lazy var sceneView: SCNView = {
        let view = SCNView(frame: .zero)
        return view
    }()
    
    private lazy var scene: SCNScene = {
        let scene = SCNScene()
        return scene
    }()
    
    private var boxArray: [[SCNNode]] = []
    
    private lazy var playButton: UIButton = {
        let view = UIButton(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var timeInterval: TimeInterval = 0
    private let timeConstant: TimeInterval  = 0.1
    private var floor: Float = 0
    
    private let gameManager: GameManager
    private var boxBank: [SCNNode] = []
    
    private let letterArr: [String] = ["M","O","B","P","S","Y","C","H","O","1","0","0","I","S","T","H","E","B","E","S","T"]
    private let mob: String = "MOB"
    
    // MARK: init
    
    init() {
        self.gameManager = GameManager()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
        setupCamera()
        setupBoxGrid()
        setupPlayButton()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(spawn(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Setup
    
    func initialSetup() {
        sceneView.frame = self.view.frame
        self.view = sceneView
        sceneView.backgroundColor = .black
        sceneView.showsStatistics = false
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
        sceneView.isPlaying = false
        sceneView.scene = scene
    }
    
    func setupBoxGrid() {
        for y in 0...15 {
            var line: [SCNNode] = []
            for x in 0...15 {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.white
                let geometry: SCNGeometry
                geometry = SCNBox(width: 0.8, height: 0.8, length: 0.8, chamferRadius: 0)
                geometry.firstMaterial = material
                let geometryNode = SCNNode(geometry: geometry)
                geometryNode.position.x = Float(x)
                geometryNode.position.y = Float(-y)
                scene.rootNode.addChildNode(geometryNode)
                line.append(geometryNode)
            }
            boxArray.append(line)
        }
    }
    
    private func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(7.5, -7, 35)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupPlayButton() {
        playButton.backgroundColor = .systemRed
        playButton.layer.cornerRadius = 10
        playButton.setTitle("PLAY", for: .normal)
        playButton.setTitle("STOP", for: .selected)
        playButton.addTarget(self, action: #selector(startGameLoop), for: .touchDown)
        
        self.view.addSubview(playButton)

        playButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        playButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100).isActive = true
        playButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20).isActive = true
    }
    
    // MARK: Game Logic
    
    private func spawnObject(letter: String) -> SCNNode {
        let geometry: SCNGeometry
        geometry = SCNText(string: letter, extrusionDepth: 0)
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
        scene.rootNode.addChildNode(geometryNode)
        return geometryNode
    }
    
    private func setNewGrid(survivors: [(Int,Int)], dead: [(Int,Int)] ) {
        for i in survivors {
            let box = spawnObject(letter: mob)
            box.geometry?.firstMaterial?.diffuse.contents = randomUIColor()
            box.position = boxArray[i.0][i.1].position
            box.position.z = floor
            
            let action = SCNAction.repeatForever(SCNAction.rotate(by: .pi, around: SCNVector3(Double(i.0),Double(i.1),0.0), duration: 0.5))
            box.runAction(action)
            
            let light = SCNLight()
            light.type = .spot
            light.drawsArea = true
            light.intensity = 1000
            light.spotOuterAngle = 120
            light.color = randomUIColor()
            box.light = light
            
            boxBank.append(box)
        }
        for j in dead {
            boxArray[j.0][j.1].geometry?.firstMaterial?.diffuse.contents = UIColor.white
        }
        floor += 0.8
    }
    
    @objc func startGameLoop() {
        if sceneView.isPlaying {
            playButton.backgroundColor = .systemRed
            playButton.isSelected = false
            timeInterval = 0
            sceneView.isPlaying = false
            for box in boxBank {
                box.removeFromParentNode()
            }
            gameManager.resetGrid()
            floor = 0
        } else {
            sceneView.isPlaying = true
            playButton.isSelected = true
            playButton.backgroundColor = .gray
        }
    }
    
    @objc func spawn(_ gestureRecognizer: UIGestureRecognizer) {
        
        
        guard let view = self.view as? SCNView else { return }
        
        let location = gestureRecognizer.location(in: view)
        let hitResults = view.hitTest(location, options: [:])
        
        if hitResults.count > 0 {
            let result = hitResults[0]
            guard let material = result.node.geometry?.firstMaterial else { return }
            material.diffuse.contents = UIColor.systemRed
            for x in 0..<boxArray.count {
                for y in 0..<boxArray[0].count {
                    if boxArray[x][y] == result.node {
                        if gameManager.grid[x][y] {
                            gameManager.grid[x][y] = false
                            var toBeRemoved: [Int] = []
                            for i in 0..<gameManager.survivors.count {
                                if gameManager.survivors[i] == (x,y) {
                                    boxArray[x][y].geometry?.firstMaterial?.diffuse.contents = UIColor.white
                                    toBeRemoved.append(i)
                                }
                            }
                            for j in 0..<toBeRemoved.count {
                                gameManager.survivors.remove(at: j)
                            }
                        } else {
                            gameManager.grid[x][y] = true
                            gameManager.survivors.append((x,y))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Renderer
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if timeInterval < 0.01 {
            timeInterval = time
        }
        let deltaTime = time - timeInterval
        if sceneView.isPlaying && deltaTime > timeConstant {
            gameManager.gameLoop()
            setNewGrid(survivors: gameManager.survivors, dead: gameManager.dead)
            gameManager.clearGenerationArray()
            timeInterval = time
        }
    }

}
