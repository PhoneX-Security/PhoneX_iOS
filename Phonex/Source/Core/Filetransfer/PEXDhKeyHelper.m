//
// Created by Dusan Klinec on 15.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDhKeyHelper.h"
#import "PEXDbCallLog.h"
#import "PEXCanceller.h"
#import "PEXDbDhKey.h"
#import "hr.h"
#import "PEXTransferProgress.h"
#import "PEXMessageDigest.h"
#import "PEXCryptoUtils.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDH.h"
#import "PEXResCrypto.h"
#import "PEXGenerator.h"
#import "PEXStringUtils.h"
#import "PEXPbFiletransfer.pb.h"
#import "PEXDHKeySignatureGenerator.h"
#import "PEXHybridCipher.h"
#import "PBGeneratedMessage+PEX.h"
#import "PEXFtHolder.h"
#import "PEXAESCipher.h"
#import "PEXCancelledException.h"
#import "PEXMACVerificationException.h"
#import "PEXSignatureException.h"
#import "PEXHmac.h"
#import "PEXUtils.h"
#import "PEXRegex.h"
#import "PEXDHKeyHolder.h"
#import "PEXSecurityCenter.h"
#import "PEXCipher.h"
#import "PEXFileTransferException.h"
#import "PEXStreamedCipher.h"
#import "ZipFile.h"
#import "ZipWriteStream.h"
#import "PEXOutputFunctionStream.h"
#import "ZipReadStream.h"
#import "FileInZipInfo.h"
#import "PEXRingBuffer.h"
#import "PEXPbRest.pb.h"
#import "PEXSipUri.h"
#import "PEXServiceConstants.h"
#import "PEXFtUploader.h"
#import "PEXPrivateKey.h"
#import "PEXFtDownloader.h"
#import "PEXPbUtils.h"
#import "PEXLengthDelimitedInputStream.h"
#import "PEXStreamUtils.h"
#import "PEXFileToSendEntry.h"
#import "PEXSOAPSSLManager.h"
#import "PEXSOAPManager.h"
#import "PEXMergedInputStream.h"
#import "PEXTransferProgressWithBlock.h"
#import "PEXFtUploadParams.h"
#import "PEXDBMessage.h"
#import "PEXMessageManager.h"
#import "PEXGuiFileUtils.h"
#import "PEXAssetLibraryManager.h"
#import "PEXFileTypeHolder.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/CGImageDestination.h>

NSString * PEXFtErrorDomain = @"net.phonex.ft.error";

/**
* Nonce size in bytes. 18B = 24 characters in Base64 encoding.
* More than 2**128 than UUID has.
*/
const int PEX_FT_NONCE_SIZE = 18;

/**
* GetKey & FileTransfer protocol version.
*/
const int PEX_FT_PROTOCOL_VERSION = 1;

/**
* Number of C keys derived from DH agreement.
*/
const int PEX_FT_CI_KEYS_COUNT = 8;

/**
* Number of days to key expiration on server side, after DH was created.
*/
const int PEX_FT_EXPIRATION_SERVER_DAYS = 30;

/**
* Number of days to key expiration in database, after DH was created.
*/
const int PEX_FT_EXPIRATION_DATABASE_DAYS = 60;

/**
* Number of bits for Ci keys.
*/
const int PEX_FT_CI_KEYLEN = 32;

/**
* Number of PBKDF2 iterations for generating Ci keys.
*/
const int PEX_FT_CI_KEY_ITERATIONS = 1024;

const NSUInteger PEX_FT_CI_MAC_MB = 1;
const NSUInteger PEX_FT_CI_ENC_XB = 2;
const NSUInteger PEX_FT_CI_MAC_XB = 3;
const NSUInteger PEX_FT_CI_ENC_META = 4;
const NSUInteger PEX_FT_CI_MAC_META = 5;
const NSUInteger PEX_FT_CI_ENC_ARCH = 6;
const NSUInteger PEX_FT_CI_MAC_ARCH = 7;

/**
* Maximal length of a filename in FileTransferProtocol.
*/
const int PEX_FT_MAX_FILENAME_LEN = 64;

NSString * PEX_FT_FILENAME_REGEX = @"[^a-zA-Z0-9_\\-]";
const int PEX_FT_THUMBNAIL_LONG_EDGE = 800; // pixels at long edge.
const float PEX_FT_THUMBNAIL_QUALITY = 0.8;

const NSUInteger PEX_FT_META_IDX = 0;
const NSUInteger PEX_FT_ARCH_IDX = 1;

/**
* URI to the REST server for file upload.
*/
NSString * PEX_FT_REST_UPLOAD_URI = @"/rest/rest/upload";
NSString * PEX_FT_REST_DOWNLOAD_URI = @"/rest/rest/download";

const int PEX_FT_UPLOAD_VERSION = 0;
const int PEX_FT_UPLOAD_NONCE2 = 1;
const int PEX_FT_UPLOAD_USER = 2;
const int PEX_FT_UPLOAD_DHPUB = 3;
const int PEX_FT_UPLOAD_HASHMETA = 4;
const int PEX_FT_UPLOAD_HASHPACK = 5;
const int PEX_FT_UPLOAD_METAFILE = 6;
const int PEX_FT_UPLOAD_PACKFILE = 7;

@class PEXFtUnpackingOptions;
@class PEXFtFileEntry;

@implementation PEXDhKeyHelper {

}

+ (NSArray *)getUploadParams {
    return @[@PEX_FT_UPD_VERSION,
            @PEX_FT_UPD_NONCE2,
            @PEX_FT_UPD_USER,
            @PEX_FT_UPD_DHPUB,
            @PEX_FT_UPD_HASHMETA,
            @PEX_FT_UPD_HASHPACK,
            @PEX_FT_UPD_METAFILE,
            @PEX_FT_UPD_PACKFILE];
}

+ (NSString *)getUploadParam: (NSUInteger) idx {
    return [self getUploadParams][idx];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.readTimeoutMilli = 0;
        self.connectionTimeoutMilli = 0;
    }

    return self;
}

/**
* Throws an exception if a given byte array is null or contains zeros.
* @param input
*/
-(void) throwIfNull: (NSData *) input {
    NSUInteger len = [input length];
    if (input == nil || len == 0) {
        [NSException raise:PEXRuntimeSecurityException format:@"input is nil"];
    }

    BOOL onlyZeros = YES;
    unsigned char * chr = (unsigned char *) [input bytes];
    for (NSUInteger i = 0; i < len; i++){
        if (chr[i] != 0x0){
            onlyZeros = FALSE;
            break;
        }
    }

    if (onlyZeros){
        [NSException raise:PEXRuntimeSecurityException format:@"Given input field contains %lu zero bytes.", (unsigned long) [input length]];
    }
}

- (void) updateProgress: (PEXTransferProgress *) progress partial: (NSNumber *) partial total:(double) total{
    if (progress == nil) return;
    [progress updateTxProgress:partial total:total];
}

/**
* Wrapper for generating DHkeys for the user.
* Prepares data structure.  Main entry point.
*
* @param userSip
* @author ph4r05
*/
-(PEXDHKeyHolder *) generateDHKey {
    hr_ftDHKey * key = [[hr_ftDHKey alloc] init];

    // 1.0 Load certificates for corresponding users
    NSString * const myCertHash = [PEXMessageDigest getCertificateDigestWrap:self.myCert];
    NSString * const sipCertHash = [PEXMessageDigest getCertificateDigestWrap:self.sipCert];

    // 1.1 Generate DH keys with generate().
    PEXDbDhKey * data = [self generateDBDHKey:self.userSip sipCertHash:sipCertHash];

    // 1.2 Hash nonce1, server does not have it in plain
    NSData * shaNonce1 = [PEXMessageDigest sha256Message:data.nonce1];
    NSString * const nonce1Hash = [shaNonce1 base64EncodedStringWithOptions:0];

    key.auxVersion = @(4);
    key.version = @(2);
    key.protocolVersion = @(3);
    key.user = _userSip;
    key.nonce1 = nonce1Hash;
    key.nonce2 = data.nonce2;
    key.creatorCertInfo = myCertHash;
    key.userCertInfo = sipCertHash;

    // 2. Create signatures.
    NSData * dhPubKey = [NSData dataWithBase64EncodedString: data.publicKey];
    [self throwIfNull:dhPubKey];

    PEXPbDhkeySigBuilder * bsig = [[PEXPbDhkeySigBuilder alloc] init];
    [bsig setVersion:PEX_FT_PROTOCOL_VERSION];
    [bsig setB:_mySip]; // B is the key creator
    [bsig setBCertHash: myCertHash];
    [bsig setA:_userSip];
    [bsig setACertHash: sipCertHash];
    [bsig setDhGroupId:(UInt32) [data.groupNumber integerValue]];
    [bsig setGx:dhPubKey];
    [bsig setNonce1:data.nonce1];
    PEXPbDhkeySig * sig1pb = [bsig build];
    PEXPbDhkeySigBuilder * bsig2 = [[[PEXPbDhkeySigBuilder alloc] init] mergeFrom:sig1pb];

    // 2.1 sig1
    NSData * sig1 = [PEXDHKeySignatureGenerator generateDhKeySignature:sig1pb privKey:_privKey];
    [self throwIfNull: sig1];

    // 2.2 sig2
    [bsig2 setNonce2:data.nonce2];
    NSData * sig2 = [PEXDHKeySignatureGenerator generateDhKeySignature:[bsig2 build] privKey:_privKey];
    [self throwIfNull: sig2];

    // 3. Encrypt by hybrid encryption.
    // 3.1. 1st ciphertext
    PEXPbGetDHKeyResponseBodySCipBuilder * scip = [[PEXPbGetDHKeyResponseBodySCipBuilder alloc] init];
    [scip setDhGroupId:(UInt32) [data.groupNumber integerValue]];
    [scip setGx: dhPubKey];
    [scip setNonce1: data.nonce1];
    [scip setSig1: sig1];

    PEXPbGetDHKeyResponseBodySCip * scip1 = [scip build];
    PEXPbHybridEncryption * cip1 = [PEXHybridCipher encrypt:[scip1 writeToCodedNSData] cert:_sipCert];

    // 3.2. 2nd ciphertext
    PEXPbHybridEncryption * cip2 = [PEXHybridCipher encrypt:sig2 cert:_sipCert];

    // 4. SOAP entity
    [key setAEncBlock:[cip1 writeToCodedNSData]];
    // Using hybrid encryption format (everything in AEncBlock), not needed in this version.
    [key setSEncBlock:[NSData data]];
    // Has no use in this version, signature is encrypted in AEncBlock.
    [key setSig1: [NSData data]];
    // Signature 2, for 4th message of the protocol. Using hybrid encryption.
    [key setSig2: [cip2 writeToCodedNSData]];

    // Set expiration date for server side
    [key setExpires:[NSDate dateWithTimeIntervalSinceNow:PEX_FT_EXPIRATION_SERVER_DAYS * 24.0 * 60.0 * 60.0]];

    PEXDHKeyHolder * holder = [[PEXDHKeyHolder alloc] init];
    holder.dbKey = data;
    holder.serverKey = key;

    return holder;
}

/**
* Process response of the GetDHKey protocol, 2nd message.
* Requires byte array corresponding to hybrid encryption output.
*
* @param hybridCipher
* @return
*/
-(PEXPbGetDHKeyResponseBodySCip *) getDhKeyResponse: (NSData *) hybridEncryption{
    // 1.0 Read byte array and obtain hybrid encryption.
    PEXPbHybridEncryptionBuilder * bhib = [[PEXPbHybridEncryptionBuilder alloc] init];
    [bhib mergeFromData:hybridEncryption];

    // 2.0 Process by hybrid cipher
    NSData * plaintext = [PEXHybridCipher decrypt:[bhib build] privKey:_privKey];

    // 3.0 reconstruct message from decrypted ciphertext.
    PEXPbGetDHKeyResponseBodySCipBuilder * bresp = [[PEXPbGetDHKeyResponseBodySCipBuilder alloc] init];
    [bresp mergeFromData:plaintext];
    return [bresp build];
}

/**
* Process getPart2Response message, decrypts signature2.
*
* @param hybridEncryption
* @return
*/
-(NSData *) getDhPart2Response: (NSData *) hybridEncryption{
    // 1.0 Read byte array and obtain hybrid encryption.
    PEXPbHybridEncryptionBuilder * bhib = [[PEXPbHybridEncryptionBuilder alloc] init];
    [bhib mergeFromData:hybridEncryption];

    // 2.0 Process by hybrid cipher
    return [PEXHybridCipher decrypt:[bhib build] privKey:_privKey];
}

/**
* Verifies signature from the GetDHKey protocol.
* If nonce2 is null, it verifies sig1 otherwise sig2.
*
* Uses mySip and userSip (same for certificates) in the order
* assuming mySip is ID of the requesting side, userSip is the ID
* of the user that generated this signature.
*
* @param resp
* @return
*/
-(BOOL) verifySig1: (PEXPbGetDHKeyResponseBodySCip *) resp nonce2: (NSString *) nonce2 signature: (NSData *) signature {
    // 1.0 Load certificates for corresponding users
    NSString * myCertHash = [PEXMessageDigest getCertificateDigestWrap:_myCert];
    NSString * sipCertHash = [PEXMessageDigest getCertificateDigestWrap:_sipCert];

    // 2. Create signatures.
    PEXPbDhkeySigBuilder * bsig = [[PEXPbDhkeySigBuilder alloc] init];
    [bsig setVersion: PEX_FT_PROTOCOL_VERSION];
    [bsig setA: _mySip];
    [bsig setACertHash: myCertHash];
    [bsig setB: _userSip];	// B is the signature creator
    [bsig setBCertHash: sipCertHash];
    [bsig setDhGroupId: resp.dhGroupId];
    [bsig setGx: resp.gx];
    [bsig setNonce1: resp.nonce1];
    if (nonce2 != nil){
        [bsig setNonce2: nonce2];
    }

    return [PEXDHKeySignatureGenerator verifyDhKeySignature:[bsig build] signature:signature cert:_sipCert];
}

/**
* Generates nonce for the protocol with specific size.
*
* @return
* @author ph4r05
*/
-(NSData *) generateNonce {
    return [PEXCryptoUtils secureRandomData:nil len:PEX_FT_NONCE_SIZE amplifyWithArc:YES];
}

/**
* Generates DH key pair from the given group.
* @param groupId
* @return
*/
-(PEXDH *) generateKeyPair: (int) groupId {
    PEXDH * dh = [self loadDHParameterSpec:groupId];
    if (dh == nil){
        [NSException raise:PEXRuntimeSecurityException format:@"cannot load DH parameters"];
    }

    int res = [PEXGenerator generateDhKeyPair:[dh getRaw]];
    if (res != 1){
        [NSException raise:PEXRuntimeSecurityException format:@"cannot egnerate DH key"];
    }

    return dh;
}

/**
* Creates DiffieHellman shared key.
* Sorry for small "D", Diffie should be with big D, but naming convention...
*
* @param pair
* @param gx
*/
-(NSData *) diffieHelman: (PEXDH *) pair pubKey: (PEXDH *) gx {
    if (pair == nil || ![pair isAllocated]) {
        DDLogError(@"Pair is nil");
        return nil;
    }

    if (gx == nil || ![gx isAllocated] || gx.getRaw == NULL || gx.getRaw->pub_key == NULL){
        DDLogError(@"Public key cannot be used");
        return nil;
    }

    return [PEXCryptoUtils computeDH:pair.getRaw pubKey:gx.getRaw->pub_key];
}

/**
* Generate and store new DH key pair for particular sip user in contact list.
*
* @param sip
* @return true on success, otherwise false* @author miroc
*/
-(PEXDbDhKey *) generateDBDHKey: (NSString *) sip sipCertHash:(NSString *)sipCertHash {
    // we randomly pick up a prime group (from pregenerated set) from which DH parameters are derived
    int groupId = arc4random_uniform(256) + 1;

    // Generate DH key
    PEXDH * aPair = [self generateKeyPair:groupId];

    // Generate nonces
    NSData * nonce1 = [self generateNonce];
    NSData * nonce2 = [self generateNonce];

    // Store to DB
    PEXDbDhKey * data = [[PEXDbDhKey alloc] init];
    data.privateKey = [[PEXCryptoUtils exportDHPrivateKeyToDER:aPair.getRaw] base64EncodedStringWithOptions:0];
    data.publicKey  = [[PEXCryptoUtils exportDHPublicKeyToDER:aPair.getRaw] base64EncodedStringWithOptions:0];
    data.groupNumber = @(groupId);
    data.sip = sip;
    data.dateCreated = [NSDate date];
    data.nonce1 = [nonce1 base64EncodedStringWithOptions:0];
    data.nonce2 = [nonce2 base64EncodedStringWithOptions:0];
    data.aCertHash = sipCertHash;
    data.dateExpire = [NSDate dateWithTimeIntervalSinceNow:(PEX_FT_EXPIRATION_DATABASE_DAYS * 24.0 * 60.0 * 60.0)];

    // Insert new key to the database.
    [[PEXDbAppContentProvider instance] insert:[PEXDbDhKey getURI] contentValues:[data getDbContentValues]];

    DDLogVerbose(@"Stored DH object to database; detail=[%@]", data);
    return data;
}

/**
* Loads specific DHkey from the database.
* Sip can be null, in that case only nonce2 is used for search.
*
* @param nonce2
* @param sip
* @return
*/
-(PEXDbDhKey *) loadDHKey: (NSString *) nonce2 sip:(NSString *) sip {
    return [PEXDbDhKey loadDHKey:nonce2 sip:sip cr:[PEXDbAppContentProvider instance]];
}

/**
* Removes all DH keys for particular user.
*
* @param sip
* @return
*/
-(int) removeDHKeysForUser: (NSString *) sip{
    return [PEXDbDhKey removeDHKeysForUser:sip cr:[PEXDbAppContentProvider instance]];
}

/**
* Removes a DHKey with given nonce2
*
* @param sip
* @return
*/
-(BOOL) removeDHKey: (NSString *) nonce2{
    return [PEXDbDhKey removeDHKey:nonce2 cr:[PEXDbAppContentProvider instance]];
}

/**
* Removes a DHKey with given nonce2s
*
* @param sip
* @return
*/
-(int) removeDHKeys: (NSArray *) nonces {
    return [PEXDbDhKey removeDHKeys:nonces cr:[PEXDbAppContentProvider instance]];
}

/**
* Removes DH keys that are either a) older than given date
* OR b) does not have given certificate hash OR both OR just
* equals the sip.
*
* Returns number of removed entries.
*
* @param sip
* @param olderThan
* @param certHash
* @return
*/
-(int) removeDHKeys: (NSString *) sip olderThan: (NSDate *) olderThan certHash: (NSString *) certHash{
    return [self removeDHKeys:sip olderThan:olderThan certHash:certHash expirationLimit:nil];
}

/**
* Removes DH keys that are either a) older than given date
* OR b) does not have given certificate hash OR both OR just
* equals the sip.
*
* Returns number of removed entries.
*
* @param sip
* @param olderThan
* @param certHash
* @param expirationLimit
* @return
*/
-(int) removeDHKeys: (NSString *) sip olderThan: (NSDate *) olderThan certHash: (NSString *) certHash
    expirationLimit: (NSDate *) expirationLimit
{
    return [PEXDbDhKey removeDHKeys:sip olderThan:olderThan certHash:certHash expirationLimit:expirationLimit cr:[PEXDbAppContentProvider instance]];
}

/**
* Returns list of a nonce2s for ready DH keys. If
* sip is not null, for a given user, otherwise for
* everybody.
*
* @param sip OPTIONAL
* @return
*/
-(NSArray *) getReadyDHKeysNonce2: (NSString *) sip {
    return [PEXDbDhKey getReadyDHKeysNonce2:sip cr:[PEXDbAppContentProvider instance]];
}

/**
* Converts database DHKey entry to DH Key pair.
*
* @param data
* @return
*/
-(PEXDH *) getKeyPair: (PEXDbDhKey *) data {
    if (data == nil || [PEXStringUtils isEmpty:data.privateKey]){
        DDLogError(@"Empty data, cannot reconstruct key pair");
        return nil;
    }

    NSData * privDer = [NSData dataWithBase64EncodedString:data.privateKey];
    return [PEXCryptoUtils importDHFromDER:privDer];
}

/**
* Reconstructs DH PublicKey from byte representation.
*
* @param pk
* @return
*/
-(PEXDH *) getPubKeyFromByte: (NSData *) pk{
    return [PEXCryptoUtils importDHPubFromDER:pk];
}

/**
* Reconstructs DH PrivKey from byte representation.
*
* @param pk
* @return
*/
-(PEXDH *) getPrivKeyFromByte: (NSData *) pk{
    return [PEXCryptoUtils importDHFromDER:pk];
}

/**
* Load DH PARAMETER from file assets/dh_groups/dhparam_4096_1_0<groupNumber>.pem
*
* @param groupNumber should be between 001-256
* @return
* @author miroc
*/
-(PEXDH *) loadDHParameterSpec: (int) groupNumber{
    @try {
        NSData * groupData = [PEXResCrypto loadDHGroupId: groupNumber];
        if (groupData == nil){
            [NSException raise:PEXCryptoException format:@"Empty group data"];
        }

        DH * dh = [PEXCryptoUtils importDHParamsFromPEM:NULL pem:groupData];
        if (dh == NULL){
            [NSException raise:PEXCryptoException format:@"Empty DH parameters"];
        }

        return [[PEXDH alloc] initWith:dh];
    } @catch (NSException * e) {
        DDLogError(@"Problem while working with dhparam assets file, exception=%@", e);
        return nil;
    }
}

/**
* Initializes file transfer protocol holder.
* Generates all necessary components for the FileTransfer protocol.
* Used if you are in the role of a sender.
*
* Procedure assumes client has executed GetDHKey protocol and has:
* a) DHKey from message 2.
* b) nonce2 obtained from message 4.
*
* Function generates DH keys needed for file transfer. Function ends up by generating
* X_B, Enc(X_B), MAC(Enc(X_B)).
*
* Function requires: rand, userSip, remoteSip, certificates, private key (for producing signature).
*
* @param nonce2 - byte representation of nonce2.
* @return
*/
-(PEXFtHolder *) createFTHolder: (PEXPbGetDHKeyResponseBodySCip *) body nonce2: (NSData *) nonce2 {
    // Following the protocol description
    PEXFtHolder * holder = [[PEXFtHolder alloc] init];
    holder.nonce2 = nonce2;
    holder.nonce1 = body.nonce1;

    // 1.1 saltb
    holder.saltb = [self generateNonce];

    // 1.2 nonceb
    holder.nonceb = [self generateNonce];

    // 1.3 generate random key pair
    holder.kp = [self generateKeyPair:(int) body.dhGroupId];

    // 1.4 compute DH shared key
    PEXDH * dhRemotePublic = [self getPubKeyFromByte:body.gx];
    holder.c = [self diffieHelman:holder.kp pubKey:dhRemotePublic];

    // 1.5 compute salt1 = hash(saltB XOR nonce1)
    holder.salt1 = [self computeSalt1:holder.saltb nonce1:[NSData dataWithBase64EncodedString: body.nonce1]];

    // Check if some of given values are not null - would signalize serious bug.
    [self throwIfNull: holder.nonce2];
    [self throwIfNull: holder.saltb];
    [self throwIfNull: holder.nonceb];
    [self throwIfNull: holder.c];
    [self throwIfNull: holder.salt1];

    // 1.6 ci
    [self computeCi:holder];

    // 1.7 MB = MAC_{c_1}(version || B || hash(B_{crt}) || A || hash(A_{crt}) || dh\_group\_id || g^x || g^y || g^{xy} || nonce_1 || nonce_2 || nonce_B)
    NSString * myCertHash  = [PEXMessageDigest getCertificateDigestWrap:_myCert];
    NSString * sipCertHash = [PEXMessageDigest getCertificateDigestWrap:_sipCert];

    PEXPbUploadFileToMacBuilder * mb = [[PEXPbUploadFileToMacBuilder alloc] init];
    [mb setVersion: PEX_FT_PROTOCOL_VERSION];
    [mb setB: _userSip];
    [mb setBCertHash: sipCertHash];
    [mb setA: _mySip];
    [mb setACertHash: myCertHash];
    [mb setDhGroupId: body.dhGroupId];
    [mb setGx: body.gx];
    [mb setGy: [holder getGyData]];
    [mb setGxy: holder.c];
    [mb setNonce1: body.nonce1];
    [mb setNonce2: [nonce2 base64EncodedStringWithOptions:0]];
    [mb setNonceb: holder.nonceb];

    // 1.7.2 generate MAC over UploadFileToMac.
    holder.MB = [PEXCryptoUtils hmac:[[mb build] writeToCodedNSData] key:holder.ci[PEX_FT_CI_MAC_MB]];

    // 1.8 XB = B, nonceb, sig(Mb)
    // 1.8.1 generate signature on Mb
    NSData * sig = [PEXCryptoUtils sign:holder.MB key:[PEXPrivateKey keyWithKey: _privKey] error:nil];

    PEXPbUploadFileXbBuilder * bXB = [[PEXPbUploadFileXbBuilder alloc] init];
    [bXB setB: _userSip];
    [bXB setNonceb: holder.nonceb];
    [bXB setSig: sig];
    holder.XB = [bXB build];

    // 2.0 Encrypt XB
    holder.encXB = [PEXAESCipher encrypt:[holder.XB writeToCodedNSData] password:holder.ci[PEX_FT_CI_ENC_XB] doKeyDerivation: NO];

    // 3.0 MAX encXB
    holder.macEncXB = [PEXCryptoUtils hmac:holder.encXB key:holder.ci[PEX_FT_CI_MAC_XB]];

    return holder;
}

-(void) computeCi: (PEXFtHolder *) holder {
    if (holder.ci == nil) {
        holder.ci = [NSMutableArray arrayWithCapacity:PEX_FT_CI_KEYS_COUNT + 1];
    }

    if (holder.ci.count == 0){
        [holder.ci addObject:[NSData data]];
    }

    for(int i = 1; i <= PEX_FT_CI_KEYS_COUNT; i++){
        [holder.ci addObject:[self computeCi:holder.c i:i salt1:holder.salt1 nonce2:holder.nonce2]];
        [self throwIfNull: holder.ci[i]];

        // Is operation cancelled?
        [self checkIfCancelled];
    }
}

/**
* Derives sub-keys from DH master key with PBKDF2
*
* $c_i$ & = $PBKDF2(c \; || \; "\text{pass-}c_i", hash(hash^i(salt_1) || nonce_2), 1024, 256)$
*
* @param c
* @param salt1
* @param nonce2
* @return
*/
-(NSData *) computeCi: (NSData *) c i: (int) i salt1: (NSData *) salt1 nonce2: (NSData *) nonce2{
    // Prepare salt value

    // 1.0 hash^i(salt_1)
    NSData * salt1Hashed = [PEXMessageDigest iterativeHash:salt1 iterations:(unsigned int) i digest:HASH_SHA256];

    // 1.1 hash(hash^i(salt_1) || nonce2)
    NSMutableData * toHash = [NSMutableData dataWithData:salt1Hashed];
    [toHash appendData:nonce2];

    NSData * pbkdfSalt = [PEXMessageDigest sha256:toHash];
    NSString * cString = [c base64EncodedStringWithOptions:0];

    return [PEXCryptoUtils pbkdf2:pbkdfSalt
                         withPass:[NSString stringWithFormat:@"%@||pass-c%d", cString, i]
                   withIterations:PEX_FT_CI_KEY_ITERATIONS
                       withOutLen:PEX_FT_CI_KEYLEN];
}

/**
* Computes salt1=SHA256(saltb XOR nonce1)
*
* @return
*/
-(NSData *) computeSalt1: (NSData *) saltb nonce1: (NSData *) nonce1 {
    NSUInteger minSize = MIN(nonce1.length, saltb.length);
    NSUInteger maxSize = MAX(nonce1.length, saltb.length);
    NSMutableData * toSalt1 = [NSMutableData dataWithLength:(NSUInteger) maxSize];
    void * toSalt1p = [toSalt1 mutableBytes];

    unsigned char const * nonce1p = [nonce1 bytes];
    unsigned char * toSaltp2 = (unsigned char *) toSalt1p;

    memcpy(toSalt1p, [saltb bytes], saltb.length);
    for(int i=0; i < minSize; i++){
        toSaltp2[i] ^= nonce1p[i];
    }

    return [PEXMessageDigest sha256: toSalt1];
}

/**
* Reconstructs ukey from bytes.
* Used in FileTransfer protocol to contain DH public key.
*
* @param ukeyBytes
* @return
*/
-(PEXPbUploadFileKey *) reconstructUkey: (NSData *) ukeyBytes {
    return [PEXPbUploadFileKey parseFromData:ukeyBytes];
}

/**
* Process file transfer message from the sender.
* Reconstructs shared secret to the FTHolder.
*
* Used if you are in the role of a receiver.
*
* Is assumed user has loaded DHOffline record corresponding to this
* user and nonce2.
*
* Function requires: rand, userSip, remoteSip, certificates.
*
* If this function ends without exception thrown it means that:
*   a) Encryption keys are recovered.
*	 b) MAC on the ciphertext XB is verified (ciphertext was not tampered, no chosen ciphertext attack).
*	 c) Signature on the MAC is verified, thus the key exchange was not tampered (sides identity,
*		  public key), is related to this session (nonce2) and is fresh (nonce1, nonce2, nonceb)
*        and the identity of the remote party is verified.
*
* @param data			DHOffline database record corresponding to nonce2.
* @param ukey			uKey read from the REST response.
*
*/
-(PEXFtHolder *) processFileTransfer: (PEXDbDhKey *) data ukey: (NSData *) ukey {
    PEXPbUploadFileKey * u = [self reconstructUkey:ukey];
    return [self processFileTransfer:data saltb:u.saltb gy:u.gy encXB:u.sCiphertext macEncXB:u.mac];
}

/**
* Process file transfer message from the sender.
* Reconstructs shared secret to the FTHolder.
*
* Used if you are in the role of a receiver.
*
* Is assumed user has loaded DHOffline record corresponding to this
* user and nonce2.
*
* Function requires: rand, userSip, remoteSip, certificates.
*
* If this function ends without exception thrown it means that:
*   a) Encryption keys are recovered.
*	 b) MAC on the ciphertext XB is verified (ciphertext was not tampered, no chosen ciphertext attack).
*	 c) Signature on the MAC is verified, thus the key exchange was not tampered (sides identity,
*		  public key), is related to this session (nonce2) and is fresh (nonce1, nonce2, nonceb)
*        and the identity of the remote party is verified.
*
* @param data			DHOffline database record corresponding to nonce2.
* @param saltb			SaltB from the FTUploadMessage.
* @param gy			DH Pub key of a remote party (sender) from the FTUploadMessage.
* @param encXB			Encrypted XB from the FTUploadMessage.
* @param macEncXB		MAC on encrypted XB from the FTUploadMessage.
*/
-(PEXFtHolder *) processFileTransfer: (PEXDbDhKey *) data saltb: (NSData *) saltb gy: (NSData *) gy encXB: (NSData *) encXB macEncXB: (NSData *) macEncXB{
    PEXFtHolder * holder = [[PEXFtHolder alloc] init];

    // 1.0 recover salt1 = hash(saltB XOR nonce1)
    //holder.initFileStruct();
    holder.salt1 = [self computeSalt1:saltb nonce1:[NSData dataWithBase64EncodedString: data.nonce1]];
    holder.saltb = saltb;
    holder.nonce1 = data.nonce1;
    holder.nonce2 = [NSData dataWithBase64EncodedString: data.nonce2];
    [self throwIfNull:holder.salt1];
    [self throwIfNull:holder.saltb];

    // Is operation cancelled?
    [self checkIfCancelled];

    // 1.1 compute ci
    holder.kp = [self getKeyPair:data];
    holder.c  = [self diffieHelman:holder.kp pubKey:[self getPubKeyFromByte:gy]];
    holder.ci = [NSMutableArray arrayWithCapacity: PEX_FT_CI_KEYS_COUNT+1];
    [self throwIfNull: holder.c];

    // Is operation cancelled?
    [self checkIfCancelled];
    [self computeCi:holder];

    // Is operation cancelled?
    [self checkIfCancelled];

    // 1.2 compute MAC on ciphertext and verify it
    holder.macEncXB = [PEXCryptoUtils hmac:encXB key:holder.ci[PEX_FT_CI_MAC_XB]];
    if (![holder.macEncXB isEqualToData:macEncXB]){
        [PEXMACVerificationException raise:PEXRuntimeSecurityException format:@"MAC does not match"];
    }

    // Is operation cancelled?
    [self checkIfCancelled];

    // 1.3 decrypt XB
    holder.encXB = encXB;
    [self throwIfNull:holder.encXB];
    NSData * XBbyte = [PEXAESCipher decrypt:encXB password:holder.ci[PEX_FT_CI_ENC_XB] doKeyDerivation:NO];

    holder.XB = [PEXPbUploadFileXb parseFromData:XBbyte];

    // Is operation cancelled?
    [self checkIfCancelled];

    // 1.4 produce MAC MB = MAC_{c_1}(version || B || hash(B_{crt}) || A || hash(A_{crt}) || dh\_group\_id || g^x || g^y || g^{xy} || nonce_1 || nonce_2 || nonce_B)
    holder.nonceb = holder.XB.nonceb;
    NSString * myCertHash  = [PEXMessageDigest getCertificateDigestWrap:_myCert];
    NSString * sipCertHash = [PEXMessageDigest getCertificateDigestWrap:_sipCert];

    // Is operation cancelled?
    [self checkIfCancelled];

    PEXPbUploadFileToMacBuilder * mb = [[PEXPbUploadFileToMacBuilder alloc] init];
    [mb setVersion: PEX_FT_PROTOCOL_VERSION];
    [mb setB: _mySip];
    [mb setBCertHash: myCertHash];
    [mb setA: _userSip];
    [mb setACertHash: sipCertHash];
    [mb setDhGroupId:(UInt32) [data.groupNumber integerValue]];
    [mb setGx: [NSData dataWithBase64EncodedString: data.publicKey]]; // PubKey of the creator.
    [mb setGy: gy];								   // PubKey of the sender.
    [mb setGxy: holder.c];
    [mb setNonce1: data.nonce1];
    [mb setNonce2: data.nonce2];
    [mb setNonceb: holder.nonceb];		// Obtained by decryption of XB.

    // 1.4.1 generate MAC over UploadFileToMac.
    holder.MB = [PEXCryptoUtils hmac:[[mb build] writeToCodedNSData] key:holder.ci[PEX_FT_CI_MAC_MB]];

    // Is operation cancelled?
    [self checkIfCancelled];

    // 1.5 verify signature
    @try {
        BOOL sigok = [PEXCryptoUtils verify:holder.MB signature:holder.XB.sig certificate:[PEXCertificate certificateWithCert: _sipCert] error:nil];
        if (!sigok) [PEXSignatureException raise:PEXRuntimeSecurityException format:@"Signature is invalid."];
    } @catch (NSException * e){
        [PEXSignatureException raise:PEXRuntimeSecurityException format:@"Exception during signature verification."];
    }

    // Done
    return holder;
}

/**
* Generates HMAC on the file according to the protocol.
* Produces HMAC_{key}(iv || nonce2 || file)
*
* @param is
* @param nonce2
* @return
*/
-(NSData *) generateFTFileMac: (NSInputStream *) is offset: (NSUInteger) offset key: (NSData *) key iv: (NSData *) iv nonce2: (NSData *) nonce2 {
    PEXHmac * mac = [PEXHmac initWithKey:key];

    // MAC iv, nonce2, file
    [mac update:iv];
    [mac update:[[nonce2 base64EncodedStringWithOptions:0] dataUsingEncoding:NSASCIIStringEncoding]];

    NSInteger numBytes;
    NSMutableData * bytesBuff = [NSMutableData dataWithLength:2048];
    uint8_t * bytes = [bytesBuff mutableBytes];

    [PEXUtils dropFirstN:is n:offset c:^BOOL {
        return [self isCancelled];
    }];

    while((numBytes = [is read:bytes maxLength:[bytesBuff length]]) != 0){
        if (numBytes > 0){
            [mac update:(unsigned char const *) bytes len:(size_t) numBytes];
        } else {
            NSError * err = [is streamError];
            DDLogError(@"Stream error: %@", err);
        }

        if ([self isCancelled]){
            [mac destroy];
            return nil;
        }
    }

    NSData * hmac = [mac final];
    [mac destroy]; // deletes key from memory.
    return hmac;
}

/**
* Generates HMAC on the file according to the protocol.
* Produces HMAC_{key}(iv || nonce2 || file)
*
* @param is
* @param nonce2
* @return
*/
-(NSData *) generateFTFileMacFile: (NSString *) file offset: (NSUInteger) offset key: (NSData *) key iv: (NSData *) iv nonce2: (NSData *) nonce2 {
    NSInputStream * is = nil;
    @try {
        is = [NSInputStream inputStreamWithFileAtPath:file];
        [is open];
        return [self generateFTFileMac:is offset: offset key:key iv:iv nonce2:nonce2];
    } @finally {
        [PEXUtils closeSilently:is];
    }
}

/**
* Computes hash on the file according to the protocol.
* Produces hash(iv || mac(iv, nonce2, e) || e). Uses protocol buffers to store IV and MAC.
*
* @param is
* @param nonce2
* @return
*/
-(NSData *) computeFTFileHash: (NSInputStream *) is iv: (NSData *) iv mac: (NSData *) mac {
    PEXMessageDigest * hasher = [PEXMessageDigest digestWithHashFunction:HASH_SHA256];

    // Build {IV + MAC} structure that prepends ciphertext.
    PEXPbUploadFileEncryptionInfoBuilder * b = [[PEXPbUploadFileEncryptionInfoBuilder alloc] init];
    [b setIv: iv];
    [b setMac: mac];

    // Build structure & write to the output stream.
    PEXPbUploadFileEncryptionInfo * info = [b build];
    [hasher update:[info writeDelimitedToCodedNSData]];

    NSInteger numBytes;
    NSMutableData * bytesBuff = [NSMutableData dataWithLength:2048];
    uint8_t * bytes = [bytesBuff mutableBytes];
    while((numBytes = [is read:bytes maxLength:[bytesBuff length]]) > 0){
        if (numBytes > 0){
            [hasher update:(unsigned char const *) bytes len:(size_t) numBytes];
        } else {
            NSError * err = [is streamError];
            DDLogError(@"Stream error: %@", err);
        }

        if (_canceller != nil && [_canceller isCancelled]){
            [hasher destroy];
            return nil;
        }
    }

    NSData * digest = [hasher final];
    [hasher destroy]; // releases context immediately.
    return digest;
}

/**
* Computes hash on the file according to the protocol.
* Produces hash(iv || mac(iv, nonce2, e) || e)
*
* @param is
* @param nonce2
* @return
*/
-(NSData *) computeFTFileHashFile: (NSString *) file iv: (NSData *) iv mac: (NSData *) mac {
    NSInputStream * is = nil;
    @try {
        is = [NSInputStream inputStreamWithFileAtPath:file];
        [is open];
        return [self computeFTFileHash:is iv:iv mac:mac];
    } @finally {
        [PEXUtils closeSilently:is];
    }
}

+(NSString *) sanitizeFileName: (NSString *) fileName{
    // At first get real extension.
    NSMutableString * extension = [[[fileName pathExtension] lowercaseString] mutableCopy];
    NSMutableString * basename = [[[fileName lastPathComponent] stringByDeletingPathExtension] mutableCopy];

    // Truncate file length to the maximal size
    basename = [[PEXUtils getStringMaxLen:basename length:PEX_FT_MAX_FILENAME_LEN] mutableCopy];
    extension = [[PEXUtils getStringMaxLen:extension length:12] mutableCopy];

    // Remove not allowed characters
    NSRegularExpression * nameRegex = [PEXRegex regularExpressionWithString:PEX_FT_FILENAME_REGEX isCaseSensitive:NO error:nil];
    [nameRegex replaceMatchesInString:basename options:0 range:NSMakeRange(0, [basename length]) withTemplate:@""];

    // Same for extension
    NSRegularExpression * extRegex = [PEXRegex regularExpressionWithString:@"[^a-zA-Z0-9_-]" isCaseSensitive:NO error:nil];
    [extRegex replaceMatchesInString:extension options:0 range:NSMakeRange(0, [extension length]) withTemplate:@"_"];

    return [PEXStringUtils isEmpty:extension] ? basename : [NSString stringWithFormat:@"%@.%@", basename, extension];
}

/**
* Sanitize file file name. Cuts filename length
* only to allowed size (preserving extension, converted to lower-case),
* allows only alpha-numerical+{_-} characters.
*
* Same checks holds also for extension.
*
* @param fileName
* @return
*/
-(NSString *) sanitizeFileName: (NSString *) fileName{
    return [PEXDhKeyHelper sanitizeFileName:fileName];
}

/**
* Returns directory where to store generated and received files.
* @return
*/
-(NSString *) getStorageDirectory {
    return [PEXSecurityCenter getFileTransferDocDir];
}

/**
* Returns directory where to store temporary files created during file transfer.
* @return
*/
-(NSString *) getCacheDirectory {
    return [PEXSecurityCenter getFileTransferCacheDir:nil];
}

/**
* Returns directory where to store temporary files created during file transfer.
* @return
*/
+(NSString *) getCacheDirectory {
    return [PEXSecurityCenter getFileTransferCacheDir:nil];
}

+ (NSString *)correctFTFile:(NSString *)path {
    if ([PEXStringUtils isEmpty:path]){
        return nil;
    }

    return [NSString stringWithFormat:@"%@%@", [PEXUtils ensureDirectoryPath:[self getCacheDirectory]], [path lastPathComponent]];
}

/**
* Returns directory where to store thumbnails sent by remote contacts. Should reside in cache directory so they
* are deleted when needed.
*
* @return
*/
-(NSString *) getThumbDirectory {
    return [PEXDhKeyHelper getThumbDirectory];
}

+(NSString *) getThumbDirectory {
    NSString * cacheDir = [PEXSecurityCenter getFileTransferCacheDir:nil];
    NSString * thumbDir = [NSString pathWithComponents:@[cacheDir, @"thumbs"]];
    return [PEXUtils ensureDirectoryPath:thumbDir];
}

/**
* Because each new start of the application means changed application path
*/
+ (NSString *) getRefreshedThumbnailPath: (NSString * const) oldPath
{
    return [[self getThumbDirectory] stringByAppendingPathComponent:oldPath.lastPathComponent];
}

/**
* Encryption and HMAC computation with streamCipher.
* Cipher used: holder.fileCipher[fileIdx], AES-256-CBC.
* HMAC produced: HMAC_{key}(iv || nonce2 || file)
*
* @param is
* @param nonce2
* @return
*/
-(void) encryptAndMacFile: (NSInputStream *) is holder: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx progress: (bytes_processed_block) progressBlock {
    if (fileIdx>=2){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Invalid file index" userInfo:nil];
    }

    NSOutputStream * os = [NSOutputStream outputStreamToFileAtPath:holder.filePath[fileIdx] append:NO];
    [os open];

    // Initialize MAC object to be used in streamed cipher.
    PEXHmac * mac = [PEXHmac initWithKey:holder.ci[fileIdx == PEX_FT_META_IDX ? PEX_FT_CI_MAC_META : PEX_FT_CI_MAC_ARCH]];

    // MAC iv, nonce2, file
    [mac update:holder.fileIv[fileIdx]];
    [mac update:[[holder.nonce2 base64EncodedStringWithOptions:0] dataUsingEncoding:NSASCIIStringEncoding]];

    // Read piped input stream produced by ZIP and encrypt it to the file.
    // Dump AES ciphertext using CipherOutpuStream to the temporary file (reading the ZIP stream).
    PEXStreamedCipher * scip = [PEXStreamedCipher cipherWithCip:holder.fileCipher[fileIdx] canceller:_canceller progressBlock:progressBlock buffSize:4096];
    scip.hmac = mac;

    // Do the cipher step, with cancellation and HMACing.
    [scip doCipher:is os:os];
    [PEXUtils closeSilently:os];

    holder.fileMac[fileIdx] = [mac final];
    [mac destroy]; // deletes key from memory.
}

/**
* Takes CGImageRef and writes its PNG representation to a file.
*/
-(void)savePNGImage:(CGImageRef)imageRef path:(NSString *)path {
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    CGImageDestinationRef dr = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypePNG , 1, NULL);
    CGImageDestinationAddImage(dr, imageRef, NULL);
    CGImageDestinationFinalize(dr);
    CFRelease(dr);
}

/**
* Takes CGImageRef and writes its JPG representation to a file.
*/
-(void)saveJPGImage:(CGImageRef)imageRef path:(NSString *)path quality: (CGFloat) quality {
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
            @(quality), kCGImageDestinationLossyCompressionQuality, nil];

    NSURL *fileURL = [NSURL fileURLWithPath:path];
    CGImageDestinationRef dr = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeJPEG , 1, NULL);
    CGImageDestinationAddImage(dr, imageRef, (__bridge CFDictionaryRef)properties);
    CGImageDestinationFinalize(dr);
    CFRelease(dr);
}

/**
* Attempts to generate a tumbnail from the first page of the PDF.
*/
-(UIImage *) thumbFromPDF: (NSURL *) pdfFileUrl width: (CGFloat) width height: (CGFloat) height {
    CGPDFPageRef page;
    CGRect aRect = CGRectMake(0, 0, width, height); // thumbnail size
    UIGraphicsBeginImageContext(aRect.size);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)pdfFileUrl);

    // Read page & render it to the context.
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, aRect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGContextSetGrayFillColor(context, 1.0, 1.0);
    CGContextFillRect(context, aRect);

    // Grab the first PDF page
    page = CGPDFDocumentGetPage(pdf, 1);
    CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, aRect, 0, false);

    // And apply the transform.
    CGContextConcatCTM(context, pdfTransform);
    CGContextDrawPDFPage(context, page);

    // Create the new UIImage from the context
    UIImage * thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();

    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    CGPDFDocumentRelease(pdf);

    return thumbnailImage;
}

/**
* Reads file and writes it to the given ZIP stream with cancellation & progress monitoring.
* Used to write thumb files to meta zip.
*/
-(void) addFileToZip: (ZipWriteStream *) zipStream file: (NSString *) file progress: (bytes_processed_block) progressBlock {
    // Reopens input stream for encryption.
    NSInputStream * fis = [NSInputStream inputStreamWithFileAtPath: file];
    [fis open];

    // Read file by bytes and write if possible
    NSInteger numBytes = 0;
    NSMutableData * bytesBuff = [NSMutableData dataWithLength:2048];
    uint8_t * bytes = [bytesBuff mutableBytes];
    const NSUInteger bytesLen = [bytesBuff length];
    NSInteger bytesDoneSoFar  = 0;

    [self checkIfCancelled];
    for(;;){
        numBytes = [fis read:bytes maxLength:bytesLen];
        if (numBytes == 0){
            [zipStream finishedWriting];
            break;

        } else if (numBytes < 0){
            DDLogError(@"Error in reading a file %@", file);
            [PEXFileTransferException raise:PEXFileTransferGenericException format:@"File reading error, file=%@", file];
        }

        if ([self isCancelled]){
            break;
        }

        [zipStream writeData:[NSData dataWithBytes:bytes length:(NSUInteger) numBytes]];

        // Progress - easier to monitor input, we know length of the input files...
        bytesDoneSoFar += numBytes;
        if (progressBlock != nil){
            progressBlock(bytesDoneSoFar);
        }
    }

    [PEXUtils closeSilently:fis];
}

/**
* Generates thumbnail for normal file and writes it to the meta thumb zip file.
* Used in processNormalFile.
*/
-(BOOL) generateNormalFileThumb: (PEXFtHolder *) holder fe: (PEXFtFileEntry *) fe {
    NSString * cacheDir = [self getCacheDirectory];
    NSString * tmpThumbJpg = [PEXUtils createTemporaryFileFrom:fe.fname dir:cacheDir withExtension:@"jpg"];
    NSString * tmpThumbPng = [PEXUtils createTemporaryFileFrom:fe.fname dir:cacheDir withExtension:@"png"];
    NSString * tmpThumb = tmpThumbJpg;

    [PEXUtils removeFile:tmpThumbJpg];
    [PEXUtils removeFile:tmpThumbPng];

    uint64_t thumbSize  = 0;
    BOOL thumbGenerated = NO;

    if ([PEXGuiFileUtils canGenerateThumbnail:fe.fname])
    {
        const PEXFileTypeHolder * const typeHolder = [[PEXFileTypeHolder alloc] initWithFilename:fe.file.path];

        CGImageRef thumbRef = [PEXGuiFileUtils generateThumnailForFileUrlCG:fe.file maxSizeInPixels:@(PEX_FT_THUMBNAIL_LONG_EDGE)];
        if (thumbRef != NULL) {
            // For PDF it is usually better to use PNG as a thumb.
            BOOL generateJpgThumb = YES;
            if ([typeHolder isPdf]){
                tmpThumb = tmpThumbPng;
                [self savePNGImage:thumbRef path:tmpThumb];
                generateJpgThumb = NO;

                // Sanity check - is thumbnail smaller than original? If not, generate JPG thumb.
                thumbSize = [PEXUtils fileSize:tmpThumb error:nil];
                if (fe.size > 0 && thumbSize > fe.size){
                    DDLogWarn(@"Thumb size is bigger than original file! thumb: %ld, original: %ld", (long)thumbSize, (long)fe.size);
                    generateJpgThumb = YES;
                }
            }

            if (generateJpgThumb){
                tmpThumb = tmpThumbJpg;
                [self saveJPGImage:thumbRef path:tmpThumb quality:PEX_FT_THUMBNAIL_QUALITY];
            }

            CFRelease(thumbRef);
            thumbGenerated = YES;
        }
    }

    // If there is chance thumbnail was generated, verify whether file realy exists.
    if (thumbGenerated) {
        thumbGenerated = [PEXUtils fileExistsAndIsAfile:tmpThumb];
    }

    if (thumbGenerated) {
        NSString * const thumbnailName = tmpThumb.lastPathComponent;

        thumbSize = [PEXUtils fileSize:tmpThumb error:nil];
        ZipWriteStream *zipMetaStream = [holder.zipFiles[PEX_FT_META_IDX] writeFileInZipWithName:thumbnailName compressionLevel:ZipCompressionLevelNone];
        [self addFileToZip:zipMetaStream file:tmpThumb progress:nil];
        [PEXUtils removeFile:tmpThumb];

        holder.thumbFilesTotalSize += thumbSize;
        fe.metaB.thumbNameInZip = thumbnailName;
        DDLogVerbose(@"Thumbnail generated for filename: %@, len=%llu", fe.fname, thumbSize);
        return YES;
    } else {
        fe.metaB.thumbNameInZip = nil;
        return NO;
    }
}

/**
* Upload process. Takes file specified in PEXFtFileEntry and:
*  a) generates its thumbnail and writes it to the meta zip.
*  b) adds it to the ZIP arch + computes its SH256 hash.
* Progress monitoring.
*/
-(void) processNormalFile: (PEXFtHolder *) holder fe: (PEXFtFileEntry *) fe progress: (bytes_processed_block) progressBlock {
    // Do not add compression since most of the real world formats already do own compression.
    // Beware the library builds a seekable ZIP file (non-stream), so it can fill local header with
    // file size, compressed size and CRC32 after writing file data so streamed reader can read
    // file content with no compression. (With DEFLATE stream reader knows where data stream ends).
    ZipWriteStream * zipArchStream  = [holder.zipFiles[PEX_FT_ARCH_IDX] writeFileInZipWithName:fe.fname compressionLevel:ZipCompressionLevelNone];
    PEXMessageDigest *fileDigest    = [PEXMessageDigest digestWithHashFunction:HASH_SHA256];
    NSString * cacheDir             = [self getCacheDirectory];
    long bytesDoneSoFar = 0;

    // Classical file is processed with input stream.
    NSInputStream *fis = [NSInputStream inputStreamWithURL:fe.file];
    [fis open];

    // Read file by bytes and write if possible
    long numBytes = 0;
    NSMutableData *bytesBuff = [NSMutableData dataWithLength:2048];
    uint8_t *bytes = [bytesBuff mutableBytes];
    const NSUInteger bytesLen = [bytesBuff length];

    // Generate thumb & write it to meta file.
    @try {
        if (fe.doGenerateThumb) {
            fe.size   = [PEXUtils fileSize:fe.file.path error:nil];
            [self generateNormalFileThumb:holder fe:fe];
        }
    } @catch(NSException *e){
        DDLogError(@"Exception during thumbnail generation, exception=%@", e);
        fe.metaB.thumbNameInZip = nil;
    }

    [self checkIfCancelled];
    for (; ;) {
        numBytes = [fis read:bytes maxLength:bytesLen];
        if (numBytes == 0) {
            [zipArchStream finishedWriting];
            break;

        } else if (numBytes < 0) {
            DDLogError(@"Error in reading a file %@", fe.file);
            [PEXFileTransferException raise:PEXFileTransferGenericException format:@"File reading error, file=%@", fe.file];
        }

        if ([self isCancelled]) {
            break;
        }

        [zipArchStream writeData:[NSData dataWithBytes:bytes length:(NSUInteger) numBytes]];
        [fileDigest update:bytes len:(NSUInteger) numBytes];

        // Progress - easier to monitor input, we know length of the input files...
        bytesDoneSoFar += numBytes;
        if (progressBlock != nil) {
            progressBlock(bytesDoneSoFar);
        }
    }

    fe.size   = (uint64_t) bytesDoneSoFar;
    fe.sha256 = [fileDigest final];
    [fileDigest destroy];
    [PEXUtils closeSilently:fis];
}

/**
* Generates thumbnail from asset file, used in processAssetFile: method.
*/
-(BOOL) generateAssetThumb: (PEXFtHolder *) holder fe: (PEXFtFileEntry *) fe asset: (ALAsset *) asset{
    NSString * cacheDir = [self getCacheDirectory];
    CGImageRef thumbRef = [asset aspectRatioThumbnail];
    if (thumbRef == NULL){
        fe.metaB.thumbNameInZip = nil;
        return NO;
    }

    NSString * tmpThumb = [PEXUtils createTemporaryFileFrom:fe.fname dir:cacheDir withExtension:@"jpg"];
    [PEXUtils removeFile:tmpThumb];
    [self saveJPGImage:thumbRef path:tmpThumb quality:PEX_FT_THUMBNAIL_QUALITY];
    uint64_t thumbSize = [PEXUtils fileSize:tmpThumb error:nil];
    if (thumbSize == 0){
        [PEXUtils removeFile:tmpThumb];
        fe.metaB.thumbNameInZip = nil;
        return NO;
    }

    NSString * const thumbnailName = tmpThumb.lastPathComponent;

    ZipWriteStream * zipMetaStream = [holder.zipFiles[PEX_FT_META_IDX] writeFileInZipWithName:thumbnailName compressionLevel:ZipCompressionLevelNone];
    [self addFileToZip:zipMetaStream file:tmpThumb progress:nil];
    [PEXUtils removeFile:tmpThumb];

    holder.thumbFilesTotalSize += thumbSize;
    fe.metaB.thumbNameInZip = thumbnailName;
    return YES;
}

/**
* Upload process. Takes file specified in PEXFtFileEntry which is known to be an asset. Assets cannot be read directly,
*  thus ALAssetsLibrary is used to read it, using provided block.
*  This method:
*  a) generates its thumbnail and writes it to the meta zip.
*  b) adds it to the ZIP arch + computes its SH256 hash.
* Progress monitoring.
*/
-(void) processAssetFile: (PEXFtHolder *) holder fe: (PEXFtFileEntry *) fe assetLib: (ALAssetsLibrary *) assetsLibrary progress: (bytes_processed_block) progressBlock {
    // Do not add compression since most of the real world formats already do own compression.
    // Beware the library builds a seekable ZIP file (non-stream), so it can fill local header with
    // file size, compressed size and CRC32 after writing file data so streamed reader can read
    // file content with no compression. (With DEFLATE stream reader knows where data stream ends).
    ZipWriteStream * zipArchStream    = [holder.zipFiles[PEX_FT_ARCH_IDX] writeFileInZipWithName:fe.fname compressionLevel:ZipCompressionLevelNone];
    PEXMessageDigest *fileDigest      = [PEXMessageDigest digestWithHashFunction:HASH_SHA256];
    NSString * cacheDir               = [self getCacheDirectory];
    NSInteger bytesDoneSoFar          = 0;

    // Processing of the asset file.
    // Async call for file at given URI.
    dispatch_semaphore_t finSem    = dispatch_semaphore_create(0);
    dispatch_time_t tdeadline      = dispatch_time(DISPATCH_TIME_NOW, 100 * 1000000ull);
    __block NSError * assetsError  = nil;
    __weak __typeof(self) weakSelf = self;

    // Load asset from library.
    // TODO use PEXFileData assetDataFromUrl: (requires semaphore passing)
    [[[PEXAssetLibraryManager instance] getAssetLibrary] assetForURL:fe.file
       resultBlock:^(ALAsset *asset) {
           ALAssetRepresentation *rep = [asset defaultRepresentation];
           NSMutableData * buffBytes  = [NSMutableData dataWithLength:8192];
           uint8_t * bytes            = [buffBytes mutableBytes];
           int64_t read               = 0;
           NSError * err = nil;

           // Generate thumb & write it to the meta zip file.
           // TODO: progress monitoring.
           if (fe.doGenerateThumb) {
               [self generateAssetThumb:holder fe:fe asset:asset];
           }

           // Read file, compute sha256 hash, write to arch ZIP file.
           for(; read < fe.size ;){
               NSUInteger curRead = [rep getBytes:bytes fromOffset:read length:[buffBytes length] error:&err];
               if (err != nil || curRead == 0){
                   DDLogError(@"Error in reading file for hash, err=%@", err);
                   [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Error in reading asset"];
               }

               if ([self isCancelled]) {
                   break;
               }

               [zipArchStream writeData:[NSData dataWithBytes:bytes length:(NSUInteger) curRead]];
               [fileDigest update:bytes len:(NSUInteger) curRead];
               read += curRead;

               // Progress - easier to monitor input, we know length of the input files...
               if (progressBlock != nil) {
                   progressBlock(read);
               }
           }

           [zipArchStream finishedWriting];
           fe.sha256 = [fileDigest final];
           [fileDigest destroy];

           dispatch_semaphore_signal(finSem);
       }
      failureBlock:^(NSError *error) {
          assetsError = error;
          DDLogError(@"Error in assets get=%@", error);
          dispatch_semaphore_signal(finSem);
      }
    ];

    // Wait for completion - semaphore indication.
    int waitRes =  [PEXSOAPManager waitWithCancellation:nil doneSemaphore:finSem
                                            semWaitTime:tdeadline timeout:-1.0 doRunLoop:YES
                                            cancelBlock:^BOOL { return [weakSelf isCancelled];}];

    [[PEXAssetLibraryManager instance] releaseAssetLibrary];

    if (assetsError != nil || waitRes == kWAIT_RESULT_CANCELLED){
        DDLogVerbose(@"Error or cancelled");
        [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Maybe cancelled"];
    }
}

/**
* Check a given file name for duplicate.
* If a duplicate is found in mutable set, new non-conflicting one file name is returned.
*/
-(NSString *) checkFileNameDuplicate: (NSMutableSet *) fnames fname: (NSString *) fname didCollide: (BOOL *) didCollide {
    if (![fnames containsObject:[fname lowercaseString]]){
        if (didCollide != NULL){
            *didCollide = NO;
        }
        return fname;
    }

    if (didCollide != NULL){
        *didCollide = YES;
    }

    BOOL success = NO;
    NSString * candidate = [fname stringByDeletingPathExtension];
    NSString * extension = [fname pathExtension];
    NSString * suffix    = [PEXStringUtils isEmpty:extension] ? @"" : [NSString stringWithFormat:@".%@", extension];
    NSString * prefix    = [fname stringByDeletingPathExtension];
    NSInteger idx        = 0;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSRegularExpression * regex    = [PEXRegex regularExpressionWithString:@"^(.+?)_([0-9]+)$" isCaseSensitive:NO error:nil];
    NSRegularExpression * imgRegex = [PEXRegex regularExpressionWithString:@"^IMG_([0-9]+)$" isCaseSensitive:NO error:nil];

    NSRange range = NSMakeRange(0, candidate.length);
    NSArray * m    = [regex    matchesInString:candidate options:0 range:range];
    NSArray * mImg = [imgRegex matchesInString:candidate options:0 range:range];

    // Match only non-image sequences, in order to avoid confusion with sending images.
    if (m!=nil && [m count]>0 && (mImg == nil || [mImg count] < 1)) {
        NSTextCheckingResult * res = m[0];
        prefix =  [PEXRegex getStringAtRange:candidate range:[res rangeAtIndex:1]];
        idx    = [[PEXRegex getStringAtRange:candidate range:[res rangeAtIndex:2]] integerValue];
    }

    for(int retry=0; retry < 100; retry++){
        candidate = [NSString stringWithFormat:@"%@_%02ld%@", prefix, (long)idx + 1, suffix];
        if (![fnames containsObject:[candidate lowercaseString]]){
            success = YES;
            break;
        }
    }

    if (success){
        return candidate;
    }

    // Generate some random name so collision is not probable.
    for(int retry=0; retry < 100; retry++) {
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *newDate = [dateFormatter stringFromDate:[NSDate date]];
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSString *rndPart = [NSString stringWithFormat:@"%@_%@", newDate, [uuid substringToIndex:8]];
        candidate = [NSString stringWithFormat:@"%@%@%@", [fname stringByDeletingPathExtension], rndPart, suffix];
        if (![fnames containsObject:[candidate lowercaseString]]){
            success = YES;
            break;
        }
    }

    return candidate;
}

/**
* Loads data for a file specified by PEXFileToSendEntry.
* Computes its hash, file size, file name, extension.
* If file is from assets, it is handled differently - need to be accessed directly.
*/
-(PEXFtFileEntry *) getFtFileEntry: (PEXFtHolder *) holder fe: (PEXFileToSendEntry *) toSend {
    __block PEXFtFileEntry * fe = [[PEXFtFileEntry alloc] init];
    fe.fEntry = toSend;
    fe.doGenerateThumb = toSend.doGenerateThumbIfPossible;

    if (!toSend.isAsset){
        NSUInteger len = 0;
        fe.file    = toSend.file;
        fe.fname   = [self sanitizeFileName: [toSend.file lastPathComponent]];
        fe.ext     = [[toSend.file lastPathComponent] pathExtension];
        fe.size    = 0; // File size is obtained during file read.
        fe.isAsset = NO;

    } else {
        // Async call for file at given URI.
        dispatch_semaphore_t finSem    = dispatch_semaphore_create(0);
        dispatch_time_t tdeadline      = dispatch_time(DISPATCH_TIME_NOW, 100 * 1000000ull);
        __block NSError * assetsError  = nil;
        __weak __typeof(self) weakSelf = self;

        // Load asset from library.
        [[[PEXAssetLibraryManager instance] getAssetLibrary] assetForURL:toSend.file
           resultBlock:^(ALAsset *asset) {
               ALAssetRepresentation *rep = [asset defaultRepresentation];
               fe.file    = [rep url];
               fe.fname   = [self sanitizeFileName: [[rep filename] lastPathComponent]];
               fe.size    = (uint64_t) [rep size];
               fe.ext     = [fe.fname pathExtension];
               fe.isAsset = YES;
               if ([rep size] < 0){
                   [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Cannot determine asset size."];
               }

               dispatch_semaphore_signal(finSem);
           }
           failureBlock:^(NSError *error) {
               assetsError = error;
               DDLogError(@"Error in assets get=%@", error);
               dispatch_semaphore_signal(finSem);
           }
        ];

        // Wait for completion - semaphore indication.
        int waitRes =  [PEXSOAPManager waitWithCancellation:nil doneSemaphore:finSem
                                                semWaitTime:tdeadline timeout:-1.0 doRunLoop:YES
                                                cancelBlock:^BOOL { return [weakSelf isCancelled];}];

        [[PEXAssetLibraryManager instance] releaseAssetLibrary];

        if (assetsError != nil || waitRes == kWAIT_RESULT_CANCELLED){
            DDLogVerbose(@"Error or cancelled");
            return nil;
        }
    }

    // Prefer from argument.
    if (![PEXStringUtils isEmpty:toSend.prefFileName]){
        fe.fname = [self sanitizeFileName: toSend.prefFileName];
    }

    // Check fname against existing fnames in archive to avoid collisions.
    BOOL fnameCollision = NO;
    fe.fname = [self checkFileNameDuplicate:holder.fnames fname:fe.fname didCollide:&fnameCollision];
    [holder.fnames addObject:[fe.fname lowercaseString]];
    [holder.orderedFnames addObject:fe.fname];
    holder.fnameCollisionFound |= fnameCollision;

    // Build meta information storage.
    fe.metaB = [[PEXPbMetaFileDetailBuilder alloc] init];
    [fe.metaB setExtension:fe.ext];
    [fe.metaB setFileName:fe.fname];
    [fe.metaB setFileSize:fe.size];
    [fe.metaB setXhash:fe.sha256];
    [fe.metaB setThumbNameInZip:fe.fname];
    [fe.metaB setMimeType: toSend.mimeType != nil ? toSend.mimeType : [PEXUtils guessMIMETypeFromExtension:fe.ext]];
    if (toSend.title != nil) {
        [fe.metaB setTitle: toSend.title];
    }
    if (toSend.desc != nil) {
        [fe.metaB setDesc:toSend.desc];
    }
    if (toSend.fileDate != nil) {
        [fe.metaB setFileTimeMilli:(uint64_t) [toSend.fileDate timeIntervalSince1970] * 1000];
    }

    return fe;
}

/**
* Prepares FtHolder for upload, specifying all paths needed during upload phase.
*/
-(void) prepareHolderPaths: (PEXFtHolder *) holder {
    if (holder == nil){
        [PEXFileTransferException raise:PEXRuntimeException format:@"Holder cannot be nil"];
    }

    // Generate IVs & store to FTholder.
    holder.fileIv[PEX_FT_META_IDX] = [PEXCryptoUtils secureRandomData:nil len:AES_BLOCK_SIZE amplifyWithArc:YES];
    holder.fileIv[PEX_FT_ARCH_IDX] = [PEXCryptoUtils secureRandomData:nil len:AES_BLOCK_SIZE amplifyWithArc:YES];

    // Encrypt given data by AES-CBC
    holder.fileCipher[PEX_FT_META_IDX] = [self prepareCipher:holder encryption:YES fileIdx:PEX_FT_META_IDX];
    holder.fileCipher[PEX_FT_ARCH_IDX] = [self prepareCipher:holder encryption:YES fileIdx:PEX_FT_ARCH_IDX];

    NSString * nonce2 = [holder.nonce2 base64EncodedStringWithOptions:0];
    NSString * pathNoce = [PEXDhKeyHelper getFilenameFromBase64:nonce2];
    NSString * cacheDir = [self getCacheDirectory];
    DDLogVerbose(@"Cache dir=[%@]", cacheDir);

    // Create temporary files.
    // Create in external storage - can do it, since files are protected (encrypted content).
    holder.filePath[PEX_FT_META_IDX] = [PEXUtils createTemporaryFile:[NSString stringWithFormat:@"ft_meta_%@_", pathNoce] suffix:@".tmp" dir:cacheDir];
    holder.filePath[PEX_FT_ARCH_IDX] = [PEXUtils createTemporaryFile:[NSString stringWithFormat:@"ft_arch_%@_", pathNoce] suffix:@".tmp" dir:cacheDir];
    NSString * ftMetaFile = holder.filePath[PEX_FT_META_IDX];
    NSString * ftArchFile = holder.filePath[PEX_FT_ARCH_IDX];

    holder.filePackPath[PEX_FT_META_IDX] = [self getFileNameForPacked:PEX_FT_META_IDX nonce2:nonce2];
    holder.filePackPath[PEX_FT_ARCH_IDX] = [self getFileNameForPacked:PEX_FT_ARCH_IDX nonce2:nonce2];
    NSString * zipMetaName = holder.filePackPath[PEX_FT_META_IDX];
    NSString * zipFileName = holder.filePackPath[PEX_FT_ARCH_IDX];

    [PEXUtils removeFile:zipMetaName];
    [PEXUtils removeFile:zipFileName];
    holder.zipFiles[PEX_FT_META_IDX] = [[ZipFile alloc] initWithFileName:zipMetaName mode:ZipFileModeCreate allow64Mode:NO];
    holder.zipFiles[PEX_FT_ARCH_IDX] = [[ZipFile alloc] initWithFileName:zipFileName mode:ZipFileModeCreate allow64Mode:NO];
    DDLogVerbose(@"Temporary files meta=[%@] arch=[%@]", ftMetaFile, ftArchFile);
}

/**
* Builds PEXPbUploadFileKey structure needed for file upload and serializes it to NSData.
* Has to be done before file upload.
*/
-(PEXPbUploadFileKey *) buildUkeyData: (PEXFtHolder *) holder {
    // Construct uKey according to the protocol.
    PEXPbUploadFileKeyBuilder * keyBuilder = [[PEXPbUploadFileKeyBuilder alloc] init];
    [keyBuilder setSaltb:       holder.saltb];
    [keyBuilder setGy:         [holder getGyData]];
    [keyBuilder setSCiphertext: holder.encXB];
    [keyBuilder setMac:         holder.macEncXB];
    PEXPbUploadFileKey * ukey = [keyBuilder build];
    holder.ukeyData           = [ukey writeToCodedNSData];
    return ukey;
}

/**
* Sets files to be sent to the remote party.
* Files have to exist, otherwise IOException is thrown.
* Can append textual title and description, optional.
*
* Generates all needed information to the holder (IVs, MACs,
* file names).
*
* Created files (meta, archive) are placed to externalCacheDir,
* file names are stored in holder. Generated files are E_m, E_p.
* IV and MAC is not prepended to the files - it has to be done manually during sending!
*
* Supports operation cancellation.
*
* @param holder 		Initialized by initFTHolder() method.
*/
-(PEXFtPreUploadFilesHolder *) ftSetFilesToSend: (PEXFtHolder *) holder params: (PEXFtUploadParams *) params {
    if (params == nil || params.files == nil){
        [PEXFileTransferException raise:PEXRuntimeException format:@"Paths cannot be nil"];
    }

    // Prepare holder paths.
    [self prepareHolderPaths:holder];
    NSString * ftMetaFile  = holder.filePath[PEX_FT_META_IDX];
    NSString * ftArchFile  = holder.filePath[PEX_FT_ARCH_IDX];
    NSString * zipMetaName = holder.filePackPath[PEX_FT_META_IDX];
    NSString * zipFileName = holder.filePackPath[PEX_FT_ARCH_IDX];

    // Build file list & check for existence
    // Build meta structures.
    NSMutableArray * files2send = [[NSMutableArray alloc] initWithCapacity:[params.files count]];

    // Total size of files to send - for progress monitoring.
    holder.srcFilesTotalSize = 0;
    holder.thumbFilesTotalSize = 0;

    // Whole meta file container.
    PEXPbMetaFileBuilder * metaBuilder = [[PEXPbMetaFileBuilder alloc] init];
    [metaBuilder setTimestamp:[PEXUtils currentTimeMillis]];
    [metaBuilder setNumberOfFiles:(unsigned int) [params.files count]];

    // Set title if not empty - user defined, optional.
    if (![PEXStringUtils isEmpty:params.title]){
        [metaBuilder setTitle: params.title];
    }

    // Set description if not empty - user defined, optional.
    if (![PEXStringUtils isEmpty:params.description]){
        [metaBuilder setXdescription: params.description];
    }

    //
    // Processing individual files to send.
    // Existence check, hashing, thumbnail generation.
    // Builds meta file.
    //
    PEXFtPreUploadFilesHolder * toReturn = [[PEXFtPreUploadFilesHolder alloc] init];
    BOOL success = NO;

    // Set progress to 0, this particular phase (meta file building)
    if (_txprogress != nil){
        [_txprogress setTotalOps:@(6)];
        [_txprogress setCurOp:@(0)];
        [self updateProgress:_txprogress partial:nil total:0.0];
    }

    PEXCancelledException * cancelledExc = nil;
    NSException * e = nil;

    @try {
        const NSUInteger filesNum = [params.files count];
        NSUInteger curFile = 0;

        // First pass - scan files to send, process them (determine size, availability, ...)

        for(PEXFileToSendEntry * f in params.files) {
            @autoreleasepool {
                // Was operation cancelled?
                [self checkIfCancelled];
                PEXFtFileEntry *fe = [self getFtFileEntry:holder fe:f];
                [fe.metaB setPrefOrder:(SInt32) curFile];
                [files2send addObject:fe];
                holder.srcFilesTotalSize += fe.size;

                DDLogVerbose(@"File meta prepared, fname=[%@] len=[%lu] extension=[%@] mime[%@]",
                        fe.fname, (unsigned long) fe.size, fe.ext, fe.metaB.mimeType);

                // Was operation cancelled?
                [self checkIfCancelled];

                // Progress
                [self updateProgress:_txprogress partial:@((double) curFile / (double) filesNum) total:0.10 * ((double) curFile / (double) filesNum)];
                curFile += 1;
            }
        }

        // Update new file names (potential duplicates fix).
        if (holder.fnameCollisionFound){
            DDLogVerbose(@"Fname collision found, going to update fnames");
            [PEXMessageManager fileNotificationMessageFnameUpdate:params newFnames:holder.orderedFnames];
        }

        // Operation was successful - we can proceed to the next step.
        [metaBuilder setNumberOfFiles:(unsigned int) curFile];

        // Now create ZIP archive containing given files. Then encrypt it.
        const uint64_t files2sendTotalSizeF = holder.srcFilesTotalSize;
        if (_txprogress != nil){
            [_txprogress setCurOp:@(1)];
        }

        bytes_processed_block mainProcessBlock = ^(NSInteger bytesDoneSoFar) {
            [self updateProgress:_txprogress
                         partial:@((double)bytesDoneSoFar / (double)files2sendTotalSizeF)
                           total:0.10 + (0.20)*((double)bytesDoneSoFar / (double)files2sendTotalSizeF)];
        };

        bytes_processed_block encProcessBlock = ^(NSInteger bytesDoneSoFar) {
            [self updateProgress:_txprogress
                         partial:@((double)bytesDoneSoFar / (double)files2sendTotalSizeF)
                           total:0.30 + (0.65)*((double)bytesDoneSoFar / (double)files2sendTotalSizeF)];
        };

        // Go file by file and process them.
        for(PEXFtFileEntry * fe in files2send){
            if (fe.isAsset){
                [self processAssetFile:holder fe:fe assetLib:nil progress:mainProcessBlock];
            } else {
                [self processNormalFile:holder fe:fe progress:mainProcessBlock];
            }

            // Add hash to the file.
            if (fe.sha256 != nil && [fe.sha256 length] > 0){
                fe.metaB.xhash = fe.sha256;
            }

            // Build meta detail and add to the meta message.
            PEXPbMetaFileDetail * metaFileDetailMsg = [fe.metaB build];
            fe.metaMsg = metaFileDetailMsg;
            [metaBuilder addFiles:metaFileDetailMsg];
        }

        [holder.zipFiles[PEX_FT_ARCH_IDX] close];
        [holder.zipFiles[PEX_FT_META_IDX] close];

        // Cancellation?
        [self checkIfCancelled];
        if (_txprogress != nil){
            [_txprogress setCurOp:@(2)];
            [self updateProgress:_txprogress partial:nil total:0.5];
        }

        // Encrypt Archive ZIP file and HMAC it.
        NSInputStream * isZip = [NSInputStream inputStreamWithFileAtPath:zipFileName];
        [isZip open];
        [self encryptAndMacFile:isZip holder:holder fileIdx:PEX_FT_ARCH_IDX progress:encProcessBlock];
        [PEXUtils closeSilently:isZip];
        [PEXUtils removeFile:zipFileName];
        DDLogVerbose(@"Archive file was encrypted.");

        holder.fileHash[PEX_FT_ARCH_IDX]    = [self computeFTFileHashFile:ftArchFile iv:holder.fileIv[PEX_FT_ARCH_IDX] mac:holder.fileMac[PEX_FT_ARCH_IDX]];
        holder.fileSize[PEX_FT_ARCH_IDX]    = @([PEXUtils fileSize:ftArchFile error:nil]);
        holder.filePrepRec[PEX_FT_ARCH_IDX] = [self getFilePrependRecord:holder fileIdx:PEX_FT_ARCH_IDX];
        if (_txprogress!=nil){
            [_txprogress setCurOp: @(3)];
            [self updateProgress:_txprogress partial:nil total:0.96];
        }

        // Add missing fields to the meta & dump meta to the piped stream - avoid writing
        // unprotected files to the storage.
        // Meta file contains hash of the pack file to create binding between them.
        [metaBuilder setArchiveHash:holder.fileHash[PEX_FT_ARCH_IDX]];
        PEXPbMetaFile * mf = [metaBuilder build];

        // Meta file = delimited MB message + ZIP with thumbs.
        NSData * metaPb = [mf writeDelimitedToCodedNSData];
        PEXMergedInputStream * metaFileIs = [[PEXMergedInputStream alloc] initWithStream:
                        [NSInputStream inputStreamWithData:metaPb]
                      : [NSInputStream inputStreamWithFileAtPath:zipMetaName]];

        // Encrypt & hmac resulting meta file.
        [metaFileIs open];
        [self encryptAndMacFile:metaFileIs holder:holder fileIdx:PEX_FT_META_IDX progress:nil];
        [PEXUtils closeSilently:metaFileIs];
        [PEXUtils removeFile:zipMetaName];
        DDLogVerbose(@"Meta file was encrypted.");

        // Cancellation?
        [self checkIfCancelled];

        // Encrypt the given file & unlink the old file used for meta file.
        if (_txprogress != nil){
            [_txprogress setCurOp:@(4)];
            [self updateProgress:_txprogress partial:nil total:0.97];
        }

        // Can finally compute hashes & determine file size
        holder.fileHash[PEX_FT_META_IDX]    = [self computeFTFileHashFile:ftMetaFile iv:holder.fileIv[PEX_FT_META_IDX] mac:holder.fileMac[PEX_FT_META_IDX]];
        holder.fileSize[PEX_FT_META_IDX]    = @([PEXUtils fileSize:ftMetaFile error:nil]);
        holder.filePrepRec[PEX_FT_META_IDX] = [self getFilePrependRecord:holder fileIdx:PEX_FT_META_IDX];

        // Success.
        DDLogVerbose(@"Files were processed successfully.");
        if (_txprogress != nil){
            [_txprogress setCurOp:@(5)];
            [self updateProgress:_txprogress partial:nil total:1.0];
        }

        // Prepare structures for upload.
        [self buildUkeyData:holder];

        toReturn.files2send = files2send;
        toReturn.mf = mf;
        success = YES;

    } @catch(PEXCancelledException * cex){
        DDLogInfo(@"Prepare files operation was cancelled");
        cancelledExc = cex;

    } @catch(NSException * ex) {
        DDLogError(@"Exception in creating file transfer archives. exception=%@", e);
        e = ex;
    }

    // If operation was not success, delete temporary files and reset holder.
    if (!success){
        DDLogVerbose(@"Operation was not successful.");
        [PEXUtils removeFile:ftMetaFile];
        [PEXUtils removeFile:ftArchFile];
        [PEXUtils removeFile:zipMetaName];
        [PEXUtils removeFile:zipFileName];

        // Files cleanup.
        [self cleanFiles:holder];
        [holder resetFileData];
    }

    // Throw exception to inform about cancellation, if any happened.
    if (cancelledExc!=nil){
        [PEXCancelledException raise:PEXFileTransferGenericException format:@"Operation cancelled"];
    }

    // If exception was thrown, propagate it to upper layer.
    if (e!=nil){
        @throw e;
    }

    return toReturn;
}

/**
* Prepares cipher for file encryption from FTholder.
* Valid IVs and Ci are assumed to be stored in holder.
*
* Used mainly for internal purposes.
*
* @param holder
* @param encryption
* @param fileIdx
* @return
*/
-(PEXCipher *) prepareCipher: (PEXFtHolder *) holder encryption: (BOOL) encryption fileIdx: (int) fileIdx {
    if (fileIdx<0 || fileIdx>=2){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Invalid file index" userInfo:nil];
    }

    const NSUInteger keyIdx = fileIdx == PEX_FT_META_IDX ? PEX_FT_CI_ENC_META : PEX_FT_CI_ENC_ARCH;
    [self throwIfNull:holder.ci[keyIdx]];
    [self throwIfNull:holder.fileIv[fileIdx]];

    // Convert ci keys to the AES encryption keys.
    // Ci length has to correspond to the AES encryption key size.
    NSData * key = holder.ci[keyIdx];
    NSData * iv  = holder.fileIv[fileIdx];

    // Encrypt given data by AES-CBC
    return [PEXCipher cipherWithCipher:EVP_aes_256_cbc() encrypt:encryption key:key iv:iv];
}

/**
* Returns data that should be prepended meta/archive file before sending.
*/
-(NSData *) getFilePrependRecord: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx {
    if (fileIdx>=2){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Invalid file index" userInfo:nil];
    }

    // Build {IV + MAC} structure that prepends ciphertext.
    PEXPbUploadFileEncryptionInfoBuilder * b = [[PEXPbUploadFileEncryptionInfoBuilder alloc] init];
    [b setIv:holder.fileIv[fileIdx]];
    [b setMac:holder.fileMac[fileIdx]];

    // Build structure & write to the output stream.
    PEXPbUploadFileEncryptionInfo * info = [b build];
    return [info writeDelimitedToCodedNSData];
}

/**
* Returns file name to store downloaded files.
*
*/
+(NSString *) getFileNameForDownload: (NSUInteger) fileIdx nonce2: (NSString *) nonce2 {
    NSString * cacheDir = [PEXSecurityCenter getFileTransferCacheDir:nil];
    NSString * fileName =  [NSString stringWithFormat:@"ft_recv_%lu_%@.tmp", (unsigned long) fileIdx, [PEXDhKeyHelper getFilenameFromBase64:nonce2]];
    return [NSString pathWithComponents:@[cacheDir, fileName]];
}

/**
* Returns file name to store decrypted versions.
*/
-(NSString *) getFileNameForDecrypted: (NSUInteger) fileIdx nonce2: (NSString *) nonce2 {
    NSString * cacheDir = [self getCacheDirectory];
    NSString * fileName =  [NSString stringWithFormat:@"ft_dec_%lu_%@.tmp", (unsigned long) fileIdx, [PEXDhKeyHelper getFilenameFromBase64:nonce2]];
    return [NSString pathWithComponents:@[cacheDir, fileName]];
}

/**
* Returns file name to store packed file.
*/
-(NSString *) getFileNameForPacked: (NSUInteger) fileIdx nonce2: (NSString *) nonce2 {
    NSString * cacheDir = [self getCacheDirectory];
    NSString * fileName =  [NSString stringWithFormat:@"ft_zip_%lu_%@.tmp", (unsigned long) fileIdx, [PEXDhKeyHelper getFilenameFromBase64:nonce2]];
    return [NSString pathWithComponents:@[cacheDir, fileName]];
}

/**
* Reads given file from the stream in a specific format defined by protocol.
* IV, MAC, Ciphertext.
*
* IV and MAC are stored to holder (parsed from Protocol Buffer message that prepends
* ciphertext in the given InputStream), ciphertext is stored to a new temporary file,
* path is stored to holder. File is not decrypted.
*
* It totalSize is null, the size of the given file is unknown, thus updates number of bytes read, not percents.
*
* Used mainly for internal purposes - reads file from the downloading stream.
*
* If allow re-download is enabled, fixed file name is used and file is appended.
*
* Supports canceling operation in progress.
*
* @param holder
*/
-(void) readFileFromStream: (PEXFtHolder *) holder is: (NSInputStream *) is fileIdx: (NSUInteger) fileIdx
           allowReDownload: (BOOL) allowReDownload progress: (PEXTransferProgress *) progress
                 totalSize: (NSNumber *) totalSize
{
    if (fileIdx>=2){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Invalid file index" userInfo:nil];
    }

    NSString * nonce2 = [holder.nonce2 base64EncodedStringWithOptions:0];

    // Create temporary files.
    // Create in external storage - can do it, since files are protected (encrypted content).
    //
    // If allow re-download is set, create file name with specified filename since it
    // may already exist.
    NSString * tempFile = [PEXDhKeyHelper getFileNameForDownload:(int)fileIdx nonce2:nonce2];
    NSFileManager * fmgr = [NSFileManager defaultManager];

    // If file does not exist and allowReDownload==true, create new one
    if (allowReDownload && ![fmgr fileExistsAtPath:tempFile]){
        [fmgr createFileAtPath:tempFile contents:[NSData data] attributes:nil];
    }

    // Read ciphertext to a file, set new file to FTholder..
    holder.filePath[fileIdx] = tempFile;
    NSError * err = nil;
    uint64_t read = [PEXUtils fileSize:tempFile error:&err]; // May be continued download.
    BOOL ok = NO;
    if (err != nil){
        read = 0;
    }

    // Was operation cancelled?
    if ([self isCancelled]){
        [fmgr removeItemAtPath:tempFile error:nil];
        @throw [PEXCancelledException exceptionWithName:PEXOperationCancelledExceptionString reason:@"Cancelled during download" userInfo:nil];
    }

    NSOutputStream * bos = nil;
    @try {
        bos = [NSOutputStream outputStreamToFileAtPath:tempFile append:allowReDownload];
        [bos open];
        BOOL cancelled = NO;

        __weak __typeof(self) weakSelf = self;
        PEXStreamCopyResult res = [PEXStreamUtils copyStreamWithBuffer:8192 is:is os:bos readCnt:&read
                                 cancelBlock:^BOOL { return [weakSelf isCancelled]; }
                              bytesReadBlock:nil
                           bytesWrittenBlock:^(NSInteger bytes) {
                               [weakSelf updateProgress:progress partial:nil total:totalSize == nil ? bytes : (double)bytes / [totalSize doubleValue]];
                           }
        ];

        if (res == PEX_STREAM_CANCELLED){
            cancelled = YES;
        } else if (res != PEX_STREAM_COPY_OK){
            [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Stream copy error."];
        }


        [PEXUtils closeSilently:bos];

        // If numbytes != -1, stream was not entirely read -> cancelled.
        // But to be sure, new variable cancelled is used;
        if (cancelled){
            DDLogVerbose(@"Reading cancelled");
            [fmgr removeItemAtPath:tempFile error:nil];
            @throw [PEXCancelledException exceptionWithName:PEXOperationCancelledExceptionString reason:@"Cancelled during download" userInfo:nil];
        }

        holder.fileSize[fileIdx] = @([PEXUtils fileSize:tempFile error:nil]);
        ok = YES;

    } @catch(NSException * e){
        [PEXUtils closeSilently:bos];
        @throw e;
    } @finally {
        // If process was not finished successfully, delete temporary file.
        if (!ok){
            DDLogVerbose(@"Reading was not successful, deleting temporary file %@", tempFile);
            [fmgr removeItemAtPath:tempFile error:nil];
        }
    }
}

/**
* Verifies MAC & decrypts file pointed by holder.
* After decryption new filename pointing at decrypted file is stored to the holder,
* old file is deleted.
*
* @param holder
*/
-(BOOL) decryptFile: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx {
    if (fileIdx>=2){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Invalid file index" userInfo:nil];
    }

    // File existence check.
    NSFileManager * fmgr = [NSFileManager defaultManager];
    NSString * file = holder != nil && holder.filePath != nil ? holder.filePath[fileIdx] : nil;
    if (![PEXUtils fileExistsAndIsAfile:file]){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Specified file does not exist, cannot continue." userInfo:nil];
    }

    // At first read meta information.
    NSInputStream * is = [NSInputStream inputStreamWithFileAtPath:file];
    NSInteger bytesRead = 0;
    const SInt32 msgLen = [PEXPbUtils readMessageSize:is bytesRead:&bytesRead];
    PEXLengthDelimitedInputStream * ldis = [[PEXLengthDelimitedInputStream alloc] initWithStream:is length:msgLen];
    PBCodedInputStream * codis = [PBCodedInputStream streamWithInputStream:ldis];
    PEXPbUploadFileEncryptionInfo * info = [PEXPbUploadFileEncryptionInfo parseFromCodedInputStream:codis];
    holder.fileIv[fileIdx] = info.iv;
    holder.fileMac[fileIdx] = info.mac;
    NSUInteger offset = (NSUInteger) (bytesRead + msgLen);

    // At first compute MAC.
    const NSUInteger macKey = fileIdx == PEX_FT_META_IDX ? PEX_FT_CI_MAC_META : PEX_FT_CI_MAC_ARCH;
    NSData * computedMac = [self generateFTFileMacFile:file offset:offset key:holder.ci[macKey] iv:holder.fileIv[fileIdx] nonce2:holder.nonce2];
    if (![PEXUtils isDataSameAndNonNil:computedMac b:holder.fileMac[fileIdx]]){
        @throw [PEXMACVerificationException exceptionWithName:PEXFileTransferGenericException reason:@"MAC does not match" userInfo:nil];
    }

    // Create a new temporary file
    NSString * nonce2 = [holder.nonce2 base64EncodedStringWithOptions:0];

    // Create temporary files.
    // Create in external storage - can do it, since files are protected (encrypted content).
    NSString * tempFile = [self getFileNameForDecrypted:fileIdx nonce2:nonce2];
    [PEXUtils removeFile:tempFile];

    // Prepare decryption
    PEXCipher * aes = [self prepareCipher:holder encryption:NO fileIdx:(int)fileIdx];

    NSOutputStream * bos = nil;
    @try {
        bos = [NSOutputStream outputStreamToFileAtPath:tempFile append:YES];
        [bos open];

        // Encryption is performed in this step.
        PEXStreamedCipher * sAes = [PEXStreamedCipher cipherWithCip:aes canceller:self.canceller progressMonitor:nil buffSize:2048];
        sAes.offset = offset;
        sAes.cancelBlock = _cancelBlock;
        [sAes doCipherFileA:file os:bos];

        [PEXUtils closeSilently:bos];
        bos = nil;

        // Delete old file
        [fmgr removeItemAtPath:file error:nil];

        // Set new file
        holder.filePath[fileIdx] = tempFile;
        holder.fileSize[fileIdx] = @([PEXUtils fileSize:tempFile error:nil] - offset);

        return true;
    } @finally {
        if (bos != nil){
            [PEXUtils closeSilently:bos];
        }
    }
}

/**
* Builds meta file from the holder.
*
* Assumes file was already decrypted and holder points at decrypted meta file.
* Also dumps ZIP file from the rest of the decrypted file.
*
* @param holder
* @return
*/
-(PEXPbMetaFile *) reconstructMetaFile: (PEXFtHolder *) holder {
    if (holder == nil || holder.filePath[PEX_FT_META_IDX] == nil){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Holder or meta file null" userInfo:nil];
    }

    NSFileManager * fmgr = [NSFileManager defaultManager];
    NSString * nonce2 = [holder.nonce2 base64EncodedStringWithOptions:0];

    // File where decrypted file resides.
    NSString * file = holder.filePath[PEX_FT_META_IDX];

    // File where to store ZIPed thumbs.
    NSString * zipMetaName = [self getFileNameForPacked:PEX_FT_META_IDX nonce2:nonce2];

    // File existence check.
    if (![PEXUtils fileExistsAndIsAfile:file fmgr:fmgr] || ![fmgr isReadableFileAtPath:file]){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Specified file does not exist, cannot continue." userInfo:nil];
    }

    NSInputStream  * bis = nil;
    NSOutputStream * bos = nil;
    PEXPbMetaFile  * mf  = nil;
    PEXLengthDelimitedInputStream * ldis = nil;

    @try {
        bis = [NSInputStream inputStreamWithFileAtPath:file];
        [bis open];

        // At first read meta information.
        SInt32 msgLen = [PEXPbUtils readMessageSize: bis];
        DDLogVerbose(@"MSGLength: %ld", (long) msgLen);

        // Parse meta message from the input stream, leaving the rest unread.
        ldis = [[PEXLengthDelimitedInputStream alloc] initWithStream:bis length:msgLen];
        PBCodedInputStream * codis = [PBCodedInputStream streamWithInputStream:ldis];
        mf  = [PEXPbMetaFile parseFromCodedInputStream:codis];

        // Pump bis to the thumb zip file.
        bos = [NSOutputStream outputStreamToFileAtPath:zipMetaName append:NO];

        NSMutableData  * dataBuff        = [NSMutableData dataWithLength:8192];
        uint8_t        * bytes           = dataBuff.mutableBytes;
        const NSUInteger bytesLen        = dataBuff.length;
        NSUInteger       numTotalBytes   = 0;
        NSInteger        bytesRead       = 0;
        PEXRingBuffer  * ring            = [PEXRingBuffer bufferWithBuffSize:bytesLen];
        BOOL             streamFinished  = NO;

        for([bos open] ; (![ring isEmpty] || !streamFinished) && ![self isCancelled] ; ) {
            // Phase 1 - read data from input file stream to ring buffer.
            if ([ring isEmpty]) {
                [ring resetBufferIfEmpty];

                bytesRead = [bis read:bytes maxLength:bytesLen];
                if (bytesRead == 0) {
                    streamFinished = YES;

                } else if (bytesRead < 0) {
                    DDLogError(@"Error in reading a thumb ZIP file %@", file);
                    [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Error in reading a thumb ZIP file=%@", file];

                } else {
                    NSInteger ringWritten = [ring write:bytes maxLength:(NSUInteger) bytesRead];
                    if (ringWritten != bytesRead){
                        DDLogError(@"RingWritten != data.length.");
                        [PEXFileTransferException raise:PEXFileTransferUnkownArchiveStructureException format:@"Ring buffer works wrong."];
                    }
                }
            }

            // Phase 2 - If ring is not empty, dump it to the file output stream.
            if (![ring isEmpty]){
                uint8_t   * readBytes     = [ring getContiguousReadBuffer];
                NSInteger   buffLen       = [ring getContiguousReadBufferLen];
                NSInteger   streamWritten = [bos write:readBytes maxLength:(NSUInteger) buffLen];
                if (streamWritten < 0){
                    DDLogError(@"Cannot write data into the file");
                    [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Cannot write data into file."];

                } else if (streamWritten == 0){
                    DDLogDebug(@"Writen 0 bytes to the file stream");
                }

                numTotalBytes += streamWritten;
                [ring setBytesRead:(NSUInteger)streamWritten];
            }
        }

        [self checkIfCancelled];

        // On success, tidy up the files.
        [PEXUtils removeFile:file];
        if (numTotalBytes > 0) {
            holder.filePath[PEX_FT_META_IDX] = zipMetaName;
        } else {
            holder.filePath[PEX_FT_META_IDX] = @"";
            [PEXUtils removeFile:zipMetaName];
        }

    } @finally {
        [PEXUtils closeSilently:bos];
        [PEXUtils closeSilently:bis];
        [PEXUtils closeSilently:ldis];
    }

    return mf;
}

/**
* Backward compatible meta file from android platform - was not length delimited, without thumbZIP.
*/
-(PEXPbMetaFile *) reconstructMetaFileOld: (PEXFtHolder *) holder {
    if (holder == nil || holder.filePath[PEX_FT_META_IDX] == nil){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Holder or meta file null" userInfo:nil];
    }

    NSFileManager * fmgr = [NSFileManager defaultManager];
    NSString * nonce2 = [holder.nonce2 base64EncodedStringWithOptions:0];

    // File where decrypted file resides.
    NSString * file = holder.filePath[PEX_FT_META_IDX];

    // File where to store ZIPed thumbs.
    NSString * zipMetaName = [self getFileNameForPacked:PEX_FT_META_IDX nonce2:nonce2];

    // File existence check.
    if (![PEXUtils fileExistsAndIsAfile:file fmgr:fmgr] || ![fmgr isReadableFileAtPath:file]){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Specified file does not exist, cannot continue." userInfo:nil];
    }

    NSInputStream  * bis = nil;
    PEXPbMetaFile  * mf  = nil;

    @try {
        bis = [NSInputStream inputStreamWithFileAtPath:file];
        [bis open];

        // Parse meta message from the input stream, leaving the rest unread.
        PBCodedInputStream * codis = [PBCodedInputStream streamWithInputStream:bis];
        mf  = [PEXPbMetaFile parseFromCodedInputStream:codis];

        [self checkIfCancelled];

        // On success, tidy up the files.
        [PEXUtils removeFile:file];
        holder.filePath[PEX_FT_META_IDX] = @"";
        [PEXUtils removeFile:zipMetaName];

    } @finally {
        [PEXUtils closeSilently:bis];
    }

    return mf;
}

/**
* Check if the resulting file name conflicts with existing ones in given destination directory.
* If yes, action is taken according to the specification. It might throw na exception, rename new file or overwrite existing one.
*/
- (NSString *) getFileNameCheckConflict: (NSFileManager *) fmgr destDir: (NSString *) destDir fname: (NSString *) fname conflictAction: (PEXFtFilenameConflictCopyAction) conflictAction {
    NSString * cFile = [NSString pathWithComponents:@[destDir, fname]];
    if ([PEXUtils fileExistsAndIsAfile:cFile]){
        if (conflictAction == PEX_FILECOPY_THROW_EXCEPTION){
            [PEXFileTransferException raise:PEXFileTransferUnkownArchiveStructureException format:@"File already exists."];
        } else if (conflictAction == PEX_FILECOPY_OVERWRITE && ![fmgr isWritableFileAtPath:cFile]){
            [PEXFileTransferException raise:PEXFileTransferUnkownArchiveStructureException format:@"File cannot be overwritten."];
        }

        // If rename on conflict -> create a new temporary file.
        if (conflictAction == PEX_FILECOPY_RENAME_NEW){
            cFile = [PEXUtils createTemporaryFileFrom:fname dir:destDir];
            if (![fmgr isWritableFileAtPath:cFile]){
                [PEXFileTransferException raise:PEXFileTransferUnkownArchiveStructureException format:@"Cannot create a writable temporary file."];
            }
        }
    }

    return cFile;
}

/**
* Extracts ZIP archive at given file with options.
* Can be used either for meta or pack archives.
*/
-(PEXFtUnpackingResult *) unzipArchiveAtFile: (NSString *) file options: (PEXFtUnpackingOptions *) options {
    if (file == nil){
        [PEXFileTransferException raise:PEXFileTransferGenericException format:@"File is nit"];
    }

    if (options == nil){
        [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Options is nil"];
    }

    if (options.destinationDirectory == nil){
        [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Directory is nil"];
    }

    PEXFtUnpackingResult * res = [[PEXFtUnpackingResult alloc] init];
    NSFileManager * fmgr = [NSFileManager defaultManager];

    // File existence check.
    if (![PEXUtils fileExistsAndIsAfile:file fmgr:fmgr]){
        [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Specified file does not exist, cannot continue."];
    }

    // Create destination directory if missing.
    NSString * destDir = [PEXUtils ensureDirectoryPath:options.destinationDirectory];
    if (![PEXUtils directoryExists:destDir fmgr:fmgr] && options.createDirIfMissing){
        NSDictionary * attributes = @{ NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication };
        [fmgr createDirectoryAtPath:destDir withIntermediateDirectories:YES attributes:attributes error:nil];
    }

    // Check if destination directory is usable (exists, is directory and is writable).
    if (![PEXUtils directoryExists:destDir fmgr:fmgr] || ![fmgr isWritableFileAtPath:destDir]){
        DDLogError(@"Problem with destination directory: %@", destDir);
        [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Problem with destination directory, probably does not exist."];
    }

    NSMutableArray * tmpFiles     = [[NSMutableArray alloc] init];
    NSMutableArray * createdFiles = [[NSMutableArray alloc] init];
    ZipFile        * unzipFile    = nil;
    res.finishedOK                = YES;

    // Extracting the archive in try block.
    @try {
        unzipFile = [[ZipFile alloc] initWithFileName:file mode:ZipFileModeUnzip allow64Mode:NO];
        [unzipFile goToFirstFileInZip];

        // Read each file in the archive and extract it to the destination directory.
        NSUInteger numFiles = [unzipFile numFilesInZip];
        for (NSUInteger i = 0; i < numFiles; i++){
            FileInZipInfo * fileInfo = [unzipFile getCurrentFileInZipInfo];
            NSString      * fname    = options.fnamePrefix == nil ?
                      [fileInfo name]
                    : [NSString stringWithFormat:@"%@%@", options.fnamePrefix, [fileInfo name]];

            if (fileInfo.crypted || [PEXStringUtils contains:fname needle:@"/"]){
                [PEXFileTransferException raise:PEXFileTransferUnkownArchiveStructureException format:@"Encrypted or file names are not allowed."];
            }

            NSString * sanitizedFname = [self sanitizeFileName:fname];
            NSString * cFile = [self getFileNameCheckConflict:fmgr destDir:destDir fname:sanitizedFname conflictAction:options.actionOnConflict];
            [tmpFiles addObject:cFile];

            DDLogVerbose(@"Going to read file [%@] from the archive and write as [%@]", sanitizedFname, cFile);
            PEXMessageDigest *fileDigest    = [PEXMessageDigest digestWithHashFunction:HASH_SHA256];
            ZipReadStream  * read           = [unzipFile readCurrentFileInZip];
            NSMutableData  * data           = [[NSMutableData alloc] initWithLength:4096];
            NSOutputStream * fos            = [NSOutputStream outputStreamToFileAtPath:cFile append:NO];
            PEXRingBuffer  * ring           = [PEXRingBuffer bufferWithBuffSize:[data length]];
            BOOL             failReading    = NO;
            BOOL             streamFinished = NO;

            // Read file from ZIP archive and write it to the new file.
            for([fos open]; (![ring isEmpty] || !streamFinished) && ![self isCancelled] ; ) {
                if ([ring isEmpty]) {
                    [ring resetBufferIfEmpty];
                    NSInteger bytesRead = [read readDataWithBuffer:data];
                    if (bytesRead < 0) {
                        DDLogError(@"Error while unziping a file.");
                        failReading = YES;
                        break;
                    } else if (bytesRead == 0) {
                        streamFinished = YES;
                    } else {
                        [fileDigest update:[data mutableBytes] len:(size_t)bytesRead];
                        NSInteger ringWritten = [ring write:[data mutableBytes] maxLength:(NSUInteger) bytesRead];
                        if (ringWritten != bytesRead) {
                            DDLogError(@"RingWritten != data.length.");
                            [PEXFileTransferException raise:PEXFileTransferUnkownArchiveStructureException format:@"Ring buffer works wrong."];
                        }
                    }
                }

                // If ring is not empty, dump it to the stream.
                if (![ring isEmpty]){
                    uint8_t * readBytes = [ring getContiguousReadBuffer];
                    NSInteger buffLen = [ring getContiguousReadBufferLen];
                    NSInteger streamWritten = [fos write:readBytes maxLength:(NSUInteger) buffLen];
                    if (streamWritten < 0){
                        DDLogError(@"Cannot write data into the file");
                        [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Cannot write data into file."];
                        failReading = YES;

                    } else if (streamWritten == 0){
                        DDLogDebug(@"Writen 0 bytes to the file stream");
                    }

                    [ring setBytesRead:(NSUInteger)streamWritten];
                }
            }

            [read finishedReading];
            [PEXUtils closeSilently:fos];

            if ([self isCancelled]){
                res.finishedOK = NO;
                break;
            }

            if (!failReading){
                DDLogVerbose(@"File %@ successfully extracted", sanitizedFname);
                PEXFtUnpackingFile * fl = [[PEXFtUnpackingFile alloc] initWithOriginalFname:[fileInfo name] destination:cFile];
                fl.sha256 = [fileDigest final];
                [createdFiles addObject: fl];
            }

            if (![unzipFile goToNextFileInZip]){
                break;
            }
        } // End of file in ZIP archive iteration.

    } @catch(NSException * ex){
        res.exc = ex;
        res.finishedOK = NO;

    } @finally {
        if (unzipFile != nil){
            [unzipFile close];
        }

        // Delete all created files in case of an error / exception.
        if (!res.finishedOK || res.exc != nil){
            DDLogVerbose(@"Exception thrown during archive extraction");
            if (options.deleteNewFilesOnException){
                DDLogVerbose(@"Going to throw exception, deleting extracted files, len=%lu", (unsigned long)[tmpFiles count]);
                for(NSString * f in tmpFiles){
                    [PEXUtils removeFile:f];
                }
            }
        }
    } // end of try-catch-finally

    // Exception has to be thrown eventually.
    if (res.exc != nil){
        DDLogVerbose(@"Exception during extraction");
        @throw res.exc;
    }

    // Copy file names as result.
    res.files = [NSArray arrayWithArray:createdFiles];
    return res;
}

/**
* Unzips archive file sent in file transfer protocol.
* Archive is assumed to have only flat structure (no directories are allowed).
*
*
* @param holder
* @return
*/
-(PEXFtUnpackingResult *) unzipArchive: (PEXFtHolder *) holder options: (PEXFtUnpackingOptions *) options {
    if (holder == nil || holder.filePath[PEX_FT_ARCH_IDX] == nil){
        [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Holder or meta file is nil"];
    }

    if (options == nil){
        [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Options is nil"];
    }

    if (options.destinationDirectory == nil){
        [PEXFileTransferException raise:PEXFileTransferGenericException format:@"Directory is nil"];
    }

    NSString             * file = holder.filePath[PEX_FT_ARCH_IDX];
    PEXFtUnpackingResult * res  = [[PEXFtUnpackingResult alloc] init];

    @try {
        res = [self unzipArchiveAtFile:file options:options];

        // No exception -> delete old archive file.
        if (options.deleteArchiveOnSuccess){
            DDLogVerbose(@"Going to delete archive (onSuccess)");

            if ([PEXUtils removeFile:holder.filePath[PEX_FT_ARCH_IDX]]){
                holder.filePath[PEX_FT_ARCH_IDX] = @"";
            }
        }

        // Delete meta archive on success
        if (options.deleteMetaOnSuccess && ![PEXStringUtils isEmpty:holder.filePath[PEX_FT_META_IDX]]){
            DDLogVerbose(@"Going to delete meta (onSuccess)");

            NSString * mFile = holder.filePath[PEX_FT_META_IDX];
            if ([PEXUtils removeFile:mFile]){
                holder.filePath[PEX_FT_META_IDX] = @"";
            }
        }

        return res;
    } @catch(NSException * e){
        DDLogVerbose(@"Exception during extraction");
        res.exc = e;
        res.finishedOK = NO;
        res.files = [[NSArray alloc] init];
        @throw e;
    }
}

/**
* Uploads prepared files for the given user (uses userSip attribute).
* Files have to be already encrypted and prepared (with IV, MAC computed in FTHolder).
* Upload progress will be reported to txprogress.
*
* @param holder
* @param ks			KeyStore with user private key, needed for HTTPs connection.
* @param password		KeyStore password.
* @return
*/
-(PEXFtUploadResult *) uploadFile: (PEXFtHolder *) holder {
    PEXFtUploadResult * res = [[PEXFtUploadResult alloc] init];

    // Get my domain
    NSString * domain = [PEXSipUri getDomainFromSip:_userSip parsed:nil];

    // Determine full domain.
    NSString * url2send = [NSString stringWithFormat:@"%@%@", [PEXServiceConstants getDefaultRESTURL:domain], PEX_FT_REST_UPLOAD_URI];
    DDLogVerbose(@"Going to upload file, url=[%@]", url2send);

    // Was operation cancelled?
    [self checkIfCancelled];

    // Start upload process.
    __weak __typeof(self) weakSelf = self;
    PEXFtUploader * uploader = [[PEXFtUploader alloc] init];
    uploader.canceller = self.canceller;
    uploader.cancelBlock = self.cancelBlock;
    uploader.holder = holder;
    uploader.user = _userSip;
    uploader.progressBlock = ^(int64_t curBytes, int64_t totalBytes, int64_t totalBytesExpected) {
        [weakSelf updateProgress:weakSelf.txprogress partial:nil total:(double) totalBytes / (double) totalBytesExpected];
    };

    [uploader configureSession];
    [uploader prepareSecurity:self.privData];
    [uploader prepareSession];
    int waitRes = [uploader uploadFilesBlockingForUser:_userSip url:url2send];

    // Blocking call finished here.
    res.error = uploader.error;
    res.uploaderFinishCode = waitRes;
    res.code = uploader.statusCode;
    res.response = uploader.restResponse;
    DDLogVerbose(@"Upload finished. code=%ld, resp=%@, error=%@", (long)res.code, res.response, res.error);

    return res;
}

/**
* Downloads file sent by user specified in holder.
* After this method finishes, IV & MAC are parsed from prepended protocol buffers message
* from the input stream, ciphertext is stored to a file, its filename is stored appropriately
* in the FTHolder. File is not decrypted.
*
* @param holder		FTHolder with prepared keys, nonce2.
* @param ks			KeyStore with user private key, needed for HTTPs connection.
* @param password		KeyStore password.
* @param fileIdx		Which particular file to download.
*/
-(PEXFtFileDownloadResult *) downloadFile: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx allowRedownload: (BOOL) allowReDownload {
    if (fileIdx>=2){
        @throw [PEXFileTransferException exceptionWithName:PEXFileTransferGenericException reason:@"Invalid file index" userInfo:nil];
    }

    PEXFtFileDownloadResult * toReturn = [[PEXFtFileDownloadResult alloc] init];
    NSString * nonce2 = [holder.nonce2 base64EncodedStringWithOptions:0];
    NSString * pathNonce = [PEXDhKeyHelper getFilenameFromBase64:nonce2];
    NSString * fileType = fileIdx == PEX_FT_META_IDX ? @"meta" : @"pack"; // Magic strings defined on the server.

    // Get my domain
    NSString * domain = [PEXSipUri getDomainFromSip:_userSip parsed:nil];

    // Determine full domain.
    NSString * url2send = [NSString stringWithFormat:@"%@%@/%@/%@",
                    [PEXServiceConstants getDefaultRESTURL:domain],
                    PEX_FT_REST_DOWNLOAD_URI, pathNonce, fileType
    ];
    DDLogVerbose(@"Going to download file, url=[%@]", url2send);

    // Was operation cancelled?
    [self checkIfCancelled];

    // Continued download.
    uint64_t alreadyDownloaded = 0;
    NSString * cacheDir = [self getCacheDirectory];
    NSString * toDownload = [PEXDhKeyHelper getFileNameForDownload:fileIdx nonce2:nonce2];
    NSString * tempDownloadPath = [PEXUtils createTemporaryFileFrom:[toDownload lastPathComponent] dir:cacheDir];
    if (allowReDownload){
        if ([PEXUtils fileExistsAndIsAfile:toDownload]){
            alreadyDownloaded = [PEXUtils fileSize:toDownload error:nil];
            DDLogVerbose(@"Re-downloading, file exists, filesize=%llu", alreadyDownloaded);
        }
    }

    __weak __typeof(self) weakSelf = self;
    PEXFtDownloader * downloader = [[PEXFtDownloader alloc] init];
    downloader.canceller = self.canceller;
    downloader.cancelBlock = self.cancelBlock;
    downloader.holder = holder;
    downloader.user = _userSip;
    downloader.destinationFile = tempDownloadPath;
    [downloader setTimeouts:@(_connectionTimeoutMilli) resTimeout:@(_readTimeoutMilli)];
    downloader.progressBlock = ^(int64_t curBytes, int64_t totalBytes, int64_t totalBytesExpected) {
        [weakSelf updateProgress:weakSelf.txprogress partial:nil total:(double) totalBytes / (double) totalBytesExpected];
    };

    // Continued download range.
    if (alreadyDownloaded>0){
        [downloader setRangeFrom: (NSUInteger) alreadyDownloaded];
    }

    [downloader configureSession];
    [downloader prepareSecurity:self.privData];
    [downloader prepareSession];
    int waitRes = [downloader downloadFileBlocking:url2send];

    // Blocking call finished here.
    DDLogVerbose(@"Download finished. code=%ld, error=%@", (long) downloader.statusCode, downloader.error);
    toReturn.error = downloader.error;
    toReturn.code = downloader.statusCode;
    toReturn.downloaderFinishCode = waitRes;
    toReturn.task = downloader;
    if (waitRes == kWAIT_RESULT_CANCELLED
            || waitRes == kWAIT_RESULT_TIMEOUTED
            || downloader.error != nil
            || downloader.statusCode < 0)
    {
        return toReturn;
    }

    NSInputStream * is = [NSInputStream inputStreamWithFileAtPath:downloader.destinationFile];
    [is open];

    // Read file from temporary download file, parse prefixed IV, MAC.
    // Progress monitoring is inside download task.
    [self readFileFromStream:holder is:is fileIdx:fileIdx allowReDownload:NO progress:nil totalSize:nil];
    [PEXUtils closeSilently:is];

    // Delete downloaded raw file.
    [PEXUtils removeFile:tempDownloadPath];

    return toReturn;
}

+(void) cleanDownloadFile: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx {
    // Try to delete download residuals.
    if (holder.nonce2 == nil){
        return;
    }

    @try {
        NSString * down = [PEXDhKeyHelper getFileNameForDownload:fileIdx nonce2:[holder.nonce2 base64EncodedStringWithOptions:0]];
        if ([PEXUtils fileExistsAndIsAfile:down]){
            [PEXUtils removeFile:down];
        }

    } @catch(NSException * e){
        DDLogError(@"Could not delete file, exception=%@, fileIdx: %d", e, (int) fileIdx);
    }

}

+(void) cleanFile: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx {
    if (holder.filePath == nil) {
        return;
    }

    NSString * file;
    NSError * err = nil;

    NSFileManager * mgr = [NSFileManager defaultManager];
    file = holder.filePath[fileIdx];
    if (![PEXStringUtils isEmpty:file]) {
        err = nil;
        [mgr removeItemAtPath:file error:&err];
        if (err != nil) {
            DDLogDebug(@"error in cleaning path: %@, error=%@", file, err);
        }
    }

    file = holder.filePackPath[fileIdx];
    if (![PEXStringUtils isEmpty:file]) {
        err = nil;
        [mgr removeItemAtPath:file error:&err];
        if (err != nil) {
            DDLogDebug(@"error in cleaning path: %@, error=%@", file, err);
        }
    }
}

+(void) cleanAllFiles: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx {
    [PEXDhKeyHelper cleanDownloadFile:holder fileIdx:fileIdx];
    [PEXDhKeyHelper cleanFile:holder fileIdx:fileIdx];
}

/**
* Cleans all temporary files related to this session.
* @param holder
*/
-(void) cleanFiles: (PEXFtHolder *) holder{
    [PEXDhKeyHelper cleanAllFiles:holder fileIdx:PEX_FT_META_IDX];
    [PEXDhKeyHelper cleanAllFiles:holder fileIdx:PEX_FT_ARCH_IDX];
}

/**
* Deletes files that might be left over from failed download.
*/
-(void) deleteDownloadResiduals: (PEXFtHolder *) holder{
    // Try to delete download residuals.
    if (holder.nonce2 == nil){
        return;
    }

    [PEXDhKeyHelper cleanDownloadFile:holder fileIdx:PEX_FT_META_IDX];
    [PEXDhKeyHelper cleanDownloadFile:holder fileIdx:PEX_FT_ARCH_IDX];
}

/**
* Converts base64 string to a file name (removes /)
* Substitution:
* / --> _
* + --> -
*
* @param based
* @return
*/
+(NSString *) getFilenameFromBase64: (NSString *) based{
    NSString * toRet = based;
    toRet = [toRet stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    toRet = [toRet stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    return toRet;
}

/**
* Determines whether was upload sucessful.
* @param res
* @return
*/
- (BOOL) wasUploadSuccessful: (PEXFtUploadResult *) res{
    if (res == nil) return NO;
    if (res.uploaderFinishCode == kWAIT_RESULT_CANCELLED || res.uploaderFinishCode == kWAIT_RESULT_TIMEOUTED) return NO;
    if (res.code != 200) return NO;
    if (res.response == nil) return NO;
    if (![res.response hasErrorCode]) return NO;
    return res.response.errorCode == 0;
}

/**
* Returns service error code, if available, null otherwise.
* @param res
* @return
*/
-(NSInteger) getUploadErrorCode: (PEXFtUploadResult *) res{
    if (res == nil) return -1;
    if (res.code != 200) return -1;
    if (res.response == nil) return -1;
    if (![res.response hasErrorCode]) return -1;
    return res.response.errorCode;
}

/**
* Dumps holder to a string.
* For debugging. Do not use in production (deprecation flag).
*
* @deprecated
* @param holder
* @return
*/
+(NSString *) dumpHolder: (PEXFtHolder *) holder{
    if (holder == nil) return @"";
    NSMutableString * sb = [[NSMutableString alloc] init];
    [sb appendFormat:@"nonceb: %@\nnonce2: %@\n salt1: %@\nc: %@\n",
                    [PEXUtils bytesToHex:holder.nonceb],
                    [PEXUtils bytesToHex:holder.nonce2],
                    [PEXUtils bytesToHex:holder.salt1],
                    [PEXUtils bytesToHex:holder.c]
    ];

    // ci keys
    if (holder.ci != nil){
        for(NSUInteger i=0; i < [holder.ci count]; i++){
            [sb appendFormat:@"c_%lu: %@\n", (unsigned long) i, [PEXUtils bytesToHex:holder.ci[i]]];
        }
    }

    [sb appendFormat:@"mb: %@\nxb: %@\nencXb: %@\nmaEncXb: %@\n",
                    [PEXUtils bytesToHex:holder.MB],
                    [PEXUtils bytesToHex:[holder.XB writeToCodedNSData]],
                    [PEXUtils bytesToHex:holder.encXB],
                    [PEXUtils bytesToHex:holder.macEncXB]
    ];

    // Files
    for(NSUInteger i=0; i < PEX_FTHOLDER_NUM_ELEMS; i++){
        if (holder.fileHash!=nil)
            [sb appendFormat:@"fileHash[%lu]: %@\n", (unsigned long)i, [PEXUtils bytesToHex:holder.fileHash[i]]];
        if (holder.fileIv!=nil)
            [sb appendFormat:@"fileIV[%lu]: %@\n", (unsigned long) i, [PEXUtils bytesToHex:holder.fileIv[i]]];
        if (holder.fileMac!=nil)
            [sb appendFormat:@"fileMAC[%lu]: %@\n", (unsigned long) i, [PEXUtils bytesToHex:holder.fileMac[i]]];
        if (holder.fileSize!=nil)
            [sb appendFormat:@"fileSize[%lu]: %@\n", (unsigned long) i, holder.fileSize[i]];
        if (holder.filePath!=nil)
            [sb appendFormat:@"filePath[%lu]: %@\n", (unsigned long) i, [PEXUtils bytesToHex:holder.filePath[i]]];
    }

    return [NSString stringWithString:sb];
}

/**
* Determines whether to use compression in the file transfer
* @param extension
* @return
*/
-(BOOL) useCompression: (NSString *) extension{
    return YES; /*!("jpg".equalsIgnoreCase(extension)
				|| "jpeg".equalsIgnoreCase(extension)
				|| "png".equalsIgnoreCase(extension)
				|| "gif".equalsIgnoreCase(extension)
				|| "pdf".equalsIgnoreCase(extension)
				|| "zip".equalsIgnoreCase(extension)
				|| "rar".equalsIgnoreCase(extension)
				|| "tar".equalsIgnoreCase(extension)
				|| "jar".equalsIgnoreCase(extension)
				|| "gzip".equalsIgnoreCase(extension));*/
}

/**
* Returns true if the local canceller signalizes a canceled state.
* @return
*/
-(BOOL) isCancelled{
    return (_canceller != nil && [_canceller isCancelled]) || (_cancelBlock != nil && _cancelBlock());
}

/**
* Throws exception if operation was cancelled.
* @return
*/
-(void) checkIfCancelled {
    if (_canceller != nil && [_canceller isCancelled]){
        [PEXCancelledException raise:PEXOperationCancelledExceptionString format:@"Operation cancelled"];
    }

    if (_cancelBlock != nil && _cancelBlock()){
        [PEXCancelledException raise:PEXOperationCancelledExceptionString format:@"Operation cancelled"];
    }
}

@end
