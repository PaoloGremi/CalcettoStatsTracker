import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Apri con una finestra più ampia del default (800x600) e impedisci di
    // ridimensionarla troppo, per evitare overflow nei layout della home.
    self.setContentSize(NSSize(width: 1280, height: 860))
    self.minSize = NSSize(width: 960, height: 700)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
