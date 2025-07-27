//
//  SettingsView.swift
//  Astro Fight
//
//  Created by Copilot on 28/07/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var audioSettings = AudioSettings.shared
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Audio & Game Preferences")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                
                // Audio Settings Section
                VStack(spacing: 20) {
                    // Section Header
                    HStack {
                        Image(systemName: "speaker.wave.3")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Audio Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // BGM Toggle
                    SettingsToggleRow(
                        title: "Background Music",
                        subtitle: "Game soundtrack and ambient music",
                        icon: "music.note",
                        isOn: $audioSettings.isBGMEnabled,
                        iconColor: .purple
                    )
                    
                    // SFX Toggle
                    SettingsToggleRow(
                        title: "Sound Effects",
                        subtitle: "Combat sounds and UI feedback",
                        icon: "speaker.3",
                        isOn: $audioSettings.isSFXEnabled,
                        iconColor: .orange
                    )
                }
                
                Spacer()
                
                // Back Button
                Button(action: {
                    onBack()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back to Menu")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.6), lineWidth: 3)
                            )
                    )
                    .shadow(color: Color.blue.opacity(0.8), radius: 6, x: 0, y: 0)
                    .shadow(color: Color.blue.opacity(0.8), radius: 12, x: 0, y: 0)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .toggleStyle(CustomToggleStyle(onColor: iconColor))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(iconColor.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

struct CustomToggleStyle: ToggleStyle {
    let onColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? onColor : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

#Preview {
    SettingsView(onBack: {})
}
