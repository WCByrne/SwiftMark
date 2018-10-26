//
//  Fixtures.swift
//  SwiftMarkTests
//
//  Created by Wesley Byrne on 10/26/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import Foundation

struct TestSource {
    
    static let bold = """
        This should render as *bold*
        """
    
    static var superComplex: String {
        var str = ""
        for _ in 0..<20 {
            str += "\n"
            str += complex
        }
        return str
        
    }
    
    static let complex = """
    # Welcome
    This is a *complex* string the has _many_ variations in it.

    # Header
    ## Header
    ### Header
    #### Header

    ### Styling
    This is *bold*
    This is _italic_
    This is `Code`
    This is ~strike~

    ### Blocks
    Now for the blocks like Code blocks:
    ```
    if (false) {
       // this will never happen
    }
    else {
       // everyone likes it when we end up here!
    }
    ```

    > Note: The code above doesn't do *anything* but this is a cool quote!

    ### Summary
    This is cool stuff
    """
    
}
