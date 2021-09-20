//
//  UnicodeScalar+EastAsianWidth.swift
//  EastAsianWidth
//
//  Created by Yuki Takahashi on 2017/02/14.
//  Copyright © 2017年 waft. All rights reserved.
//
import Foundation

extension UnicodeScalar {

    // MARK: -
    /// East Asian Ambiguous (A)
    /// All characters that can be sometimes wide and sometimes narrow.
    /// Ambiguous characters require additional information not contained
    /// in the character code to further resolve their width.
    ///
    /// See: http://unicode.org/reports/tr11/#ED6
    ///      https://github.com/audreyt/Unicode-EastAsianWidth/blob/master/lib/Unicode/EastAsianWidth.pm#L38-L199
    var isEastAsianAmbiguous: Bool {
        switch self.value {
        case 0x00A1...0x00A1: return true
        case 0x00A4...0x00A4: return true
        case 0x00A7...0x00A8: return true
        case 0x00AA...0x00AA: return true
        case 0x00AD...0x00AE: return true
        case 0x00B0...0x00B4: return true
        case 0x00B6...0x00BA: return true
        case 0x00BC...0x00BF: return true
        case 0x00C6...0x00C6: return true
        case 0x00D0...0x00D0: return true
        case 0x00D7...0x00D8: return true
        case 0x00DE...0x00E1: return true
        case 0x00E6...0x00E6: return true
        case 0x00E8...0x00EA: return true
        case 0x00EC...0x00ED: return true
        case 0x00F0...0x00F0: return true
        case 0x00F2...0x00F3: return true
        case 0x00F7...0x00FA: return true
        case 0x00FC...0x00FC: return true
        case 0x00FE...0x00FE: return true
        case 0x0101...0x0101: return true
        case 0x0111...0x0111: return true
        case 0x0113...0x0113: return true
        case 0x011B...0x011B: return true
        case 0x0126...0x0127: return true
        case 0x012B...0x012B: return true
        case 0x0131...0x0133: return true
        case 0x0138...0x0138: return true
        case 0x013F...0x0142: return true
        case 0x0144...0x0144: return true
        case 0x0148...0x014B: return true
        case 0x014D...0x014D: return true
        case 0x0152...0x0153: return true
        case 0x0166...0x0167: return true
        case 0x016B...0x016B: return true
        case 0x01CE...0x01CE: return true
        case 0x01D0...0x01D0: return true
        case 0x01D2...0x01D2: return true
        case 0x01D4...0x01D4: return true
        case 0x01D6...0x01D6: return true
        case 0x01D8...0x01D8: return true
        case 0x01DA...0x01DA: return true
        case 0x01DC...0x01DC: return true
        case 0x0251...0x0251: return true
        case 0x0261...0x0261: return true
        case 0x02C4...0x02C4: return true
        case 0x02C7...0x02C7: return true
        case 0x02C9...0x02CB: return true
        case 0x02CD...0x02CD: return true
        case 0x02D0...0x02D0: return true
        case 0x02D8...0x02DB: return true
        case 0x02DD...0x02DD: return true
        case 0x02DF...0x02DF: return true
        case 0x0300...0x036F: return true
        case 0x0391...0x03A9: return true
        case 0x03B1...0x03C1: return true
        case 0x03C3...0x03C9: return true
        case 0x0401...0x0401: return true
        case 0x0410...0x044F: return true
        case 0x0451...0x0451: return true
        case 0x2010...0x2010: return true
        case 0x2013...0x2016: return true
        case 0x2018...0x2019: return true
        case 0x201C...0x201D: return true
        case 0x2020...0x2022: return true
        case 0x2024...0x2027: return true
        case 0x2030...0x2030: return true
        case 0x2032...0x2033: return true
        case 0x2035...0x2035: return true
        case 0x203B...0x203B: return true
        case 0x203E...0x203E: return true
        case 0x2074...0x2074: return true
        case 0x207F...0x207F: return true
        case 0x2081...0x2084: return true
        case 0x20AC...0x20AC: return true
        case 0x2103...0x2103: return true
        case 0x2105...0x2105: return true
        case 0x2109...0x2109: return true
        case 0x2113...0x2113: return true
        case 0x2116...0x2116: return true
        case 0x2121...0x2122: return true
        case 0x2126...0x2126: return true
        case 0x212B...0x212B: return true
        case 0x2153...0x2154: return true
        case 0x215B...0x215E: return true
        case 0x2160...0x216B: return true
        case 0x2170...0x2179: return true
        case 0x2190...0x2199: return true
        case 0x21B8...0x21B9: return true
        case 0x21D2...0x21D2: return true
        case 0x21D4...0x21D4: return true
        case 0x21E7...0x21E7: return true
        case 0x2200...0x2200: return true
        case 0x2202...0x2203: return true
        case 0x2207...0x2208: return true
        case 0x220B...0x220B: return true
        case 0x220F...0x220F: return true
        case 0x2211...0x2211: return true
        case 0x2215...0x2215: return true
        case 0x221A...0x221A: return true
        case 0x221D...0x2220: return true
        case 0x2223...0x2223: return true
        case 0x2225...0x2225: return true
        case 0x2227...0x222C: return true
        case 0x222E...0x222E: return true
        case 0x2234...0x2237: return true
        case 0x223C...0x223D: return true
        case 0x2248...0x2248: return true
        case 0x224C...0x224C: return true
        case 0x2252...0x2252: return true
        case 0x2260...0x2261: return true
        case 0x2264...0x2267: return true
        case 0x226A...0x226B: return true
        case 0x226E...0x226F: return true
        case 0x2282...0x2283: return true
        case 0x2286...0x2287: return true
        case 0x2295...0x2295: return true
        case 0x2299...0x2299: return true
        case 0x22A5...0x22A5: return true
        case 0x22BF...0x22BF: return true
        case 0x2312...0x2312: return true
        case 0x2460...0x24E9: return true
        case 0x24EB...0x254B: return true
        case 0x2550...0x2573: return true
        case 0x2580...0x258F: return true
        case 0x2592...0x2595: return true
        case 0x25A0...0x25A1: return true
        case 0x25A3...0x25A9: return true
        case 0x25B2...0x25B3: return true
        case 0x25B6...0x25B7: return true
        case 0x25BC...0x25BD: return true
        case 0x25C0...0x25C1: return true
        case 0x25C6...0x25C8: return true
        case 0x25CB...0x25CB: return true
        case 0x25CE...0x25D1: return true
        case 0x25E2...0x25E5: return true
        case 0x25EF...0x25EF: return true
        case 0x2605...0x2606: return true
        case 0x2609...0x2609: return true
        case 0x260E...0x260F: return true
        case 0x2614...0x2615: return true
        case 0x261C...0x261C: return true
        case 0x261E...0x261E: return true
        case 0x2640...0x2640: return true
        case 0x2642...0x2642: return true
        case 0x2660...0x2661: return true
        case 0x2663...0x2665: return true
        case 0x2667...0x266A: return true
        case 0x266C...0x266D: return true
        case 0x266F...0x266F: return true
        case 0x273D...0x273D: return true
        case 0x2776...0x277F: return true
        case 0xE000...0xF8FF: return true
        case 0xFE00...0xFE0F: return true
        case 0xFFFD...0xFFFD: return true
        case 0xE0100...0xE01EF: return true
        case 0xF0000...0xFFFFD: return true
        case 0x100000...0x10FFFD: return true
        default:
            return false
        }
    }

    /// East Asian Halfwidth (H)
    /// All characters that are explicitly defined as Halfwidth in the
    /// Unicode Standard by having a compatibility decomposition of
    /// type <narrow> to characters elsewhere in the Unicode Standard
    /// that are implicitly wide but unmarked, plus U+20A9 ₩ WON SIGN.
    ///
    /// See: http://unicode.org/reports/tr11/#ED3
    ///      https://github.com/audreyt/Unicode-EastAsianWidth/blob/master/lib/Unicode/EastAsianWidth.pm#L209-L215
    var isEastAsianHalfwidth: Bool {
        switch self.value {
        case 0x20A9...0x20A9: return true
        case 0xFF61...0xFFDC: return true
        case 0xFFE8...0xFFEE: return true
        default:
            return false
        }
    }

    /// East Asian Fullwidth (F)
    /// All characters that are defined as Fullwidth in the Unicode Standard
    /// by having a compatibility decomposition of type <wide> to characters
    /// elsewhere in the Unicode Standard that are implicitly narrow but unmarked.
    ///
    /// See: http://unicode.org/reports/tr11/#ED2
    ///      https://github.com/audreyt/Unicode-EastAsianWidth/blob/master/lib/Unicode/EastAsianWidth.pm#L201-L207
    var isEastAsianFullwidth: Bool {
        switch self.value {
        case 0x3000...0x3000: return true
        case 0xFF01...0xFF60: return true
        case 0xFFE0...0xFFE6: return true
        default:
            return false
        }
    }

    /// East Asian Narrow (Na)
    /// All other characters that are always narrow and have explicit fullwidth
    /// or wide counterparts. These characters are implicitly narrow in East Asian
    /// typography and legacy character sets because they have explicit fullwidth or
    /// wide counterparts. All of ASCII is an example of East Asian Narrow characters.
    ///
    /// See: http://unicode.org/reports/tr11/#ED5
    ///      https://github.com/audreyt/Unicode-EastAsianWidth/blob/master/lib/Unicode/EastAsianWidth.pm#L217-L227
    var isEastAsianNarrow: Bool {
        switch self.value {
        case 0x0020...0x007E: return true
        case 0x00A2...0x00A3: return true
        case 0x00A5...0x00A6: return true
        case 0x00AC...0x00AC: return true
        case 0x00AF...0x00AF: return true
        case 0x27E6...0x27EB: return true
        case 0x2985...0x2986: return true
        default:
            return false
        }
    }

    /// Neutral (Not East Asian):
    /// All other characters. Neutral characters do not occur in legacy East Asian
    /// character sets. By extension, they also do not occur in East Asian typography.
    /// For example, there is no traditional Japanese way of typesetting Devanagari.
    /// Canonical equivalents of narrow and neutral characters may not themselves be
    /// narrow or neutral respectively. For example, U+00C5 Å LATIN CAPITAL LETTER A
    /// WITH RING ABOVE is Neutral, but its decomposition starts with a Narrow character.
    ///
    /// See: http://unicode.org/reports/tr11/#ED7
    ///      https://github.com/audreyt/Unicode-EastAsianWidth/blob/master/lib/Unicode/EastAsianWidth.pm#L229-L400
    var isEastAsianNeutral: Bool {
        switch self.value {
        case 0x0000...0x001F: return true
        case 0x007F...0x00A0: return true
        case 0x00A9...0x00A9: return true
        case 0x00AB...0x00AB: return true
        case 0x00B5...0x00B5: return true
        case 0x00BB...0x00BB: return true
        case 0x00C0...0x00C5: return true
        case 0x00C7...0x00CF: return true
        case 0x00D1...0x00D6: return true
        case 0x00D9...0x00DD: return true
        case 0x00E2...0x00E5: return true
        case 0x00E7...0x00E7: return true
        case 0x00EB...0x00EB: return true
        case 0x00EE...0x00EF: return true
        case 0x00F1...0x00F1: return true
        case 0x00F4...0x00F6: return true
        case 0x00FB...0x00FB: return true
        case 0x00FD...0x00FD: return true
        case 0x00FF...0x0100: return true
        case 0x0102...0x0110: return true
        case 0x0112...0x0112: return true
        case 0x0114...0x011A: return true
        case 0x011C...0x0125: return true
        case 0x0128...0x012A: return true
        case 0x012C...0x0130: return true
        case 0x0134...0x0137: return true
        case 0x0139...0x013E: return true
        case 0x0143...0x0143: return true
        case 0x0145...0x0147: return true
        case 0x014C...0x014C: return true
        case 0x014E...0x0151: return true
        case 0x0154...0x0165: return true
        case 0x0168...0x016A: return true
        case 0x016C...0x01CD: return true
        case 0x01CF...0x01CF: return true
        case 0x01D1...0x01D1: return true
        case 0x01D3...0x01D3: return true
        case 0x01D5...0x01D5: return true
        case 0x01D7...0x01D7: return true
        case 0x01D9...0x01D9: return true
        case 0x01DB...0x01DB: return true
        case 0x01DD...0x0250: return true
        case 0x0252...0x0260: return true
        case 0x0262...0x02C3: return true
        case 0x02C5...0x02C6: return true
        case 0x02C8...0x02C8: return true
        case 0x02CC...0x02CC: return true
        case 0x02CE...0x02CF: return true
        case 0x02D1...0x02D7: return true
        case 0x02DC...0x02DC: return true
        case 0x02DE...0x02DE: return true
        case 0x02E0...0x02FF: return true
        case 0x0374...0x0390: return true
        case 0x03AA...0x03B0: return true
        case 0x03C2...0x03C2: return true
        case 0x03CA...0x0400: return true
        case 0x0402...0x040F: return true
        case 0x0450...0x0450: return true
        case 0x0452...0x10FC: return true
        case 0x1160...0x200F: return true
        case 0x2011...0x2012: return true
        case 0x2017...0x2017: return true
        case 0x201A...0x201B: return true
        case 0x201E...0x201F: return true
        case 0x2023...0x2023: return true
        case 0x2028...0x202F: return true
        case 0x2031...0x2031: return true
        case 0x2034...0x2034: return true
        case 0x2036...0x203A: return true
        case 0x203C...0x203D: return true
        case 0x203F...0x2071: return true
        case 0x2075...0x207E: return true
        case 0x2080...0x2080: return true
        case 0x2085...0x20A8: return true
        case 0x20AA...0x20AB: return true
        case 0x20AD...0x2102: return true
        case 0x2104...0x2104: return true
        case 0x2106...0x2108: return true
        case 0x210A...0x2112: return true
        case 0x2114...0x2115: return true
        case 0x2117...0x2120: return true
        case 0x2123...0x2125: return true
        case 0x2127...0x212A: return true
        case 0x212C...0x214E: return true
        case 0x2155...0x215A: return true
        case 0x215F...0x215F: return true
        case 0x216C...0x216F: return true
        case 0x217A...0x2184: return true
        case 0x219A...0x21B7: return true
        case 0x21BA...0x21D1: return true
        case 0x21D3...0x21D3: return true
        case 0x21D5...0x21E6: return true
        case 0x21E8...0x21FF: return true
        case 0x2201...0x2201: return true
        case 0x2204...0x2206: return true
        case 0x2209...0x220A: return true
        case 0x220C...0x220E: return true
        case 0x2210...0x2210: return true
        case 0x2212...0x2214: return true
        case 0x2216...0x2219: return true
        case 0x221B...0x221C: return true
        case 0x2221...0x2222: return true
        case 0x2224...0x2224: return true
        case 0x2226...0x2226: return true
        case 0x222D...0x222D: return true
        case 0x222F...0x2233: return true
        case 0x2238...0x223B: return true
        case 0x223E...0x2247: return true
        case 0x2249...0x224B: return true
        case 0x224D...0x2251: return true
        case 0x2253...0x225F: return true
        case 0x2262...0x2263: return true
        case 0x2268...0x2269: return true
        case 0x226C...0x226D: return true
        case 0x2270...0x2281: return true
        case 0x2284...0x2285: return true
        case 0x2288...0x2294: return true
        case 0x2296...0x2298: return true
        case 0x229A...0x22A4: return true
        case 0x22A6...0x22BE: return true
        case 0x22C0...0x2311: return true
        case 0x2313...0x2328: return true
        case 0x232B...0x244A: return true
        case 0x24EA...0x24EA: return true
        case 0x254C...0x254F: return true
        case 0x2574...0x257F: return true
        case 0x2590...0x2591: return true
        case 0x2596...0x259F: return true
        case 0x25A2...0x25A2: return true
        case 0x25AA...0x25B1: return true
        case 0x25B4...0x25B5: return true
        case 0x25B8...0x25BB: return true
        case 0x25BE...0x25BF: return true
        case 0x25C2...0x25C5: return true
        case 0x25C9...0x25CA: return true
        case 0x25CC...0x25CD: return true
        case 0x25D2...0x25E1: return true
        case 0x25E6...0x25EE: return true
        case 0x25F0...0x2604: return true
        case 0x2607...0x2608: return true
        case 0x260A...0x260D: return true
        case 0x2610...0x2613: return true
        case 0x2616...0x261B: return true
        case 0x261D...0x261D: return true
        case 0x261F...0x263F: return true
        case 0x2641...0x2641: return true
        case 0x2643...0x265F: return true
        case 0x2662...0x2662: return true
        case 0x2666...0x2666: return true
        case 0x266B...0x266B: return true
        case 0x266E...0x266E: return true
        case 0x2670...0x273C: return true
        case 0x273E...0x2775: return true
        case 0x2780...0x27E5: return true
        case 0x27F0...0x2984: return true
        case 0x2987...0x2E1D: return true
        case 0x303F...0x303F: return true
        case 0x4DC0...0x4DFF: return true
        case 0xA700...0xA877: return true
        case 0xD800...0xDB7F: return true // Surrogate pair. `UnicodeScalar` does not support these values.
        case 0xDB80...0xDBFF: return true // Surrogate pair. `UnicodeScalar` does not support these values.
        case 0xDC00...0xDFFF: return true // Surrogate pair. `UnicodeScalar` does not support these values.
        case 0xFB00...0xFDFD: return true
        case 0xFE20...0xFE23: return true
        case 0xFE70...0xFEFF: return true
        case 0xFFF9...0xFFFC: return true
        case 0x10000...0x1D7FF: return true
        case 0xE0001...0xE007F: return true
        default:
            return false
        }
    }

    /// East Asian Wide (W)
    /// All other characters that are always wide. These characters occur only in
    /// the context of East Asian typography where they are wide characters (such
    /// as the Unified Han Ideographs or Squared Katakana Symbols). This category
    /// includes characters that have explicit halfwidth counterparts, along with
    /// characters that have the UTR51 property Emoji_Presentation, with the exception
    /// of the range U+1F1E6 REGIONAL INDICATOR SYMBOL LETTER A through U+1F1FF
    /// REGIONAL INDICATOR SYMBOL LETTER Z.
    ///
    /// See: http://unicode.org/reports/tr11/#ED4
    /// https://github.com/audreyt/Unicode-EastAsianWidth/blob/master/lib/Unicode/EastAsianWidth.pm#L402-L422
    var isEastAsianWide: Bool {
        switch self.value {
        case 0x1100...0x115F: return true
        case 0x2329...0x232A: return true
        case 0x2E80...0x2FFB: return true
        case 0x3001...0x303E: return true
        case 0x3041...0x33FF: return true
        case 0x3400...0x4DB5: return true
        case 0x4E00...0x9FBB: return true
        case 0xA000...0xA4C6: return true
        case 0xAC00...0xD7A3: return true
        case 0xF900...0xFAD9: return true
        case 0xFE10...0xFE19: return true
        case 0xFE30...0xFE6B: return true
        case 0x20000...0x2A6D6: return true
        case 0x2A6D7...0x2F7FF: return true
        case 0x2F800...0x2FA1D: return true
        case 0x2FA1E...0x2FFFD: return true
        case 0x30000...0x3FFFD: return true
        default:
            return false
        }
    }

    // MARK: -
    var isFullwidthOrAmbiguous: Bool {
        return isEastAsianFullwidth
            || isEastAsianWide
            || isEastAsianAmbiguous
    }

    var isFullwidth: Bool {
        return isEastAsianFullwidth
            || isEastAsianWide
    }

    var isHalfwidthOrAmbiguous: Bool {
        return isEastAsianHalfwidth
            || isEastAsianNarrow
            || isEastAsianNeutral
            || isEastAsianAmbiguous
    }

    var isHalfwidth: Bool {
        return isEastAsianHalfwidth
            || isEastAsianNarrow
            || isEastAsianNeutral
    }
}
