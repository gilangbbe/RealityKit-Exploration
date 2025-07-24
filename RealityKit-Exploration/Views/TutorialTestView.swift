import SwiftUI

// Simple test view to verify tutorial integration
struct TutorialTestView: View {
    @State private var showTutorial = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("Tutorial Test")
                    .foregroundColor(.white)
                    .font(.title)
                
                Button("Show Tutorial") {
                    showTutorial = true
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
            }
            
            if showTutorial {
                TutorialView(showTutorial: $showTutorial) {
                    showTutorial = false
                }
            }
        }
    }
}

#Preview {
    TutorialTestView()
}
