import SwiftUI

struct HomeView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)
                    .padding(.top, AppSpacing.xxxl)

                // Tiles
                VStack(spacing: AppSpacing.lg) {
                    HomeTileView(
                        title: "Quiz",
                        subtitle: "Test your kana knowledge",
                        icon: "pencil.and.list.clipboard",
                        isEnabled: true
                    ) {
                        path.append(AppDestination.quizSetup)
                    }

                    HomeTileView(
                        title: "Study",
                        subtitle: "Browse kana reference tables",
                        icon: "book.pages",
                        isEnabled: true
                    ) {
                        path.append(AppDestination.study)
                    }

                    HomeTileView(
                        title: "Stats",
                        subtitle: "Track your learning progress",
                        icon: "chart.bar.fill",
                        isEnabled: false,
                        badge: "Soon"
                    ) {}
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer(minLength: AppSpacing.xxxl)
            }
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
    }
}
