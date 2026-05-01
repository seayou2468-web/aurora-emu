import SwiftUI

struct AuroraSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showFPS") private var showFPS = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("Show FPS", isOn: $showFPS)
                }
                Section("Controls") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
