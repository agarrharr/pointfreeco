import Dependencies
import Models
import Transcripts

public func allBlogPosts() -> [BlogPost] {
  @Dependency(\.envVars.appEnv) var appEnv
  @Dependency(\.date.now) var now

  return
    _allBlogPosts
    .filter {
      appEnv == .production
        ? $0.publishedAt <= now
        : true
    }
}

private let _allBlogPosts: [BlogPost] = [
  post0001_welcome,
  post0002_episodeCredits,
  post0003_ep14Solutions,
  post0004_overtureSetters,
  post0005_stylingWithFunctions,
  post0006_taggedSecondsAndMilliseconds,
  post0007_openSourcingNonEmpty,
  post0008_conditionalCoding,
  post0009_6moAnniversary,
  post0010_studentDiscounts,
  post0011_solutionsToZipExercisesPt1,
  post0012_solutionsToZipExercisesPt2,
  post0013_solutionsToZipExercisesPt3,
  post0014_openSourcingValidated,
  post0015_overtureNowWithZip,
  post0016_announcingSwiftHtml,
  post0017_typeSafeVapor,
  post0018_typeSafeKitura,
  post0019_randomZalgoGenerator,
  post0020_PodcastRSS,
  post0021_howToControlTheWorld,
  post0022_someNewsAboutContramap,
  post0023_openSourcingSnapshotTesting,
  post0024_holidayDiscount,
  post0025_2018YearInReview,
  post0026_html020,
  post0027_openSourcingGen,
  post0028_openSourcingEnumProperties,
  post0029_enterpriseSubscriptions,
  post0030_SwiftUIAndStateManagementCorrections,
  post0031_HigherOrderSnapshotStrategies,
  post0032_AnOverviewOfCombine,
  post0033_CyberMondaySale,
  post0034_TestingSwiftUI,
  post0035_SnapshotTestingSwiftUI,
  post0036_HolidayDiscount,
  post0037_2019YearInReview,
  post0038_openSourcingCasePaths,
  post0039_Referrals,
  post0040_Collections,
  post0041_AnnouncingTheComposableArchitecture,
  post0042_RegionalDiscounts,
  post0043_AnnouncingComposableCoreLocation,
  post0044,
  post0045_OpenSourcingCombinePublishers,
  post0046_AnnouncingComposableCoreMotion,
  post0047_ComposableAlerts,
  post0048_CyberMondaySale,
  post0049_OpenSourcingParsing,
  post0050_EOY2020,
  post0051_2020EOYSale,
  post0052,
  post0053_composableArchitectureTestStoreErgonomics,
  post0054_AnnouncingIsowords,
  post0055_OpenSourcingIsowords,
  post0056_BetterTestingBonanza,
  post0057_tourOfIsowords,
  post0058_WWDCSale,
  post0059_SwitchStore,
  post0060_OpenSourcingIdentifiedCollections,
  post0061_BetterPerformanceBonanza,
  post0062_AnnouncingCustomDump,
  post0063_SaferConciserForms,
  post0064_AppleEvent,
  post0065_PointFreeGifts,
  post0066_AnnouncingSwiftUINavigation,
  post0067_CyberMondaySale,
  post0068_YIR2021,
  post0069_2021EOYSale,
  post0070_UnobtrusiveRuntimeWarnings,
  post0071_ParserBuilders,
  post0072_Backtracking,
  post0073_ParserErrors,
  post0074_ParserPrinters,
  post0075_URLVaporRouting,
  post0076_WWDCSale,
  post0077_XCTUnimplemented,
  post0078_NavigationPath,
  post0079_ConcurrencyRelease,
  post0080_TCAPerformance,
  post0081_ReducerProtocol,
  post0082_AnnouncingClocks,
  post0083_NETS,
  post0084_SwiftUINavRelease,
  post0085_BlackFriday2022,
  post0086_CyberMonday2022,
  post0087_ParsingSwift57,
  post0088_YIR2022,
  post0089_2022EOYSale,
  post0090_2022EOYSaleLastChance,
  post0091_2022EOYSaleLastDay,
  post0092_SwiftDependencies,
  post0094_ModernSwiftUIPart1,
  post0095_ModernSwiftUIPart2,
  post0096_ModernSwiftUIPart3,
  post0097_ModernSwiftUIPart4,
  post0098_ModernSwiftUIPart5,
  post0099_ModernSwiftUIConclusion,
  post0100_Anniversary,
  post0101_WereLive,
  post0102_OurFirstLivestream,
  post0103_TCA1_0Preview,
  post0104_TCANavBeta,
  post0105_TCANavBeta2,
  post0106_TCANavRelease,
  post0107_WWDCSale,
  post0108_WWDCSale,
  post0109_ConcurrencyExtras,
  post0110_WritingReliableAsyncTests,
  post0111_TeamInviteCode,
  post0112_TCA1_0Tour,
  post0113_InlineSnapshotTesting,
  post0114_MacroTesting,
  post0115_MacroTesting020,
  post0116_SwiftSyntaxEcosystem,
  post0117_MacroBonanza,
  post0118_MacroBonanza,
  post0119_MacroBonanza,
  post0120_MacroBonanza,
  post0121_MacroBonanza,
  post0122_BlackFriday,
]
