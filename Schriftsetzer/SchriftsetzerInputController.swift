import Cocoa
import InputMethodKit

@objc(SchriftsetzerInputController)
class SchriftsetzerInputController: IMKInputController {
  var pendingText: String = ""

  let notFound = NSRange(location: NSNotFound, length: NSNotFound)

  override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {

    NSLog(
      "%@", "\(#function)((\(String(describing: event)), client: \(String(describing: sender)))")

    // get client to insert
    guard let client = sender as? IMKTextInput else {
      return false
    }

    // parse input data
    var inputType = InputType.control
    if event.keyCode == 51 {
      inputType = .backspace
    } else if let text = event.characters, isPrintable(text) {
      inputType = .printable(text)
    }

    switch inputType {
    case .backspace:
      if pendingText != "" {
        // apply backspace
        pendingText.removeLast()

        // set marked text if any
        let (markedText, _) = convertTable[pendingText] ?? ("", false)
        client.setMarkedText(markedText, selectionRange: notFound, replacementRange: notFound)

        // backspace handled
        return true
      }

    case .printable(let input):
      let newPendingText = pendingText + input

      if let (markedText, mayContinue) = convertTable[newPendingText] {
        if mayContinue {
          // set marked text with new input
          client.setMarkedText(markedText, selectionRange: notFound, replacementRange: notFound)
          pendingText = newPendingText

          return true
        } else {
          // fix with new input
          client.setMarkedText("", selectionRange: notFound, replacementRange: notFound)
          client.insertText(markedText, replacementRange: notFound)
          pendingText = ""

          return true
        }

      } else {
        // fix with pending text
        if let (prevMarkedText, _) = convertTable[pendingText] {
          client.setMarkedText("", selectionRange: notFound, replacementRange: notFound)
          client.insertText(prevMarkedText, replacementRange: notFound)
          pendingText = ""
        }

        // then, check new input text
        if let (markedText, mayContinue) = convertTable[input] {
          assert(mayContinue)
          // set marked text
          client.setMarkedText(markedText, selectionRange: notFound, replacementRange: notFound)
          pendingText = input

          // input handled as pending
          return true
        }
      }

    case .control:
      // fix with pending if any
      if let (markedText, _) = convertTable[pendingText] {
        client.setMarkedText("", selectionRange: notFound, replacementRange: notFound)
        client.insertText(markedText, replacementRange: notFound)
        pendingText = ""
      }
    }

    // not handled
    return false
  }
}

enum InputType {
  case backspace
  case printable(String)
  case control
}

// inputs -> (display string, may continue?)
let convertTable = [
  "a": ("a", true),
  "au": ("au", true),
  "aue": ("aue", false),
  "ae": ("ä", true),
  "aee": ("ae", false),

  "o": ("o", true),
  "oe": ("ö", true),
  "oee": ("oe", false),

  "u": ("u", true),
  "ue": ("ü", true),
  "uee": ("ue", false),

  "s": ("s", true),
  "sz": ("ß", true),
  "szz": ("sz", false),

  "g": ("g", true),
  "ge": ("ge", false),

  "q": ("q", true),
  "qu": ("qu", true),
  "que": ("que", false),

  "e": ("e", true),
  "eu": ("eu", true),
  "eue": ("eue", false),

  "A": ("A", true),
  "Au": ("Au", true),
  "Aue": ("Aue", false),
  "AE": ("Ä", true),
  "AEE": ("AE", false),

  "O": ("O", true),
  "OE": ("Ö", true),
  "OEE": ("OE", false),

  "U": ("U", true),
  "UE": ("Ü", true),
  "UEE": ("UE", false),

  "S": ("S", true),
  "SZ": ("ẞ", true),
  "SZZ": ("SZ", false),

  "Q": ("Q", true),
  "Qu": ("Qu", true),
  "Que": ("Que", false),

  "E": ("E", true),
  "Eu": ("Eu", true),
  "Eue": ("Eue", false),

  "E=": ("€", true),
  "E==": ("E=", false),
]

func isPrintable(_ text: String) -> Bool {
  let printable: CharacterSet = [
    CharacterSet.alphanumerics,
    CharacterSet.symbols,
    CharacterSet.punctuationCharacters,
  ].reduce(CharacterSet()) { $0.union($1) }

  return !text.unicodeScalars.contains { !printable.contains($0) }
}
