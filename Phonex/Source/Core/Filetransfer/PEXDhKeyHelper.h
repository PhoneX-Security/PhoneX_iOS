//
// Created by Dusan Klinec on 15.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXCanceller;
@class PEXTransferProgress;
@class PEXPrivateKey;
@class PEXDHKeyHolder;
@class PEXPbGetDHKeyResponseBodySCip;
@class PEXDbDhKey;
@class PEXDH;
@class PEXFtHolder;
@class PEXPbUploadFileKey;
@class PEXCipher;
@class PEXPbMetaFile;
@class PEXFtUnpackingResult;
@class PEXFtUploadResult;
@class PEXFtUnpackingOptions;
@class PEXFtFileDownloadResult;
@class PEXFtUploadParams;
@class PEXFtPreUploadFilesHolder;

/**
* Class for GetDHKey protocol.
* Implements basic cryptographic operations related to the protocol.
*
* GetDHKey protocol:
* \begin{tabular}{l l l}
* 		$A \rightarrow B$: 	& $A$ & getKeyRequest \\
* 		$A \leftarrow B$: 	& $RSA^e(A_{pub}, K_1), IV_1, AES^e_{K_1, IV_1}(dh\_group\_id, g^x, nonce_1, sig_1)$ & getKeyResponse\\
* 		$A \rightarrow B$: 	& $hash(nonce_1)$ & getPart2Request\\
* 		$A \leftarrow B$: 	& $nonce_2, RSA^e(A_{pub}, K_2), IV_2, AES^e_{K_2, IV_2}(sig_2)$ & getPart2Response\\
* \end{tabular}
* Where:
* 	 Apub   ... public RSA key of the remote party
* 	 RSA    ... asymmetric encryption (RSA/ECB/OAEPWithSHA1AndMGF1Padding)
*   hash   ... sha256
*   sig1   ... sig(hash(version || B || hash(B_{crt}) || A || hash(A_{crt}) || dh\_group\_id || g^x || nonce_1 ))
*   sig2   ... sig(hash(version || B || hash(B_{crt}) || A || hash(A_{crt}) || dh\_group\_id || g^x || nonce_1 || nonce_2 ))
*
* FileTransfer protocol:
* 	\begin{tabular}{r l l l}
* 		$B:$ & $salt_B$ 	& = \text{generate random salt} & \\
* 		$B:$ & $nonce_B$ 	& = \text{generate random nonce} & \\
* 		$B:$ & $y$ 			& = \text{generate random DH key} & \\
* 		$B:$ & $c$ 			&; \text{mod} \; p$ & \\
* 		$B:$ & $salt_1$ 	& = $hash(salt_B \oplus nonce_1)$  & \\
* 		$B:$ & $c_i$ 		&; || \; "\text{pass-}c_i", hash(hash^i(salt_1) || nonce_2), 1024, 256)$ & \\
* 		$B:$ & $M_B$ 		& = $MAC_{c_1}(version || B || hash(B_{crt}) || A || hash(A_{crt}) || dh\_group\_id || g^x || g^y || g^{xy} || nonce_1 || nonce_2 || nonce_B)$ & \\
* 		$B:$ & $X_B$ 		& = $B, nonce_B, sig(M_B)$ & \\
* 		$B:$ & $F_m$ 		& = $iv_1, \{file\_meta\}_{c_{5}}, MAC_{c_6}(iv_1, \{file\_meta\}_{c_{5}} || nonce_2)$ & \\
* 		$B:$ & $F_p$ 		& = $iv_2, \{file\_pack\}_{c_{7}}, MAC_{c_8}(iv_2, \{file\_pack\}_{c_{7}} || nonce_2)$ & \\
* 		$A \rightarrow B$: & \multicolumn{2}{l}{ $version, nonce_2, (salt_B, g^y, \{X_B\}_{c_2}, MAC_{c_3}\left(\{X_B\}_{c_2}\right)), F_m, F_p$} \; REST uploadFile &
* \end{tabular}
*
* @author ph4r05
*
*/

#define PEX_FT_UPD_VERSION      "version"
#define PEX_FT_UPD_NONCE2       "nonce2"
#define PEX_FT_UPD_USER         "user"
#define PEX_FT_UPD_DHPUB        "dhpub"
#define PEX_FT_UPD_HASHMETA     "hashmeta"
#define PEX_FT_UPD_HASHPACK     "hashpack"
#define PEX_FT_UPD_METAFILE     "metafile"
#define PEX_FT_UPD_PACKFILE     "packfile"

/**
* Upload progress monitoring block.
*/
typedef void (^PEXTransferProgressBlock)(int64_t curBytes, int64_t totalBytes, int64_t totalBytesExpected);

FOUNDATION_EXPORT NSString * PEXFtErrorDomain;

/**
* Nonce size in bytes. 18B = 24 characters in Base64 encoding.
* More than 2**128 than UUID has.
*/
FOUNDATION_EXPORT const int PEX_FT_NONCE_SIZE;

/**
* GetKey & FileTransfer protocol version.
*/
FOUNDATION_EXPORT const int PEX_FT_PROTOCOL_VERSION;

/**
* Number of C keys derived from DH agreement.
*/
FOUNDATION_EXPORT const int PEX_FT_CI_KEYS_COUNT;

/**
* Number of days to key expiration on server side, after DH was created.
*/
FOUNDATION_EXPORT const int PEX_FT_EXPIRATION_SERVER_DAYS;

/**
* Number of days to key expiration in database, after DH was created.
*/
FOUNDATION_EXPORT const int PEX_FT_EXPIRATION_DATABASE_DAYS;

/**
* Number of bits for Ci keys.
*/
FOUNDATION_EXPORT const int PEX_FT_CI_KEYLEN;

/**
* Number of PBKDF2 iterations for generating Ci keys.
*/
FOUNDATION_EXPORT const int PEX_FT_CI_KEY_ITERATIONS;

FOUNDATION_EXPORT const NSUInteger PEX_FT_CI_MAC_MB;
FOUNDATION_EXPORT const NSUInteger PEX_FT_CI_ENC_XB;
FOUNDATION_EXPORT const NSUInteger PEX_FT_CI_MAC_XB;
FOUNDATION_EXPORT const NSUInteger PEX_FT_CI_ENC_META;
FOUNDATION_EXPORT const NSUInteger PEX_FT_CI_MAC_META;
FOUNDATION_EXPORT const NSUInteger PEX_FT_CI_ENC_ARCH;
FOUNDATION_EXPORT const NSUInteger PEX_FT_CI_MAC_ARCH;

/**
* Maximal length of a filename in FileTransferProtocol.
*/
FOUNDATION_EXPORT const int PEX_FT_MAX_FILENAME_LEN;

FOUNDATION_EXPORT NSString * PEX_FT_FILENAME_REGEX;
FOUNDATION_EXPORT NSString * PEX_FT_FILE_HASH_ALG;
FOUNDATION_EXPORT const int PEX_FT_THUMBNAIL_LONG_EDGE; // pixels at long edge.

FOUNDATION_EXPORT const NSUInteger PEX_FT_META_IDX;
FOUNDATION_EXPORT const NSUInteger PEX_FT_ARCH_IDX;

/**
* URI to the REST server for file upload.
*/
FOUNDATION_EXPORT NSString * PEX_FT_REST_UPLOAD_URI;
FOUNDATION_EXPORT NSString * PEX_FT_REST_DOWNLOAD_URI;
FOUNDATION_EXPORT NSString * PEX_FT_MULTIPART_CHARS;

FOUNDATION_EXPORT const int PEX_FT_UPLOAD_VERSION;
FOUNDATION_EXPORT const int PEX_FT_UPLOAD_NONCE2;
FOUNDATION_EXPORT const int PEX_FT_UPLOAD_USER;
FOUNDATION_EXPORT const int PEX_FT_UPLOAD_DHPUB;
FOUNDATION_EXPORT const int PEX_FT_UPLOAD_HASHMETA;
FOUNDATION_EXPORT const int PEX_FT_UPLOAD_HASHPACK;
FOUNDATION_EXPORT const int PEX_FT_UPLOAD_METAFILE;
FOUNDATION_EXPORT const int PEX_FT_UPLOAD_PACKFILE;

/**
* Action in case of file name conflicts in copy operation.
*
* @author ph4r05
*/
typedef enum PEXFtFilenameConflictCopyAction {
    PEX_FILECOPY_OVERWRITE = 0,
    PEX_FILECOPY_THROW_EXCEPTION,
    PEX_FILECOPY_RENAME_NEW
} PEXFtFilenameConflictCopyAction;

@interface PEXDhKeyHelper : NSObject

@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) PEXEVPPKey * privKey;
@property(nonatomic) PEXX509 * myCert;
@property(nonatomic) PEXX509 * sipCert;
@property(nonatomic) NSString * userSip;
@property(nonatomic) NSString * mySip;

@property(nonatomic) PEXTransferProgress * txprogress;
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic, copy) cancel_block cancelBlock;
@property(nonatomic) BOOL debug;


/**
* Connection timeout in milliseconds.
* 0 for indefinite waiting.
*/
@property(nonatomic) int connectionTimeoutMilli;

/**
* Timeout for a reading operation.
* 0 for indefinite waiting.
*/
@property(nonatomic) int readTimeoutMilli;

/**
* REST POST parameters names for file upload request.
*/
+(NSArray *)  getUploadParams;
+(NSString *) getUploadParam: (NSUInteger) idx;

/**
* Wrapper for generating DHkeys for the user.
* Prepares data structure.  Main entry point.
*
* @param userSip
* @author ph4r05
*/
-(PEXDHKeyHolder *) generateDHKey;

/**
* Process response of the GetDHKey protocol, 2nd message.
* Requires byte array corresponding to hybrid encryption output.
*
* @param hybridCipher
* @return
*/
-(PEXPbGetDHKeyResponseBodySCip *) getDhKeyResponse: (NSData *) hybridEncryption;
/**
* Process getPart2Response message, decrypts signature2.
*
* @param hybridEncryption
* @return
*/
-(NSData *) getDhPart2Response: (NSData *) hybridEncryption;

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
-(BOOL) verifySig1: (PEXPbGetDHKeyResponseBodySCip *) resp nonce2: (NSString *) nonce2 signature: (NSData *) signature;

/**
* Generates nonce for the protocol with specific size.
*
* @return
* @author ph4r05
*/
-(NSData *) generateNonce;

/**
* Generates DH key pair from the given group.
* @param groupId
* @return
*/
-(PEXDH *) generateKeyPair: (int) groupId;

/**
* Creates DiffieHellman shared key.
* Sorry for small "D", Diffie should be with big D, but naming convention...
*
* @param pair
* @param gx
*/
-(NSData *) diffieHelman: (PEXDH *) pair pubKey: (PEXDH *) gx;

/**
* Generate and store new DH key pair for particular sip user in contact list.
*
* @param sip
* @return true on success, otherwise false* @author miroc
*/
-(PEXDbDhKey *) generateDBDHKey: (NSString *) sip sipCertHash:(NSString *)sipCertHash;

/**
* Loads specific DHkey from the database.
* Sip can be null, in that case only nonce2 is used for search.
*
* @param nonce2
* @param sip
* @return
*/
-(PEXDbDhKey *) loadDHKey: (NSString *) nonce2 sip:(NSString *) sip;

/**
* Removes all DH keys for particular user.
*
* @param sip
* @return
*/
-(int) removeDHKeysForUser: (NSString *) sip;

/**
* Removes a DHKey with given nonce2
*
* @param sip
* @return
*/
-(BOOL) removeDHKey: (NSString *) nonce2;

/**
* Removes a DHKey with given nonce2s
*
* @param sip
* @return
*/
-(int) removeDHKeys: (NSArray *) nonces;

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
-(int) removeDHKeys: (NSString *) sip olderThan: (NSDate *) olderThan certHash: (NSString *) certHash;

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
    expirationLimit: (NSDate *) expirationLimit;


/**
* Returns list of a nonce2s for ready DH keys. If
* sip is not null, for a given user, otherwise for
* everybody.
*
* @param sip OPTIONAL
* @return
*/
-(NSArray *) getReadyDHKeysNonce2: (NSString *) sip;
/**
* Converts database DHKey entry to DH Key pair.
*
* @param data
* @return
*/
-(PEXDH *) getKeyPair: (PEXDbDhKey *) data;

/**
* Reconstructs DH PublicKey from byte representation.
*
* @param pk
* @return
*/
-(PEXDH *) getPubKeyFromByte: (NSData *) pk;

/**
* Reconstructs DH PrivKey from byte representation.
*
* @param pk
* @return
*/
-(PEXDH *) getPrivKeyFromByte: (NSData *) pk;

/**
* Load DH PARAMETER from file assets/dh_groups/dhparam_4096_1_0<groupNumber>.pem
*
* @param groupNumber should be between 001-256
* @return
* @author miroc
*/
-(PEXDH *) loadDHParameterSpec: (int) groupNumber;

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
-(PEXFtHolder *) createFTHolder: (PEXPbGetDHKeyResponseBodySCip *) body nonce2: (NSData *) nonce2;

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
-(NSData *) computeCi: (NSData *) c i: (int) i salt1: (NSData *) salt1 nonce2: (NSData *) nonce2;
-(void) computeCi: (PEXFtHolder *) holder;

/**
* Computes salt1=SHA256(saltb XOR nonce1)
*
* @return
*/
-(NSData *) computeSalt1: (NSData *) saltb nonce1: (NSData *) nonce1;

/**
* Reconstructs ukey from bytes.
* Used in FileTransfer protocol to contain DH public key.
*
* @param ukeyBytes
* @return
*/
-(PEXPbUploadFileKey *) reconstructUkey: (NSData *) ukeyBytes;

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
-(PEXFtHolder *) processFileTransfer: (PEXDbDhKey *) data ukey: (NSData *) ukey;

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
-(PEXFtHolder *) processFileTransfer: (PEXDbDhKey *) data saltb: (NSData *) saltb gy: (NSData *) gy encXB: (NSData *) encXB macEncXB: (NSData *) macEncXB;

/**
* Generates HMAC on the file according to the protocol.
* Produces HMAC_{key}(iv || nonce2 || file)
*
* @param is
* @param nonce2
* @return
*/
-(NSData *) generateFTFileMac: (NSInputStream *) is offset: (NSUInteger) offset key: (NSData *) key iv: (NSData *) iv nonce2: (NSData *) nonce2;

/**
* Generates HMAC on the file according to the protocol.
* Produces HMAC_{key}(iv || nonce2 || file)
*
* @param is
* @param nonce2
* @return
*/
-(NSData *) generateFTFileMacFile: (NSString *) file offset: (NSUInteger) offset key: (NSData *) key iv: (NSData *) iv nonce2: (NSData *) nonce2;

/**
* Computes hash on the file according to the protocol.
* Produces hash(iv || mac(iv, nonce2, e) || e). Uses protocol buffers to store IV and MAC.
*
* @param is
* @param nonce2
* @return
*/
-(NSData *) computeFTFileHash: (NSInputStream *) is iv: (NSData *) iv mac: (NSData *) mac;

/**
* Computes hash on the file according to the protocol.
* Produces hash(iv || mac(iv, nonce2, e) || e)
*
* @param is
* @param nonce2
* @return
*/
-(NSData *) computeFTFileHashFile: (NSString *) file iv: (NSData *) iv mac: (NSData *) mac;

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
-(NSString *) sanitizeFileName: (NSString *) fileName;
+(NSString *) sanitizeFileName: (NSString *) fileName;

/**
* Returns directory where to store generated and received files.
* @return
*/
-(NSString *) getStorageDirectory;

/**
* Returns directory where to store temporary files created during file transfer.
* @return
*/
-(NSString *) getCacheDirectory;
+(NSString *) getCacheDirectory;

/**
* Since absolute path of the directories may change with time, this takes last path component of the
* provided path and adds current FT cache directory as a prefix.
*/
+(NSString *) correctFTFile: (NSString *) path;

/**
* Returns directory where to store thumbnails sent by remote contacts. Should reside in cache directory so they
* are deleted when needed.
*
* @return
*/
-(NSString *) getThumbDirectory;
+(NSString *) getThumbDirectory;

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
-(PEXFtPreUploadFilesHolder *) ftSetFilesToSend: (PEXFtHolder *) holder params: (PEXFtUploadParams *) params;

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
-(PEXCipher *) prepareCipher: (PEXFtHolder *) holder encryption: (BOOL) encryption fileIdx: (int) fileIdx;

/**
* Returns data that should be prepended meta/archive file before sending.
*/
-(NSData *) getFilePrependRecord: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx;

/**
* Returns file name to store downloaded files.
*
*/
+(NSString *) getFileNameForDownload: (NSUInteger) fileIdx nonce2: (NSString *) nonce2;

/**
* Returns file name to store decrypted versions.
*/
-(NSString *) getFileNameForDecrypted: (NSUInteger) fileIdx nonce2: (NSString *) nonce2;

/**
* Returns file name to store packed file.
*/
-(NSString *) getFileNameForPacked: (NSUInteger) fileIdx nonce2: (NSString *) nonce2;

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
                 totalSize: (NSNumber *) totalSize;

/**
* Verifies MAC & decrypts file pointed by holder.
* After decryption new filename pointing at decrypted file is stored to the holder,
* old file is deleted.
*
* @param holder
*/
-(BOOL) decryptFile: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx;

/**
* Builds meta file from the holder.
*
* Assumes file was already decrypted and holder points at decrypted meta file.
*
* @param holder
* @return
*/
-(PEXPbMetaFile *) reconstructMetaFile: (PEXFtHolder *) holder;
-(PEXPbMetaFile *) reconstructMetaFileOld: (PEXFtHolder *) holder;

/**
* Extracts ZIP archive at given file with options.
* Can be used either for meta or pack archives.
*/
-(PEXFtUnpackingResult *) unzipArchiveAtFile: (NSString *) file options: (PEXFtUnpackingOptions *) options;

/**
* Unzips archive file sent in file transfer protocol.
* Archive is assumed to have only flat structure (no directories are allowed).
*
*
* @param holder
* @return
*/
-(PEXFtUnpackingResult *) unzipArchive: (PEXFtHolder *) holder options: (PEXFtUnpackingOptions *) options;

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
-(PEXFtUploadResult *) uploadFile: (PEXFtHolder *) holder;

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
-(PEXFtFileDownloadResult *) downloadFile: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx allowRedownload: (BOOL) allowReDownload;

+(void) cleanDownloadFile: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx;
+(void) cleanFile: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx;
+(void) cleanAllFiles: (PEXFtHolder *) holder fileIdx: (NSUInteger) fileIdx;

/**
* Cleans all temporary files related to this session.
* @param holder
*/
-(void) cleanFiles: (PEXFtHolder *) holder;

/**
* Converts base64 string to a file name (removes /)
* Substitution:
* / --> _
* + --> -
*
* @param based
* @return
*/
+(NSString *) getFilenameFromBase64: (NSString *) based;

/**
* Determines whether was upload sucessful.
* @param res
* @return
*/
- (BOOL) wasUploadSuccessful: (PEXFtUploadResult *) res;

/**
* Returns service error code, if available, null otherwise.
* @param res
* @return
*/
-(NSInteger) getUploadErrorCode: (PEXFtUploadResult *) res;

/**
* Dumps holder to a string.
* For debugging. Do not use in production (deprecation flag).
*
* @deprecated
* @param holder
* @return
*/
+(NSString *) dumpHolder: (PEXFtHolder *) holder;

/**
* Determines whether to use compression in the file transfer
* @param extension
* @return
*/
-(BOOL) useCompression: (NSString *) extension;

+ (NSString *) getRefreshedThumbnailPath: (NSString * const) oldPath;

@end