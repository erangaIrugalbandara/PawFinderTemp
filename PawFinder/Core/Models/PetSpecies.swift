import Foundation

enum PetSpecies: String, CaseIterable, Decodable {
    case dog = "Dog"
    case cat = "Cat"
    case bird = "Bird"
    case rabbit = "Rabbit" // Add this case
    case other = "Other"
}
