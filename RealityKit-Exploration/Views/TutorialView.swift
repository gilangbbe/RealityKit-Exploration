import SwiftUI

struct TutorialView: View {
    @Binding var showTutorial: Bool
    let onDismiss: (() -> Void)?
    @State private var currentPage = 0
    
    // Convenience initializer for direct dismissal
    init(showTutorial: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
        self._showTutorial = showTutorial
        self.onDismiss = onDismiss
    }
    
    private let tutorialPages = [
        TutorialPage(
            title: "Welcome to Astro Fight!",
            subtitle: "Master the Galaxy",
            content: "Push enemies off the arena to survive waves and earn points. The longer you survive, the stronger you become!",
            icon: "gamecontroller.fill",
            color: .purple
        ),
        TutorialPage(
            title: "Controls",
            subtitle: "Move & Fight",
            content: "• Tap anywhere to show joystick\n• Drag to move your character\n• Push enemies off the platform\n• Collect power-ups and loot boxes",
            icon: "hand.tap.fill",
            color: .blue
        ),
        TutorialPage(
            title: "Enemy Types & Scoring",
            subtitle: "Know Your Enemies",
            content: "• Scout (Phase 1): 50 base points\n• Fighter (Phase 2): 75 base points\n• Warrior (Phase 3): 100 base points\n• Bruiser (Phase 4): 150 base points\n• Elite (Phase 5): 200 base points\n\nScore scales with wave difficulty!",
            icon: "target",
            color: .red
        ),
        TutorialPage(
            title: "Wave System",
            subtitle: "Survive the Onslaught",
            content: "• Clear all enemies to advance\n• Each wave adds more enemies\n• Wave bonus: 60 × wave number\n• Enemies get faster and stronger\n• Choose upgrades between waves\n• Bonus uses diminishing returns",
            icon: "arrow.triangle.2.circlepath",
            color: .orange
        ),
        TutorialPage(
            title: "Power-ups",
            subtitle: "Temporary Boosts",
            content: "Collect loot boxes for power-ups:\n\n⏰ Time Slow: Slows down time\n💥 Shockwave: Push all enemies away\n\nPower-ups get stronger with upgrades!",
            icon: "bolt.fill",
            color: .yellow
        ),
        TutorialPage(
            title: "Upgrades",
            subtitle: "Permanent Improvements",
            content: "Choose upgrades after each wave:\n\n🏃 Speed: Move faster (18% per level)\n💪 Force: Push enemies harder\n⚖️ Resilience: Resist being pushed\n⏱️ Slow Duration: Longer time slow\n💥 Shockwave Force: Stronger shockwave\n\nDiminishing returns apply!",
            icon: "arrow.up.circle.fill",
            color: .green
        ),
        TutorialPage(
            title: "Loot Box Mechanics",
            subtitle: "Interactive Elements",
            content: "• Collect them for power-ups\n• Strategic positioning matters!",
            icon: "cube.fill",
            color: .cyan
        ),
        TutorialPage(
            title: "Survival Tips",
            subtitle: "Master the Arena",
            content: "• Stay near the center of the arena\n• Use enemy momentum against them\n• Time your power-ups strategically\n• Balance speed vs force upgrades",
            icon: "lightbulb.fill",
            color: .mint
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Skip") {
                        showTutorial = false
                        onDismiss?()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                    
                    Text("Tutorial")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(currentPage == tutorialPages.count - 1 ? "Done" : "Next") {
                        if currentPage == tutorialPages.count - 1 {
                            showTutorial = false
                            onDismiss?()
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                .background(Color.black.opacity(0.8))
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<tutorialPages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.vertical, 16)
                
                // Tutorial content
                TabView(selection: $currentPage) {
                    ForEach(0..<tutorialPages.count, id: \.self) { index in
                        TutorialPageView(page: tutorialPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width > 50 && currentPage > 0 {
                                // Swipe right - go to previous page
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage -= 1
                                }
                            } else if value.translation.width < -50 && currentPage < tutorialPages.count - 1 {
                                // Swipe left - go to next page
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            }
                        }
                )
            }
        }
        .onKeyPress(.leftArrow) {
            if currentPage > 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage -= 1
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.rightArrow) {
            if currentPage < tutorialPages.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.escape) {
            showTutorial = false
            onDismiss?()
            return .handled
        }
    }
}

struct TutorialPage {
    let title: String
    let subtitle: String
    let content: String
    let icon: String
    let color: Color
}

struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)
                
                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(page.color)
                    .shadow(color: page.color.opacity(0.5), radius: 10)
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: page.color)
                    .onAppear {
                        // Subtle pulsing animation for the icon
                    }
                
                // Title and subtitle
                VStack(spacing: 10) {
                    Text(page.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(page.subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(page.color)
                        .multilineTextAlignment(.center)
                }
                
                // Content
                Text(page.content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    TutorialView(showTutorial: .constant(true), onDismiss: nil)
}
