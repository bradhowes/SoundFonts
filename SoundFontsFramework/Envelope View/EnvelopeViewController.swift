// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox
import UIKit
import os

public class EnvelopeViewController: UIViewController {
    private lazy var log = Logging.logger("EnvVC")

    private var swipeLeft = UISwipeGestureRecognizer()
    private var swipeRight = UISwipeGestureRecognizer()

    private var sampler: Sampler!
    private var infoBar: InfoBar!

    @IBOutlet private weak var active: UISwitch!
    @IBOutlet private weak var attack: VSSlider!
    @IBOutlet private weak var decay: VSSlider!
    @IBOutlet private weak var sustain: VSSlider!
    @IBOutlet private weak var ruhlease: VSSlider!

    private enum ParameterControl: Int, CaseIterable {
        case attack = 1000
        case decay
        case sustain
        case release
    }

    public override func viewDidLoad() {
        addControls()

        swipeLeft.direction = .left
        swipeLeft.numberOfTouchesRequired = 2
        view.addGestureRecognizer(swipeLeft)

        swipeRight.direction = .right
        swipeRight.numberOfTouchesRequired = 2
        view.addGestureRecognizer(swipeRight)
    }
}

extension EnvelopeViewController: EnvelopeViewManager {

    public func addTarget(_ event: UpperViewSwipingEvent, target: Any, action: Selector) {
        switch event {
        case .swipeLeft: swipeLeft.addTarget(target, action: action)
        case .swipeRight: swipeRight.addTarget(target, action: action)
        }
    }
}

extension EnvelopeViewController: ControllerConfiguration {

    public func establishConnections(_ router: ComponentContainer) {
        sampler = router.sampler
        infoBar = router.infoBar
        sampler.subscribe(self, notifier: patchLoaded(_:))
    }

    private func patchLoaded(_ event: SamplerEvent) {
        os_log(.info, log: log, "patchLoaded")
        switch event {
        case .loaded(patch: _):
            // connectControls()
            break
        }
    }
}

extension EnvelopeViewController: EnvelopeSelectorDelegate {

    func selectionChanged(value: EnvelopeSelected) {
        print("new selection")
    }
}

extension EnvelopeViewController {

    private func control(of parameter: ParameterControl) -> VSSlider {
        switch parameter {
        case .attack: return attack
        case .decay: return decay
        case .sustain: return sustain
        case .release: return ruhlease
        }
    }

    private func parameter(of control: VSSlider) -> ParameterControl {
        guard let pc = ParameterControl(rawValue: control.tag) else {
            preconditionFailure("unexpected control")
        }
        return pc
    }

    private func addControls() {
        active.addTarget(self, action: #selector(activeChanged(_:)), for: .valueChanged)

        for pc in ParameterControl.allCases {
            let slider = control(of: pc)
            slider.minimumValue = 0.0
            slider.maximumValue = 1.0
            slider.increment = 0.10
            slider.value = 0.5
            slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
            slider.tag = pc.rawValue
            slider.addTapGesture()
            slider.isEnabled = active.isOn
        }
    }

    @objc func activeChanged(_ sender: UISwitch) {
        for pc in ParameterControl.allCases {
            let slider = control(of: pc)
            slider.isEnabled = sender.isOn
        }
    }

    @objc func sliderChanged(_ slider: UISlider) {
        os_log(.info, log: log, "valueChanged - BEGIN %d %f", slider.tag, slider.value)
        infoBar.setStatus(Formatters.formatted(sliderValue: slider.value))
        try? sampler.auSampler?.audioUnit.setPropertyValue(UInt32(slider.tag), value: slider.value)
    }

    private func connectControls() {
        os_log(.info, log: log, "connectControls - BEGIN")
        defer { os_log(.info, log: log, "connectControls - END") }

        guard let sampler = self.sampler.auSampler else { return }
        guard let presets = try? sampler.audioUnit.getPropertyValue(kAudioUnitProperty_ClassInfo)
            as CFPropertyList else { return }

        os_log(.info, log: log, "%{public}s", presets.description)
        guard let instrument = presets["Instrument"] as? NSMutableDictionary else { return }
        guard let existingLayers = instrument["Layers"] as? NSArray else { return }

        os_log(.info, log: log, "num layers: %d", existingLayers.count)
        for layer in zip(0..<existingLayers.count, existingLayers) {
            guard let layerDict = layer.1 as? NSDictionary else { continue }
            os_log(.info, log: log, "- layer[%d]: %{public}s", layer.0, layerDict.description)
            guard let existingConnections = layerDict["Connections"] as? NSArray else { continue }
            os_log(.info, log: log, "- num connections: %d", existingConnections.count)
            for connection in zip(0..<existingConnections.count, existingConnections) {
                guard let connectionDict = connection.1 as? NSDictionary else { continue }
                os_log(.info, log: log, "-- con[%d]: %{public}s", connection.0, connectionDict.description)
            }
        }
    }
}


//this is the connection we will be adding
//NSMutableDictionary *attackConnection = [NSMutableDictionary dictionaryWithDictionary:
//                                        @{@"ID"        :@0,
//                                          @"control"   :@0,
//                                          @"destination":@570425344,
//                                          @"enabled"   :[NSNumber numberWithBool:1],
//                                          @"inverse"   :[NSNumber numberWithBool:0],
//                                          @"scale"     :@10,
//                                          @"source"    :@73,
//                                          @"transform" :@1,
//                                        }];
//
//AVAudioUnitSampler *sampler;//already initialized and loaded with samples or this won't work
//
//CFPropertyListRef presetPlist;
//UInt32 presetSize = sizeof(CFPropertyListRef);
//AudioUnitGetProperty(sampler.audioUnit, kAudioUnitProperty_ClassInfo, kAudioUnitScope_Global, 0, &presetPlist, &presetSize);
//NSMutableDictionary *mutablePreset = [NSMutableDictionary dictionaryWithDictionary:(__bridge NSDictionary *)presetPlist];
//CFRelease(presetPlist);
//NSMutableDictionary *instrument = [NSMutableDictionary dictionaryWithDictionary: mutablePreset[@"Instrument"]];
//
//NSArray *existingLayers = instrument[@"Layers"];
//if (existingLayers.count) {
//    NSMutableArray      *layers     = [[NSMutableArray alloc]init];
//    for (NSDictionary *layer in existingLayers){
//        NSMutableDictionary *mutableLayer = [NSMutableDictionary dictionaryWithDictionary:layer];
//        NSArray *existingConections = mutableLayer[@"Connections"];
//
//        if (existingConections) {
//            attackConnection[@"ID"] = [NSNumber numberWithInteger:existingConections.count];
//            NSMutableArray *connections = [NSMutableArray arrayWithArray:existingConections];
//            [connections addObject:attackConnection];
//            [mutableLayer setObject:connections forKey:@"Connections"];
//        }
//        else{
//            attackConnection[@"ID"] = [NSNumber numberWithInteger:0];
//            [mutableLayer setObject:@[attackConnection] forKey:@"Connections"];
//        }
//        [layers addObject:mutableLayer];
//    }
//    [instrument setObject:layers forKeyedSubscript:@"Layers"];
//}
//else{
//    instrument[@"Layers"] = @[@{@"Connections":@[attackConnection]}];
//}
//[mutablePreset setObject:instrument forKey:@"Instrument"];
//
//CFPropertyListRef editedPreset = (__bridge CFPropertyListRef)mutablePreset;
//AudioUnitSetProperty(sampler.audioUnit,kAudioUnitProperty_ClassInfo,kAudioUnitScope_Global,0,&editedPreset,sizeof(presetPlist));
//Then after this connection has been made you set the attack like this.
//
//uint8_t value = 100; //0 -> 127
