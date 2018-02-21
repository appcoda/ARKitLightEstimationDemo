//
//  ViewController.swift
//  ARKitLightDemo
//
//  Created by Jayven Nhan on 1/25/18.
//  Copyright © 2018 Jayven Nhan. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var lightEstimationStackView: UIStackView!
    
    @IBOutlet weak var ambientIntensityLabel: UILabel!
    @IBOutlet weak var ambientColorTemperatureLabel: UILabel!
    
    @IBOutlet weak var ambientIntensitySlider: UISlider!
    @IBOutlet weak var ambientColorTemperatureSlider: UISlider!
    
    @IBOutlet weak var lightEstimationSwitch: UISwitch!
    
    var lightNodes = [SCNNode]()
    
    var detectedHorizontalPlane = false {
        didSet {
            DispatchQueue.main.async {
                self.mainStackView.isHidden = !self.detectedHorizontalPlane
                self.instructionLabel.isHidden = self.detectedHorizontalPlane
                self.lightEstimationStackView.isHidden = !self.detectedHorizontalPlane
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        sceneView.delegate = self
    }
    
    @IBAction func ambientIntensitySliderValueDidChange(_ sender: UISlider) {
        DispatchQueue.main.async {
            let ambientIntensity = sender.value
            self.ambientIntensityLabel.text = "Ambient Intensity: \(ambientIntensity)"
            
            guard !self.lightEstimationSwitch.isOn else { return }
            for lightNode in self.lightNodes {
                guard let light = lightNode.light else { continue }
                light.intensity = CGFloat(ambientIntensity)
            }
        }
    }
    
    @IBAction func ambientColorTemperatureSliderValueDidChange(_ sender: UISlider) {
        DispatchQueue.main.async {
            let ambientColorTemperature = self.ambientColorTemperatureSlider.value
            self.ambientColorTemperatureLabel.text = "Ambient Color Temperature: \(ambientColorTemperature)"
            
            guard !self.lightEstimationSwitch.isOn else { return }
            for lightNode in self.lightNodes {
                guard let light = lightNode.light else { continue }
                light.temperature = CGFloat(ambientColorTemperature)
            }
        }
    }
    
    @IBAction func lightEstimationSwitchValueDidChange(_ sender: UISwitch) {
        ambientIntensitySliderValueDidChange(ambientIntensitySlider)
        ambientColorTemperatureSliderValueDidChange(ambientColorTemperatureSlider)
    }
    
    func updateLightNodesLightEstimation() {
        DispatchQueue.main.async {
            guard self.lightEstimationSwitch.isOn,
                let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate
                else { return }
            
            let ambientIntensity = lightEstimate.ambientIntensity
            let ambientColorTemperature = lightEstimate.ambientColorTemperature
            
            for lightNode in self.lightNodes {
                guard let light = lightNode.light else { continue }
                light.intensity = ambientIntensity
                light.temperature = ambientColorTemperature
            }
        }
    }
    
    func getSphereNode(withPosition position: SCNVector3) -> SCNNode {
        let sphere = SCNSphere(radius: 0.1)
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position
        sphereNode.position.y += Float(sphere.radius) + 1
        
        return sphereNode
    }
    
    func getLightNode() -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 0
        light.temperature = 0
        
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0,1,0)
        
        return lightNode
    }
    
    func addLightNodeTo(_ node: SCNNode) {
        let lightNode = getLightNode()
        node.addChildNode(lightNode)
        lightNodes.append(lightNode)
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let planeAnchorCenter = SCNVector3(planeAnchor.center)
        let sphereNode = getSphereNode(withPosition: planeAnchorCenter)
        addLightNodeTo(sphereNode)
        node.addChildNode(sphereNode)
        detectedHorizontalPlane = true
        updateLightNodesLightEstimation()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

