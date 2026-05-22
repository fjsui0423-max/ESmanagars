import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "briefcase.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("ESmanagers")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Welcome")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
