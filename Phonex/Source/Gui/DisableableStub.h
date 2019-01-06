//
//  DisableableStub.h
//  Phonex
//
//  Created by Matej Oravec on 05/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

// TODO macro for generating extension for property of the class
// which includes the file

- (bool) enabled
{
    return _enabled;
}

- (void) setEnabled: (const bool) enabled
{
    _enabled = enabled;
    for (UIGestureRecognizer * const recognizer in self.gestureRecognizers)
    {
        recognizer.enabled = enabled;
    }
}