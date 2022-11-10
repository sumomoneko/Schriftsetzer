import Cocoa
import InputMethodKit

@objc(SchriftsetzerInputController)
class SchriftsetzerInputController: IMKInputController {
    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        NSLog(string)
        // get client to insert
        guard let client = sender as? IMKTextInput else {
            return false
        }
        client.insertText(string+string, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        return true
    }
}
