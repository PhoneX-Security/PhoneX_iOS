//
// Created by Dusan Klinec on 04.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPEMParser.h"
#import "USAdditions.h"

@implementation PEXPemChunk {

}

@end

@implementation PEXPEMParser {

}

-(id)init {
    if (self = [super init]) {
        _maximalDataSize = 8192;
        _produceDER = NO;
    }
    return self;
}

- (PEXPemChunk *)parsePEM:(char **)src len:(int *)len doMoveSrc:(BOOL)doMoveSrc {
    PEXPemChunk * toReturn = [self parsePEM:(char const **) src len:len];
    if (doMoveSrc && toReturn!=nil && toReturn.success){
        *src = *src + toReturn.bytesRead;
    }

    return toReturn;
}

- (PEXPemChunk *) parsePEM:(char const **)src len: (int*) len {
    char const * b = *src;
    const int ln = *len;

    // BEGIN & END constants.
    const char * begin = "BEGIN";
    const int beginLen = 5;
    const char * cend = "END";
    const int endLen = 3;

    // Automaton states.
    const int STATE_GENERAL=1;
    const int STATE_BEGIN_DASH=2;
    const int STATE_BEGIN_TYPE=4;
    const int STATE_BEGIN_DASH2=5;
    const int STATE_DATA=6;
    const int STATE_END_DASH=8;
    const int STATE_END_TYPE=10;
    const int STATE_END_DASH2=11;
    const int STATE_FINISH=12;
    const int STATE_FAIL=13;

    // Parsing markers for BEGIN, END type description,
    // data counter, string accumulator for base64 encoded data.
    const char * begin_type = NULL;
    int64_t begin_type_len = 0;
    const char * end_type = NULL;
    int64_t end_type_len = 0;
    NSString * nsBeginType = nil;
    NSString * nsEndType   = nil;

    const char * data_start = NULL;
    const char * data_end = NULL;
    uint dataLen=0;
    uint dataValidLen=0;
    int paddingIndicator=0;
    bool paddingInvalid=NO;
    NSMutableString * acc = _produceDER ? [NSMutableString stringWithCapacity:512] : nil;

    // Automaton, state.
    int st = STATE_GENERAL;
    int cn = 0;
    for(; cn<ln && st != STATE_FINISH && st != STATE_FAIL; cn++){
        const char c    = b[cn];
        const char * cs = b+cn;

        switch(st){
            default:
                st = STATE_GENERAL;
                break;

            // General state = not important characters.
            case STATE_GENERAL:
                if (c=='-') {
                    st = STATE_BEGIN_DASH;
                }
                break;

            // Dash characters appeared, might be a start of a PEM encoded entity.
            case STATE_BEGIN_DASH:
                //NSLog(@"BEGIN_DASH");
                if (isalnum((int)c) && strncasecmp(cs, begin, beginLen)==0){
                    //NSLog(@"BEGIN found");
                    st = STATE_BEGIN_TYPE;
                    cn+=beginLen;
                    begin_type = (cn+beginLen+1) > ln ? (const char *) NULL : cs+beginLen+1;
                    continue;
                }
                if (c!=' ' && c!='-'){
                    st = STATE_GENERAL;
                }
                break;

            // -----BEGIN appeared
            case STATE_BEGIN_TYPE:
                //NSLog(@"BEGIN_TYPE");
                if (c=='-'){
                    st = STATE_BEGIN_DASH2;

                    // If begin type was set, complete it. We are at its end right now.
                    if (begin_type!=NULL){
                        begin_type_len = cs - begin_type;
                        if (begin_type_len > 0l && begin_type_len < 30l){
                            nsBeginType = [[NSString alloc] initWithBytes:begin_type length:(NSUInteger)begin_type_len
                                                                 encoding:NSASCIIStringEncoding];
                        } else {
                            begin_type=NULL;
                            begin_type_len=0l;
                        }
                        //NSLog(@"Begin type end, %p %d %@", begin_type, begin_type_len, nsBeginType);
                    }

                } else if (!isalnum((int)c) && c!='#' && c!=' '){
                    st = STATE_GENERAL;
                }
                break;

            // Object type ended, - appeared.
            case STATE_BEGIN_DASH2:
                //NSLog(@"BEGIN_DASH2");
                if (c!='-' && c!=' '){
                    st = STATE_DATA;
                    paddingIndicator=0;
                    paddingInvalid=YES;
                    data_start = cs;
                    data_end = NULL;
                    dataLen=0;
                    dataValidLen=0;
                    continue;
                }
                break;

            // State for reading base64 encoded data.
            case STATE_DATA:
            {
                const bool isAlnum = isalnum((int) c);
                if (c == '-') {
                    // Dash detected - data block probably ends here since - is not in Base64 alphabet.
                    data_end = cn > 0 ? cs - 1 : (const char *) NULL;
                    st = STATE_END_DASH;
                } else if (!isAlnum && c != ' ' && c != '\n' && c != '+' && c != '/' && c != '=') {
                    // Illegal character detected. Reset parsing automaton.
                    st = STATE_GENERAL;
                } else {
                    // Valid Base64 character.
                    dataLen += 1;
                    if (dataLen > _maximalDataSize) {
                        DDLogWarn(@"Data too long, exiting");
                        st = STATE_FAIL;
                        continue;
                    }

                    // Padding indicator - checks base64 padding rules:
                    // Only two = signs are allowed, has to be at the end of the string.
                    if (c == '=') {
                        paddingIndicator += 1;
                    }
                    if (paddingIndicator > 2) {
                        // Third padding = found
                        paddingInvalid = YES;
                    }
                    if (paddingIndicator > 0 && isAlnum) {
                        // Padding was already detected, but
                        paddingInvalid = YES;
                    }

                    // Valid Base64 character, add to accumulator if desired, count number of characters.
                    if (isAlnum || c == '/' || c == '+' || c == '=') {
                        dataValidLen += 1;
                        if (_produceDER && acc != nil) {
                            [acc appendFormat:@"%c", c];
                        }
                    }
                }
                break;
            }

            // Base64 encoded data ended, dash detected. May be END block.
            case STATE_END_DASH:
                //NSLog(@"END_DASH");
                if (isalnum((int)c) && strncasecmp(cs, cend, endLen)==0){
                    st = STATE_END_TYPE;
                    cn+=endLen;
                    end_type = (cn+endLen+1) > ln ? (const char *) NULL : cs+endLen+1;
                    continue;
                }
                if (c!=' ' && c!='-'){
                    st = STATE_GENERAL;
                }
                break;

            // -----END block detected.
            case STATE_END_TYPE:
                //NSLog(@"END_TYPE");
                if (c=='-'){
                    st = STATE_END_DASH2;

                    // If end tag was set, set its end.
                    if (end_type!=NULL){
                        end_type_len = cs - end_type;
                        if (end_type_len > 0l && end_type_len < 30l){
                            nsEndType = [[NSString alloc] initWithBytes:end_type length:(NSUInteger)end_type_len
                                                               encoding:NSASCIIStringEncoding];
                        } else {
                            end_type=NULL;
                            end_type_len=0;
                        }
                        //NSLog(@"Begin type end, %p %d", end_type, end_type_len, nsEndType);
                    }
                } else if (!isalnum((int)c) && c!='#' && c!=' '){
                    st = STATE_GENERAL;
                }
                break;

            // END type parsed, finishing.
            case STATE_END_DASH2:
                //NSLog(@"END_DASH2");
                if ((c!='-' && c!=' ') || cn+1 == ln){
                    //NSLog(@"Parsing finished");

                    // Parsing finished.
                    // Decrement counter, we read something what should be "returned".
                    cn-= c=='\n' ? 1 : 0;
                    st = STATE_FINISH;
                }
                break;
        }

    }

    PEXPemChunk * toRet = [[PEXPemChunk alloc] init];
    [toRet setSuccess:NO];

    // Terminate if the final state is not accepting one.
    if (st!=STATE_FINISH && st!=STATE_END_DASH2){
        return toRet;
    }

    // Terminate if starting and ending tag are not non-null && equal.
    //NSLog(@"Begin tag: %@ end tag %@", nsBeginType, nsEndType);
    if (nsBeginType==nil || nsEndType==nil || ![nsBeginType isEqualToString:nsEndType] || cn<0){
        DDLogWarn(@"Invalid data format, begin and end tags invalid");
        return toRet;
    }

    // If der producing is enabled, decode base64 to a binary form.
    // Length has to be divisible by 4 and padding had to be valid.
    if (_produceDER && acc!=nil && (dataValidLen % 4) == 0 && paddingInvalid){
        [toRet setDer: [NSData dataWithBase64EncodedString:acc]];
    }

    // Parsing was successful - move input parameter after read entry.
    *len = *len - cn;
    *src = *src + cn;
    [toRet setBytesRead:(uint)cn];
    [toRet setHasMoreData:cn < ln];
    [toRet setSuccess:YES];
    [toRet setObjType:nsBeginType];
    [toRet setDataStart:data_start];
    [toRet setDataEnd:data_end];
    [toRet setDataLen:dataLen];
    [toRet setValidDataLen:dataValidLen];
    return toRet;
}

@end