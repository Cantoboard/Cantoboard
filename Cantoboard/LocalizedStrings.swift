//
//  LocalizedStrings.swift
//  Cantoboard
//
//  Created by Alex Man on 16/10/21.
//

import Foundation

class LocalizedStrings {
    private static func localizedString(_ stringKeyName: String) -> String {
        NSLocalizedString(stringKeyName, bundle: Bundle(for: LocalizedStrings.self), comment: stringKeyName)
    }
    
    static let installCantoboard = localizedString("installCantoboard")
    static let installCantoboard_settings = localizedString("installCantoboard.settings")
    static let installCantoboard_description = localizedString("installCantoboard.description")
    static let installCantoboard_ios15_description = localizedString("installCantoboard.ios15_description")
    
    static let testKeyboard = localizedString("testKeyboard")
    static let testKeyboard_placeholder = localizedString("testKeyboard.placeholder")
    
    static let inputMethodSettings = localizedString("inputMethodSettings")
    static let mixedMode = localizedString("inputMethodSettings.mixedMode")
    static let mixedMode_description = localizedString("inputMethodSettings.mixedMode.description")
    static let numKeyRow = localizedString("inputMethodSettings.numKeyRow")
    static let smartFullStop = localizedString("inputMethodSettings.smartFullStop")
    static let smartFullStop_description = localizedString("inputMethodSettings.smartFullStop.description")
    static let audioFeedback = localizedString("inputMethodSettings.audioFeedback")
    static let tapHapticFeedback = localizedString("inputMethodSettings.tapHapticFeedback")
    static let candidateFontSize = localizedString("inputMethodSettings.candidateFontSize")
    static let candidateFontSize_normal = localizedString("inputMethodSettings.candidateFontSize.normal")
    static let candidateFontSize_large = localizedString("inputMethodSettings.candidateFontSize.large")
    static let symbolShape = localizedString("inputMethodSettings.symbolShape")
    static let symbolShape_half = localizedString("inputMethodSettings.symbolShape.half")
    static let symbolShape_full = localizedString("inputMethodSettings.symbolShape.full")
    static let symbolShape_smart = localizedString("inputMethodSettings.symbolShape.smart")
    static let symbolShape_description = localizedString("inputMethodSettings.symbolShape.description")
    static let smartSymbolShapeDefault = localizedString("mixedInputSettings.smartSymbolShapeDefault")
    static let smartSymbolShapeDefault_half = localizedString("mixedInputSettings.smartSymbolShapeDefault.half")
    static let smartSymbolShapeDefault_full = localizedString("mixedInputSettings.smartSymbolShapeDefault.full")
    static let smartSymbolShapeDefault_description = localizedString("mixedInputSettings.smartSymbolShapeDefault.description")
    
    static let mixedInputSettings = localizedString("mixedInputSettings")
    static let smartSpace = localizedString("mixedInputSettings.smartSpace")
    static let smartSpace_description = localizedString("mixedInputSettings.smartSpace.description")
    
    static let chineseInputSettings = localizedString("chineseInputSettings")
    static let enablePredictiveText = localizedString("chineseInputSettings.enablePredictiveText")
    static let enablePredictiveText_description = localizedString("chineseInputSettings.enablePredictiveText.description")
    static let predictiveTextOffensiveWord = localizedString("chineseInputSettings.predictiveTextOffensiveWord")
    static let predictiveTextOffensiveWord_description = localizedString("chineseInputSettings.predictiveTextOffensiveWord.description")
    static let compositionMode = localizedString("chineseInputSettings.compositionMode")
    static let compositionMode_immediate = localizedString("chineseInputSettings.compositionMode.immediate")
    static let compositionMode_multiStage = localizedString("chineseInputSettings.compositionMode.multiStage")
    static let compositionMode_description = localizedString("chineseInputSettings.compositionMode.description")
    static let spaceAction = localizedString("chineseInputSettings.spaceAction")
    static let spaceAction_nextPage = localizedString("chineseInputSettings.spaceAction.nextPage")
    static let spaceAction_insertCandidate = localizedString("chineseInputSettings.spaceAction.insertCandidate")
    static let spaceAction_insertText = localizedString("chineseInputSettings.spaceAction.insertText")
    static let fullWidthSpace = localizedString("chineseInputSettings.fullWidthSpace")
    static let fullWidthSpace_off = localizedString("chineseInputSettings.fullWidthSpace.off")
    static let fullWidthSpace_shift = localizedString("chineseInputSettings.fullWidthSpace.shift")
    static let fullWidthSpace_description = localizedString("chineseInputSettings.fullWidthSpace.description")
    static let showRomanizationMode = localizedString("chineseInputSettings.showRomanizationMode")
    static let showRomanizationMode_never = localizedString("chineseInputSettings.showRomanizationMode.never")
    static let showRomanizationMode_always = localizedString("chineseInputSettings.showRomanizationMode.always")
    static let showRomanizationMode_onlyInNonCantoneseMode = localizedString("chineseInputSettings.showRomanizationMode.onlyInNonCantoneseMode")
    static let enableCorrector = localizedString("chineseInputSettings.enableCorrector")
    static let enableCorrector_description = localizedString("chineseInputSettings.enableCorrector.description")
    static let toneInputMode = localizedString("chineseInputSettings.toneInputMode")
    static let toneInputMode_vxq = localizedString("chineseInputSettings.toneInputMode.vxq")
    static let toneInputMode_longPress = localizedString("chineseInputSettings.toneInputMode.longPress")
    static let toneInputMode_description = localizedString("chineseInputSettings.toneInputMode.description")
    static let enableHKCorrection = localizedString("chineseInputSettings.enableHKCorrection")
    
    static let englishInputSettings = localizedString("englishInputSettings")
    static let autoCap = localizedString("englishInputSettings.autoCap")
    static let shouldShowEnglishExactMatch = localizedString("englishInputSettings.shouldShowEnglishExactMatch")
    static let englishLocale = localizedString("englishInputSettings.englishLocale")
    static let englishLocale_au = localizedString("englishInputSettings.englishLocale.au")
    static let englishLocale_ca = localizedString("englishInputSettings.englishLocale.ca")
    static let englishLocale_gb = localizedString("englishInputSettings.englishLocale.gb")
    static let englishLocale_us = localizedString("englishInputSettings.englishLocale.us")
    
    static let other = localizedString("other")
    static let other_onboarding = localizedString("other.onboarding")
    static let other_faq = localizedString("other.faq")
    static let other_about = localizedString("other.about")
    
    static let onboarding_skip = localizedString("onboarding.skip")
    static let onboarding_jumpToSettings = localizedString("onboarding.jumpToSettings")
    static let onboarding_done = localizedString("onboarding.done")
    
    static let onboarding_0_heading = localizedString("onboarding.0.heading")
    static let onboarding_0_content = localizedString("onboarding.0.content")
    static let onboarding_1_heading = localizedString("onboarding.1.heading")
    static let onboarding_1_content = localizedString("onboarding.1.content")
    static let onboarding_2_heading = localizedString("onboarding.2.heading")
    static let onboarding_2_content = localizedString("onboarding.2.content")
    static let onboarding_3_heading = localizedString("onboarding.3.heading")
    static let onboarding_3_content = localizedString("onboarding.3.content")
    static let onboarding_4_heading = localizedString("onboarding.4.heading")
    static let onboarding_4_content = localizedString("onboarding.4.content")
    static let onboarding_5_heading = localizedString("onboarding.5.heading")
    static let onboarding_5_content = localizedString("onboarding.5.content")
    static let onboarding_5_footnote = localizedString("onboarding.5.footnote")
    static let onboarding_5_installed_heading = localizedString("onboarding.5.installed.heading")
    static let onboarding_5_installed_content = localizedString("onboarding.5.installed.content")
    
    static let faq_0_question = localizedString("faq.0.question")
    static let faq_0_answer = localizedString("faq.0.answer")
    static let faq_1_question = localizedString("faq.1.question")
    static let faq_1_answer = localizedString("faq.1.answer")
    static let faq_2_question = localizedString("faq.2.question")
    static let faq_2_answer = localizedString("faq.2.answer")
    
    static let about_jyutpingSite = localizedString("about.jyutpingSite")
    static let about_sourceCode = localizedString("about.sourceCode")
    static let about_credit = localizedString("about.credit")
    static let about_telegram = localizedString("about.telegram")
    static let about_email = localizedString("about.email")
    static let about_appStore = localizedString("about.appStore")
}
