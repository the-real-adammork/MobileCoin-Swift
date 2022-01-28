//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct PartialTxOut: TxOutProtocol {
    let commitment: Data32
    let maskedValue: UInt64
    let targetKey: RistrettoPublic
    let publicKey: RistrettoPublic
}

extension PartialTxOut: Equatable {}
extension PartialTxOut: Hashable {}

extension PartialTxOut {
    init(_ txOut: TxOut) {
        self.init(
            commitment: txOut.commitment,
            maskedValue: txOut.maskedValue,
            targetKey: txOut.targetKey,
            publicKey: txOut.publicKey)
    }
}

extension PartialTxOut {
    init?(_ txOut: External_TxOut) {
        guard let commitment = Data32(txOut.amount.commitment.data),
              let targetKey = RistrettoPublic(txOut.targetKey.data),
              let publicKey = RistrettoPublic(txOut.publicKey.data)
        else {
            return nil
        }
        self.init(
            commitment: commitment,
            maskedValue: txOut.amount.maskedValue,
            targetKey: targetKey,
            publicKey: publicKey)
    }

    init?(_ txOutRecord: FogView_TxOutRecord, viewKey: RistrettoPrivate) {
        guard let targetKey = RistrettoPublic(txOutRecord.txOutTargetKeyData),
              let publicKey = RistrettoPublic(txOutRecord.txOutPublicKeyData),
              let commitment = TxOutUtils.reconstructCommitment(
                                                    maskedValue: txOutRecord.txOutAmountMaskedValue,
                                                    publicKey: publicKey,
                                                    viewPrivateKey: viewKey)
        else {
            return nil
        }

        let computedCrc32 = Checksum.crc32(commitment.foundationData.bytes)
        let sentCrc32 = txOutRecord.txOutAmountCommitmentDataCrc32
        let sentCommitmentCrc32 = Checksum.crc32(txOutRecord.txOutAmountCommitmentData.bytes)
        if computedCrc32 == sentCrc32 || computedCrc32 == sentCommitmentCrc32 {
            logger.debug("commitment data equal")
        } else {
            logger.debug("commitment data NOT EQUAL")
        }
        self.init(
            commitment: commitment,
            maskedValue: txOutRecord.txOutAmountMaskedValue,
            targetKey: targetKey,
            publicKey: publicKey)
    }
}
