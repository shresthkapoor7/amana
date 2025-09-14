import SwiftUI

struct SplashScreen: View {
    @AppStorage("isFirstTime") var isFirstTime: Bool = true
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                ZStack {
                    Color.white.edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Spacer()
                        Image("splash1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250, height: 250)
                        
                        Spacer()
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            self.showSplash = false
                        }
                    }
                }
            } else {
                if isFirstTime {
                    WeeksView()
                } else {
                    ContentView()
                }
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
