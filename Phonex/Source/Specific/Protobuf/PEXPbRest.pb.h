// Generated by the protocol buffer compiler.  DO NOT EDIT!

#import "ProtocolBuffers.h"

// @@protoc_insertion_point(imports)

@class PEXPbRESTUploadPost;
@class PEXPbRESTUploadPostBuilder;
#ifndef __has_feature
  #define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif // __has_feature

#ifndef NS_RETURNS_NOT_RETAINED
  #if __has_feature(attribute_ns_returns_not_retained)
    #define NS_RETURNS_NOT_RETAINED __attribute__((ns_returns_not_retained))
  #else
    #define NS_RETURNS_NOT_RETAINED
  #endif
#endif


@interface PexpbRestRoot : NSObject {
}
+ (PBExtensionRegistry*) extensionRegistry;
+ (void) registerAllExtensions:(PBMutableExtensionRegistry*) registry;
@end

@interface PEXPbRESTUploadPost : PBExtendableMessage {
@private
  BOOL hasLength_:1;
  BOOL hasErrorCode_:1;
  BOOL hasMessage_:1;
  BOOL hasNonce2_:1;
  BOOL hasVersion_:1;
  UInt64 length;
  SInt32 errorCode;
  NSString* message;
  NSString* nonce2;
  UInt32 version;
}
- (BOOL) hasVersion;
- (BOOL) hasErrorCode;
- (BOOL) hasMessage;
- (BOOL) hasNonce2;
- (BOOL) hasLength;
@property (readonly) UInt32 version;
@property (readonly) SInt32 errorCode;
@property (readonly, strong) NSString* message;
@property (readonly, strong) NSString* nonce2;
@property (readonly) UInt64 length;

+ (PEXPbRESTUploadPost*) defaultInstance;
- (PEXPbRESTUploadPost*) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (PEXPbRESTUploadPostBuilder*) builder;
+ (PEXPbRESTUploadPostBuilder*) builder;
+ (PEXPbRESTUploadPostBuilder*) builderWithPrototype:(PEXPbRESTUploadPost*) prototype;
- (PEXPbRESTUploadPostBuilder*) toBuilder;

+ (PEXPbRESTUploadPost*) parseFromData:(NSData*) data;
+ (PEXPbRESTUploadPost*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (PEXPbRESTUploadPost*) parseFromInputStream:(NSInputStream*) input;
+ (PEXPbRESTUploadPost*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (PEXPbRESTUploadPost*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (PEXPbRESTUploadPost*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface PEXPbRESTUploadPostBuilder : PBExtendableMessageBuilder {
@private
  PEXPbRESTUploadPost* result;
}

- (PEXPbRESTUploadPost*) defaultInstance;

- (PEXPbRESTUploadPostBuilder*) clear;
- (PEXPbRESTUploadPostBuilder*) clone;

- (PEXPbRESTUploadPost*) build;
- (PEXPbRESTUploadPost*) buildPartial;

- (PEXPbRESTUploadPostBuilder*) mergeFrom:(PEXPbRESTUploadPost*) other;
- (PEXPbRESTUploadPostBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (PEXPbRESTUploadPostBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasVersion;
- (UInt32) version;
- (PEXPbRESTUploadPostBuilder*) setVersion:(UInt32) value;
- (PEXPbRESTUploadPostBuilder*) clearVersion;

- (BOOL) hasErrorCode;
- (SInt32) errorCode;
- (PEXPbRESTUploadPostBuilder*) setErrorCode:(SInt32) value;
- (PEXPbRESTUploadPostBuilder*) clearErrorCode;

- (BOOL) hasMessage;
- (NSString*) message;
- (PEXPbRESTUploadPostBuilder*) setMessage:(NSString*) value;
- (PEXPbRESTUploadPostBuilder*) clearMessage;

- (BOOL) hasNonce2;
- (NSString*) nonce2;
- (PEXPbRESTUploadPostBuilder*) setNonce2:(NSString*) value;
- (PEXPbRESTUploadPostBuilder*) clearNonce2;

- (BOOL) hasLength;
- (UInt64) length;
- (PEXPbRESTUploadPostBuilder*) setLength:(UInt64) value;
- (PEXPbRESTUploadPostBuilder*) clearLength;
@end


// @@protoc_insertion_point(global_scope)