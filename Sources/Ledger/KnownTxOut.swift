//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct KnownTxOut: TxOutProtocol {
    private let ledgerTxOut: LedgerTxOut
    let value: UInt64
    let keyImage: KeyImage
    let subaddressIndex: Int

    init?(_ ledgerTxOut: LedgerTxOut, accountKey: AccountKey) {
        
        guard let value = ledgerTxOut.value(accountKey: accountKey) else {
            print("\n\n unable to create value from KnownTxOut \n\n")
            return nil
        }
        guard let (subaddressIndex, keyImage) = ledgerTxOut.keyImage(accountKey: accountKey) else {
            print("\n\n unable to process key image from KnownTxOut \n\n")
            return nil
            
        }
        guard let commitment = TxOutUtils.reconstructCommitment(
                                                   maskedValue: ledgerTxOut.maskedValue,
                                                   publicKey: ledgerTxOut.publicKey,
                viewPrivateKey:accountKey.viewPrivateKey) else {
            print("\n\n unable to create KnownTxOut \n\n")
            return nil
        }

        self.commitment = commitment
        self.ledgerTxOut = ledgerTxOut
        self.value = value
        self.keyImage = keyImage
        self.subaddressIndex = subaddressIndex
    }

    var commitment: Data32
    var maskedValue: UInt64 { ledgerTxOut.maskedValue }
    var targetKey: RistrettoPublic { ledgerTxOut.targetKey }
    var publicKey: RistrettoPublic { ledgerTxOut.publicKey }
    var block: BlockMetadata { ledgerTxOut.block }
    var globalIndex: UInt64 { ledgerTxOut.globalIndex }
}

extension KnownTxOut: Equatable {}
extension KnownTxOut: Hashable {}

