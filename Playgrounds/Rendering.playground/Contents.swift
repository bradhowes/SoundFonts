import AVFoundation
import UIKit
import PlaygroundSupport

class AudioRender {
    let audioEngine = AVAudioEngine()

    let renderBuffer: AVAudioPCMBuffer

    var sourceBuffer = [Float]()
    var isPlaying = false

    init() {
        let sourceSampleRate: Double = 32000.0
        let sourceSignalMIDI: Int = 69
        let sourceSignalFrequency = 440.0

        let destinationSampleRate: Double = 44100.0
        let destinationSignalMIDI: Int = 69

        let sourceFrameCount = AVAudioFrameCount(sourceSampleRate)
        let destinationFrameCount = AVAudioFrameCount(destinationSampleRate)

        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: destinationSampleRate, channels: 1)!
        renderBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: destinationFrameCount)!
        renderBuffer.frameLength = destinationFrameCount

        sourceBuffer = .init(repeating: 0.0, count: Int(sourceFrameCount))
        let step = 2 * Double.pi / Double(sourceFrameCount)
        for index in 0..<Int(sourceFrameCount) {
            sourceBuffer[index] = sinf(Float(sourceSignalFrequency * Double(index) * step))
        }

        let sampleRateRatio = sourceSampleRate / destinationSampleRate
        let frequencyRatio = Double(powf(2.0, Float(destinationSignalMIDI - sourceSignalMIDI) / 12.0))
        let increment = sampleRateRatio * frequencyRatio

        let destinationBuffer = renderBuffer.floatChannelData!.pointee
        var pos: Double = 0.0
        for index in 0..<Int(destinationFrameCount) {
            let whole = Int(pos)
            let partial = Float(pos - Double(whole))
            let nextValue = (whole + 1) < sourceFrameCount ? sourceBuffer[whole + 1] : sourceBuffer[0]
            let value = sourceBuffer[whole] * (1.0 - partial) + nextValue * partial
            destinationBuffer[index] = value
            pos += increment
            if pos >= Double(sourceFrameCount) {
                pos -= Double(sourceFrameCount)
            }
        }
    }

    func play() {
        guard !isPlaying else { return }

        let playerNode = AVAudioPlayerNode()
        self.audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: renderBuffer.format)
        do {
            try audioEngine.start()
        } catch let err as NSError {
            print("failed to start engine: \(err.code) \(err.domain)")
            return
        }

        playerNode.play()
        playerNode.scheduleBuffer(renderBuffer, at :nil, options: [.loops])
        isPlaying = true
    }

    func stop() {
        guard isPlaying else { return }
        audioEngine.stop()
        isPlaying = false
    }
}

class MyViewController : UIViewController {

    var label : UILabel!
    var startStop : UIButton!
    let render = AudioRender()

    override func loadView() {

        // UI

        let view = UIView()
        view.backgroundColor = .white

        startStop = UIButton(type: .system)
        startStop.setTitle("Start", for: .normal)
        startStop.tintColor = .red
        startStop.addTarget(self, action: #selector(togglePlaying), for: .touchUpInside)

        view.addSubview(startStop)

        startStop.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startStop.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            startStop.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ])

        self.view = view
    }

    @objc func togglePlaying() {
        if render.isPlaying {
            render.stop()
            startStop.setTitle("Start", for: .normal)
        }
        else {
            render.play()
            startStop.setTitle("Stop", for: .normal)
        }
    }
}

PlaygroundPage.current.liveView = MyViewController()
