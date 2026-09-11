import SwiftUI

struct SettingsView: View {
    @AppStorage("apiKey") var apiKey: String = ""
    @AppStorage("baseURL") var baseURL: String = "https://ai.ibrahimhalilsezgin.com/v1"
    @AppStorage("selectedModel") var selectedModel: String = "ag/gemini-3.6-flash-high"
    @AppStorage("systemPrompt") var systemPrompt: String = "Sen Türkçe yanıt veren, yardımsever ve hızlı bir kişisel asistansın."

    @Environment(\.dismiss) var dismiss

    let popularModels = [
        "ag/gemini-3.6-flash-high",
        "ag/gemini-3.8-flash-high",
        "gpt-4o-mini",
        "custom"
    ]

    @State private var customModel: String = ""
    @State private var isCustomModel: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("API Yapılandırması")) {
                    SecureField("API Key", text: $apiKey)
                    TextField("Base URL", text: $baseURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Model")) {
                    Picker("Model Seçimi", selection: $selectedModel) {
                        ForEach(popularModels, id: \.self) { model in
                            Text(model == "custom" ? "Özel Model" : model).tag(model)
                        }
                    }
                    .onChange(of: selectedModel) { newValue in
                        isCustomModel = newValue == "custom"
                    }

                    if isCustomModel {
                        TextField("Özel Model ID", text: $customModel)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: customModel) { newValue in
                                if !newValue.isEmpty {
                                    // Normally we might update selectedModel or use a separate key for custom.
                                    // For simplicity in UI, if "custom", we can store it directly or let it sit.
                                }
                            }
                    }
                }

                Section(header: Text("Sistem Promptu")) {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 100)
                }

                Section {
                    Button(action: resetDefaults) {
                        Text("Varsayılanları Geri Yükle")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bitti") {
                        if isCustomModel && !customModel.isEmpty {
                            selectedModel = customModel
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !popularModels.contains(selectedModel) {
                    isCustomModel = true
                    customModel = selectedModel
                    selectedModel = "custom"
                }
            }
        }
    }

    private func resetDefaults() {
        baseURL = "https://ai.ibrahimhalilsezgin.com/v1"
        selectedModel = "ag/gemini-3.6-flash-high"
        systemPrompt = "Sen Türkçe yanıt veren, yardımsever ve hızlı bir kişisel asistansın."
        isCustomModel = false
    }
}

#Preview {
    SettingsView()
}
