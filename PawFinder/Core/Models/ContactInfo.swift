import Foundation

struct ContactInfo {
    let phone: String
    let email: String
    let preferredContactMethod: ContactMethod
}

enum ContactMethod: String {
    case phone = "Phone"
    case email = "Email"
    case both = "Both"
}
