import Luminare
import SwiftUI

struct SettingsWindowContentView: View {
    @AppStorage("apiKey") private var apiKeyStorage: String?
    @State private var apiKey: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LuminareSection("settings.general") {
                HStack {
                    Text("settings.apiKey")
                    Spacer()
                    LuminareTextField("settings.apiKey.placeholder", text: $apiKey)
                        .onChange(of: apiKey) { newValue in
                            apiKeyStorage = newValue.isEmpty ? nil : newValue
                        }
                        .onAppear {
                            apiKey = apiKeyStorage ?? ""
                        }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(16)
        .frame(width: 512, alignment: .topLeading)
        .luminareBackground()
    }
}
