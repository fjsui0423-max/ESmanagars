import SwiftUI
import GoogleMobileAds

/// Medium Rectangle (300×250) バナー広告
struct AdMobLargeBannerView: UIViewRepresentable {

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeMediumRectangle)
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"

        // foreground active なシーンのキーウィンドウから rootViewController を取得
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                     ?? windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootVC
        }

        bannerView.load(GADRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
