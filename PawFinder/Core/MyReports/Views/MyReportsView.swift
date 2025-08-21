import SwiftUI

struct MyReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: MyReportsTab = .lostPets

    // Dummy Data
    private let reportedPets: [ReportedPet] = [
        ReportedPet(
            name: "Tommy",
            breed: "Golden Retriever",
            daysMissing: 3,
            sightings: 7,
            views: 156,
            image: "goldenretriever"
        ),
        ReportedPet(
            name: "Max",
            breed: "German Shepherd",
            daysMissing: 0,
            sightings: 15,
            views: 200,
            image: "germanshepherd",
            found: true
        )
    ]

    private let userSightings: [UserSighting] = [
        UserSighting(
            petName: "Bella",
            breed: "Husky",
            date: "Aug 10",
            image: "husky"
        ),
        UserSighting(
            petName: "Mittens",
            breed: "Persian Cat",
            date: "Jul 29",
            image: "cat"
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.4, green: 0.3, blue: 0.8),
                                           Color(red: 0.6, green: 0.4, blue: 0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Custom Back Button
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Back")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 30)
                    .padding(.leading, 16)

                    // Header
                    VStack(spacing: 8) {
                        Text("My Reports")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Helping 3 pets • 12 Contributions")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.top, 10)

                    // Tabs
                    HStack(spacing: 0) {
                        ForEach(MyReportsTab.allCases, id: \.self) { tab in
                            Button(action: {
                                selectedTab = tab
                            }) {
                                Text(tab.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedTab == tab ? Color(red: 0.4, green: 0.3, blue: 0.8) : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedTab == tab ? Color.white : Color.white.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(24)
                    .padding(.horizontal, 32)

                    // Section
                    if selectedTab == .lostPets {
                        LostPetsSection(pets: reportedPets)
                    } else {
                        SightingsSection(sightings: userSightings)
                    }

                    // Community Hero Card
                    CommunityHeroCard()

                    // Start Helping Card
                    StartHelpingCard()
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // No standard nav bar back button, only custom as per image2
    }
}

// MARK: - Tab Enum
enum MyReportsTab: CaseIterable {
    case lostPets, sightings

    var title: String {
        switch self {
        case .lostPets: return "My Lost Pets"
        case .sightings: return "My Sightings"
        }
    }
}

// MARK: - Dummy Models
struct ReportedPet: Identifiable {
    let id = UUID()
    let name: String
    let breed: String
    let daysMissing: Int
    let sightings: Int
    let views: Int
    let image: String
    var found: Bool = false
}

struct UserSighting: Identifiable {
    let id = UUID()
    let petName: String
    let breed: String
    let date: String
    let image: String
}

// MARK: - Lost Pets Section
struct LostPetsSection: View {
    let pets: [ReportedPet]

    var body: some View {
        VStack(spacing: 18) {
            // Active Reports Card
            if pets.contains(where: { !$0.found }) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("\(pets.filter{ !$0.found }.count) Active Reports")
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                        Button(action: {}) {
                            Text("Share All")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                        }
                    }
                    Text("Community is actively searching")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    ForEach(pets.filter { !$0.found }) { pet in
                        ReportedPetCard(pet: pet)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 7, x: 0, y: 4)
            }

            // Found Pet Card(s)
            ForEach(pets.filter { $0.found }) { pet in
                FoundPetCard(pet: pet)
            }
        }
        .padding(.horizontal, 22)
    }
}

// MARK: - Sightings Section
struct SightingsSection: View {
    let sightings: [UserSighting]

    var body: some View {
        VStack(spacing: 18) {
            if sightings.isEmpty {
                Text("No sightings reported yet.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(18)
            } else {
                ForEach(sightings) { sighting in
                    SightingCard(sighting: sighting)
                }
            }
        }
        .padding(.horizontal, 22)
    }
}

// MARK: - Card Views
struct ReportedPetCard: View {
    let pet: ReportedPet
    var body: some View {
        HStack(spacing: 14) {
            Image(pet.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 65, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 7) {
                Text(pet.name)
                    .font(.system(size: 18, weight: .bold))
                Text(pet.breed)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                Text("Missing for \(pet.daysMissing) days")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                HStack(spacing: 18) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.blue)
                        Text("\(pet.sightings) Sightings")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        Text("\(pet.views)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

struct FoundPetCard: View {
    let pet: ReportedPet
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("🎉 \(pet.name) was found!")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                Text("Thanks to \(pet.sightings) community helpers")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.vertical, 1)
            }
            Spacer()
            Image(pet.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
        .padding(18)
        .background(Color(red: 0.4, green: 0.7, blue: 0.8))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.09), radius: 4, x: 0, y: 2)
    }
}

struct CommunityHeroCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 30))
                .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.7))
            VStack(alignment: .leading, spacing: 2) {
                Text("Community Hero")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Text("Helped 5 pets to get closer to home")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 22)
    }
}

struct StartHelpingCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 30))
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
            VStack(alignment: .leading, spacing: 2) {
                Text("Start helping your community")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 22)
    }
}

struct SightingCard: View {
    let sighting: UserSighting
    var body: some View {
        HStack(spacing: 14) {
            Image(sighting.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(sighting.petName)
                    .font(.system(size: 16, weight: .bold))
                Text(sighting.breed)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                Text("Reported: \(sighting.date)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    MyReportsView()
}
