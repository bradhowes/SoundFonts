import Foundation

// E621E1F8-C36C-495A-93FC-0C247A3E6E5F
// "[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}"

let pattern = "[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}"
let uuidString = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F" as NSString
let z = uuidString.range(of: pattern, options: .regularExpression)
print(z)
