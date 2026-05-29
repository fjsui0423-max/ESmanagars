import Foundation
import GoogleMobileAds
import UIKit

final class AdMobRewardManager: NSObject, ObservableObject, GADFullScreenContentDelegate {

    static let shared = AdMobRewardManager()

    /// テスト用リワード広告ユニットID
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"

    private var rewardedAd: GADRewardedAd?

    private override init() {
        super.init()
        loadRewardAd()
    }

    // MARK: - Load

    func loadRewardAd() {
        GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            if let error {
                print("[AdMob] Rewarded ad failed to load: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            print("[AdMob] Rewarded ad loaded successfully.")
        }
    }

    // MARK: - Show

    /// リワード広告を表示する。
    /// 広告がまだロードされていない場合は即座に onReward() を呼んでフォールバックする。
    func showRewardAd(from viewController: UIViewController, onReward: @escaping () -> Void) {
        guard let ad = rewardedAd else {
            print("[AdMob] Rewarded ad not ready — granting reward immediately as fallback.")
            onReward()
            loadRewardAd()
            return
        }
        ad.present(fromRootViewController: viewController, userDidEarnRewardHandler: onReward)
    }

    // MARK: - GADFullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        rewardedAd = nil
        loadRewardAd()
    }

    func ad(_ ad: GADFullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        print("[AdMob] Rewarded ad failed to present: \(error.localizedDescription)")
        rewardedAd = nil
        loadRewardAd()
    }
}
