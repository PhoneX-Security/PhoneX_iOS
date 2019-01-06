//
// Created by Dusan Klinec on 09.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXMemBIO.h"
#import "openssl/buffer.h"

@interface PEXMemBIO ()
@property (nonatomic) BIO * membio;
@end


@implementation PEXMemBIO {

}

- (id)init {
    self = [super init];
    self.membio = BIO_new(BIO_s_mem());
    if (self.membio == NULL){
        DDLogError(@"MEMBIO: allocation failed");
        return nil;
    }

    return self;
}

- (void) dealloc {
    if (![self isAllocated]){
        return;
    }

    [self freeBuffer];
}

- (id)initWithNSData:(NSData *)data {
    self = [self init];
    if(self){
        int res = [self readDataToMem:data];
        if (!res){
            [self freeBuffer];
            return nil;
        }
    }
    return self;
}

- (BOOL)isAllocated {
    return self.membio!=NULL;
}

- (void)freeBuffer {
   if (![self isAllocated]){
       DDLogError(@"Buffer is already deallocated");
       return;
   }

   BIO_set_close(self.membio, BIO_NOCLOSE); /* So BIO_free() leaves BUF_MEM alone */
   BIO_free(self.membio);
   self.membio=NULL;
}

- (BIO *)getRaw {
    return self.membio;
}

- (int)readDataToMem:(NSData *)src offset:(uint)offset len:(int)len {
    const char * const buf = [src bytes];
    const int bufLen = (int)[src length];

    if (![self isAllocated]){
        DDLogError(@"Buffer is not allocated");
        return 0;
    }

    // If negative length -> full length.
    if (len < 0){
        len = bufLen;
    }

    // Bound check.
    if ((offset + len) > bufLen){
        DDLogError(@"NSData2Bio: Illegal bound specified");
        return 0;
    }

    // Do the stuff.
    int written = BIO_write(self.membio, buf+offset, len);
    if (written != len){
        DDLogError(@"NSData2Bio: Could not write the whole data, written=%d, toWrite=%d", written, len);
        return 0;
    }

    return 1;
}

- (int)readDataToMem:(NSData *)data {
    return [self readDataToMem:data offset:0 len:-1];
}

- (NSData *)exportFromOffset:(uint)offset len:(int)len {
    if (![self isAllocated]){
        DDLogError(@"Buffer is not allocated");
        return nil;
    }

    BUF_MEM *bptr=NULL;
    BIO_get_mem_ptr(self.membio, &bptr);

    // Test if is given request valid.
    if (bptr==NULL){
        DDLogError(@"exportFromOffset: BIO returned null value");
        return nil;
    }

    // If negative length -> full length
    if (len < 0){
        len = bptr->length;
    }

    // Test input parameters
    if ((offset + len) > bptr->length){
        DDLogError(@"exportFromOffset: Illegal bound specified");
        return nil;
    }

    return [NSData dataWithBytes:(bptr->data+offset) length:len];
}

- (NSData *)export {
    return [self exportFromOffset:0 len:-1];
}

- (NSString *)exportAsStringFromOffset:(uint)offset len:(int)len {
    NSData * data = [self exportFromOffset:offset len:len];
    if (data==nil){
        return nil;
    }
    return [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding];
}

- (NSString *)exportAsString {
    NSData * data = [self export];
    if (data==nil){
        return nil;
    }
    return [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding];
}

+ (BIO *)NSData2Bio:(NSData *)src offset:(uint64_t)offset len:(int64_t)len {
    if (src==nil){
        DDLogError(@"NSData2Bio: null argument");
        return nil;
    }

    char const * buf = [src bytes];
    int64_t bufLen = (int64_t)[src length];

    // If negative length -> full length
    if (len < 0){
        len = bufLen;
    }

    // Bound check
    if ((offset + len) > bufLen){
        DDLogError(@"NSData2Bio: Illegal bound specified");
        return nil;
    }

    // Write CSR to the PEM to memory BIO.
    BIO * mem = BIO_new(BIO_s_mem());
    if (mem==NULL){
        DDLogError(@"NSData2Bio: Allocation problem");
        return nil;
    }

    int written = BIO_write(mem, buf+offset, (int) len);
    if (written != (int)len){
        DDLogError(@"NSData2Bio: Could not write the whole data, written=%d, toWrite=%lld", written, len);
        BIO_free(mem);
        return nil;
    }

    return mem;
}

+ (BIO *)NSData2Bio:(NSData *)src {
    return [self NSData2Bio:src offset:0 len:-1];
}

+ (NSData *)Bio2NSData:(BIO *)src offset:(uint64_t)offset len:(int64_t)len {
    BUF_MEM *bptr=NULL;
    BIO_get_mem_ptr(src, &bptr);

    // Test if is given request valid.
    if (bptr==NULL){
        DDLogError(@"Bio2NSData: BIO returned null value");
        return nil;
    }

    // If negative length -> full length
    if (len < 0){
        len = bptr->length;
    }

    // Test input parameters
    if ((offset + len) > bptr->length){
        DDLogError(@"Bio2NSData: Illegal bound specified");
        return nil;
    }

    return [NSData dataWithBytes:(bptr->data+offset) length:(NSUInteger) len];
}

+ (NSData *)Bio2NSData:(BIO *)src {
    return [self Bio2NSData:src offset:0 len:-1];
}

@end