import CoreAudioKit

class BTMIDIViewController: CABTMIDICentralViewController {

    var uiViewController: UIViewController?

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(doneAction))
    }

    @objc public func doneAction() {
        uiViewController?.dismiss(animated: true, completion: nil)
    }
}

public class BluetoothMIDIButton: UIButton {

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let vc = BTMIDIViewController()
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .popover
        let popC = navController.popoverPresentationController
        popC?.permittedArrowDirections = .any
        popC?.sourceRect = self.frame
        popC?.sourceView = self.superview
        let controller = self.superview?.next as? UIViewController
        controller?.present(navController, animated: true, completion: nil)
        vc.uiViewController = controller
    }
}
