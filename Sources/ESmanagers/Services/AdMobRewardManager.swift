import Foundation
import GoogleMobileAds
import UIKit

final class AdMobRewardManager: NSObject, ObservableObject, GADFullScreenContentDelegate {

    static let shared = AdMobRewardManager()

    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    private var rewardedAd: GADRewardedAd?

    // MARK: - Published state (AnalyticsView が監視)

    @Published var isAdLoaded: Bool = false
    @Published var isLoading:  Bool = false

    private override init() {
        super.init()
        // 初期ロードは ESmanagersApp で GADMobileAds.start 完了後に行う
    }

    // MARK: - Load

    func loadRewardAd() {
        // ロード開始を Main スレッドで通知
        DispatchQueue.main.async { [self] in
            isLoading  = true
            isAdLoaded = false
        }

        GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            DispatchQueue.main.async {
                // 成功・失敗どちらの場合も必ず isLoading = false に戻す
                self?.isLoading = false

                if let error {
                    print("AdMob Load Error: \(error.localizedDescription)")
                    self?.isAdLoaded = false
                    return
                }

                self?.rewardedAd = ad
                self?.rewardedAd?.fullScreenContentDelegate = self
                self?.isAdLoaded = true
                print("[AdMob] Rewarded ad loaded successfully.")
            }
        }
    }

    // MARK: - Show

    func showRewardAd(onReward: @escaping () -> Void) {

        // ① 最前面の ViewController を確実に取得
        guard let topVC = getTopMostViewController() else {
            print("[AdMob] Error: 最前面の ViewController が見つかりません — 状態をリセットします")
            DispatchQueue.main.async { [self] in
                // VC 取得失敗 → ロック画面を「再読み込み」ボタンに戻す
                isAdLoaded = false
                isLoading  = false
            }
            return
        }

        // ② rewardedAd が nil の場合（isAdLoaded が true でも nil になり得る境界ケース対策）
        guard let ad = rewardedAd else {
            print("[AdMob] Error: rewardedAd が nil です — 再ロードします")
            DispatchQueue.main.async { [self] in
                isAdLoaded = false   // ボタンを「再読み込み」状態に戻す
            }
            loadRewardAd()
            return
        }

        // ③ 動画を確実に再生
        //    userDidEarnRewardHandler は Google が「報酬付与確定」と判定した唯一の場所
        ad.present(fromRootViewController: topVC, userDidEarnRewardHandler: {
            let reward = ad.adReward
            print("[AdMob] Reward received — amount: \(reward.amount), type: \(reward.type)")
            onReward()   // ★ 絶対にここでのみ呼ぶ ★
        })
    }

    // MARK: - ViewController 取得（堅牢版）

    private func getTopMostViewController() -> UIViewController? {
        // foreground active な UIWindowScene を優先取得
        let targetScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first

        guard let windowScene = targetScene else { return nil }

        // キーウィンドウを優先、なければ最初のウィンドウ
        let window = windowScene.windows.first(where: { $0.isKeyWindow })
                  ?? windowScene.windows.first

        guard let root = window?.rootViewController else { return nil }

        // presentedViewController を辿って最前面を取得
        var top: UIViewController = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    // MARK: - GADFullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        // 広告が閉じられたら即リセット → 次視聴に備えて再ロード
        rewardedAd = nil
        isAdLoaded = false
        loadRewardAd()
    }

    func ad(_ ad: GADFullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        print("[AdMob] Failed to present: \(error.localizedDescription)")
        rewardedAd = nil
        isAdLoaded = false
        loadRewardAd()
    }
}
