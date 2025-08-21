import SwiftUI
import MapKit

struct MapPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedAddress: String
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $mapRegion, interactionModes: .all, showsUserLocation: false, annotationItems: annotationItems()) { item in
                    MapMarker(coordinate: item.coordinate, tint: .blue)
                }
                .onTapGesture(coordinateSpace: .global) { location in
                    selectedCoordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                    fetchAddress(for: location)
                }
            }
            .navigationBarItems(leading: Button("Cancel") { dismiss() }, trailing: Button("Save") {
                dismiss()
            })
        }
    }
    
    private func annotationItems() -> [AnnotationItem] {
        if let coordinate = selectedCoordinate {
            return [AnnotationItem(coordinate: coordinate)]
        }
        return []
    }
    
    private func fetchAddress(for location: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let placemark = placemarks?.first {
                selectedAddress = placemark.name ?? "Selected Location"
            }
        }
    }
}

struct AnnotationItem: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}
