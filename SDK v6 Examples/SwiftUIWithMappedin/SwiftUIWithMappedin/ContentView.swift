import SwiftUI
import Mappedin

struct ContentView: View {
    @StateObject private var model = MapModel()

    var body: some View {
        VStack(spacing: 0) {
            MapViewRepresentable(model: model)
                .ignoresSafeArea(edges: .bottom)

            HStack {
                Button("Clear Labels") {
                    model.mapView.labels.removeAll()
                }
                .font(.footnote)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .alert(model.alertTitle, isPresented: $model.showAlert) {
            Button("Close", role: .cancel) {}
        } message: {
            Text(model.alertMessage)
        }
    }
}

#Preview {
    ContentView()
}
