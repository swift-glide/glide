//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

public extension String {
  func snakeCased(screaming: Bool = false) -> String {
    guard !isEmpty else { return self }

    var words : [Range<String.Index>] = []

    var wordStart = startIndex
    var searchRange = index(after: wordStart)..<endIndex

    while let upperCaseRange = rangeOfCharacter(
      from: CharacterSet.uppercaseLetters,
      options: [],
      range: searchRange
    ) {
      let untilUpperCase = wordStart..<upperCaseRange.lowerBound
      words.append(untilUpperCase)

      searchRange = upperCaseRange.lowerBound..<searchRange.upperBound

      guard let lowerCaseRange = rangeOfCharacter(
        from: CharacterSet.lowercaseLetters,
        options: [],
        range: searchRange
      ) else {
        wordStart = searchRange.lowerBound
        break
      }

      let nextCharacterAfterCapital = index(after: upperCaseRange.lowerBound)

      if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
        wordStart = upperCaseRange.lowerBound
      } else {
        let beforeLowerIndex = index(before: lowerCaseRange.lowerBound)
        words.append(upperCaseRange.lowerBound..<beforeLowerIndex)
        wordStart = beforeLowerIndex
      }

      searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
    }
    words.append(wordStart..<searchRange.upperBound)
    var result = words.map({ (range) in
      return self[range].lowercased()
    }).joined(separator: "_")

    if screaming {
      result = result.uppercased()
    }

    return result
  }
}
