//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

enum FogViewUtils {
    static func encryptTxOutRecord(
        txOutRecord: FogView_TxOutRecord,
        publicAddress: PublicAddress,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<Data, InvalidInputError> {
        VersionedCryptoBox.encrypt(
            plaintext: txOutRecord.serializedDataInfallible,
            publicKey: publicAddress.viewPublicKeyTyped,
            rng: rng,
            rngContext: rngContext)
    }

    static func decryptTxOutRecord(
        ciphertext: Data,
        accountKey: AccountKey
    ) -> Result<FogView_TxOutRecord, VersionedCryptoBoxError> {
        VersionedCryptoBox.decrypt(
            ciphertext: ciphertext,
            privateKey: accountKey.subaddressViewPrivateKey
        ).flatMap { decrypted in
            guard let txOutRecord = try? FogView_TxOutRecord(serializedData: decrypted) else {
                return .failure(.invalidInput("FogView_TxOutRecord deserialization failed. " +
                    "serializedData: \(redacting: decrypted.base64EncodedString())"))
            }
            return .success(txOutRecord)
        }
    }
    
    static func decryptTxOutRecordImproved(
        ciphertext: Data,
        accountKey: AccountKey
    ) -> Result<FogView_TxOutRecord, VersionedCryptoBoxError> {
        let defaultDecrypt = VersionedCryptoBox.decrypt(
            ciphertext: ciphertext,
            privateKey: accountKey.subaddressViewPrivateKey
        )
        
        let changeDecrypt = VersionedCryptoBox.decrypt(
            ciphertext: ciphertext,
            privateKey: accountKey.changeSubaddressViewPrivateKey
        )
        
        let changeResult : Result<FogView_TxOutRecord, VersionedCryptoBoxError> = changeDecrypt.flatMap { decrypted in
            guard let txOutRecord = try? FogView_TxOutRecord(serializedData: decrypted) else {
                return .failure(.invalidInput("FogView_TxOutRecord deserialization failed. " +
                    "serializedData: \(redacting: decrypted.base64EncodedString())"))
            }
            return .success(txOutRecord)
        }
        
        let defaultResult : Result<FogView_TxOutRecord, VersionedCryptoBoxError> = defaultDecrypt.flatMap { decrypted in
            guard let txOutRecord = try? FogView_TxOutRecord(serializedData: decrypted) else {
                return .failure(.invalidInput("FogView_TxOutRecord deserialization failed. " +
                    "serializedData: \(redacting: decrypted.base64EncodedString())"))
            }
            return .success(txOutRecord)
        }
        
        switch (changeResult, defaultResult) {
        case (.failure(_), .failure(let defaultError)):
            return .failure(defaultError)
        case (.failure(_), .success(let defaultRecord)):
            return .success(defaultRecord)
        case (.success(let changeRecord), .failure(_)):
            return .success(changeRecord)
        case (.success(_), .success(let defaultRecord)):
            return .success(defaultRecord)
        }
    }
}
