//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation


struct SenderMemo {
    let memoData: Data64
    let addressHash: AddressHash
}

struct RecoverableSenderMemo {
    let memoData: Data64
    let addressHash: AddressHash
    let accountKey: AccountKey
    let txOutPublicKey: RistrettoPublic

    init?(_ memoData: Data64, accountKey: AccountKey, txOutPublicKey: RistrettoPublic) {
        guard let addressHash = SenderMemoUtils.getAddressHash(memoData: memoData) else {
            return nil
        }
        self.memoData = memoData
        self.addressHash = addressHash
        self.accountKey = accountKey
        self.txOutPublicKey = txOutPublicKey
    }

    func recover(senderPublicAddress: PublicAddress) -> SenderMemo? {
        guard SenderMemoUtils.isValid(memoData: memoData,
                                   senderPublicAddress: senderPublicAddress,
                                   receipientViewPrivateKey: accountKey.subaddressViewPrivateKey,
                                   txOutPublicKey: txOutPublicKey)
        else {
            return nil
        }
        return SenderMemo(memoData: memoData, addressHash: addressHash)
    }
}

extension RecoverableSenderMemo: Hashable { }

extension RecoverableSenderMemo: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.memoData.hexEncodedString() == rhs.memoData.hexEncodedString()
    }
}