//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count function_default_parameter_at_end
// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

enum TransactionBuilderError: Error {
    case invalidInput(String)
    case attestationVerificationFailed(String)
}

extension TransactionBuilderError: CustomStringConvertible {
    var description: String {
        "Transaction builder error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            case .attestationVerificationFailed(let reason):
                return "Attestation verification failed: \(reason)"
            }
        }()
    }
}

final class TransactionBuilder {
    // TODO - Factor Out
    static let rthBlockVersion = UInt32(2)
    
    static func build(
        inputs: [PreparedTxInput],
        accountKey: AccountKey,
        to recipient: PublicAddress,
        memoType: MemoType,
        amount: PositiveUInt64,
        changeAddress: PublicAddress,
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) -> Result<(transaction: Transaction, receipt: Receipt), TransactionBuilderError> {
        build(
            inputs: inputs,
            accountKey: accountKey,
            outputs: [(recipient, amount)],
            memoType: memoType,
            changeAddress: changeAddress,
            fee: fee,
            tombstoneBlockIndex: tombstoneBlockIndex,
            fogResolver: fogResolver,
            rng: rng,
            rngContext: rngContext
        ).map { transaction, transactionReceipts in
            (transaction, transactionReceipts[0])
        }
    }

    static func build(
        inputs: [PreparedTxInput],
        accountKey: AccountKey,
        sendingAllTo recipient: PublicAddress,
        memoType: MemoType,
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) -> Result<(transaction: Transaction, receipt: Receipt), TransactionBuilderError> {
        positiveRemainingAmount(inputValues: inputs.map { $0.knownTxOut.value }, fee: fee)
            .flatMap { outputAmount in
                build(
                    inputs: inputs,
                    accountKey: accountKey,
                    outputs: [(recipient: recipient, amount: outputAmount)],
                    memoType: memoType,
                    fee: fee,
                    tombstoneBlockIndex: tombstoneBlockIndex,
                    fogResolver: fogResolver,
                    rng: rng,
                    rngContext: rngContext
                ).map { transaction, transactionReceipts in
                    (transaction, transactionReceipts[0])
                }
            }
    }

    static func build(
        inputs: [PreparedTxInput],
        accountKey: AccountKey,
        outputs: [(recipient: PublicAddress, amount: PositiveUInt64)],
        memoType: MemoType,
        changeAddress: PublicAddress,
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) -> Result<(transaction: Transaction, receipts: [Receipt]), TransactionBuilderError> {
        outputsAddingChangeOutputIfNeeded(
            inputs: inputs,
            outputs: outputs,
            changeAddress: changeAddress,
            fee: fee
        ).flatMap { outputs in
            build(
                inputs: inputs,
                accountKey: accountKey,
                outputs: outputs,
                memoType: memoType,
                fee: fee,
                tombstoneBlockIndex: tombstoneBlockIndex,
                fogResolver: fogResolver,
                rng: rng,
                rngContext: rngContext)
        }
    }

    static func build(
        inputs: [PreparedTxInput],
        accountKey: AccountKey,
        outputs: [(recipient: PublicAddress, amount: PositiveUInt64)],
        memoType: MemoType,
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) -> Result<(transaction: Transaction, receipts: [Receipt]), TransactionBuilderError> {
        guard UInt64.safeCompare(
                sumOfValues: inputs.map { $0.knownTxOut.value },
                isEqualToSumOfValues: outputs.map { $0.amount.value } + [fee])
        else {
            return .failure(.invalidInput("Input values != output values + fee"))
        }

        let builder = TransactionBuilder(
            fee: fee,
            tombstoneBlockIndex: tombstoneBlockIndex,
            fogResolver: fogResolver,
            memoBuilder: memoType.createMemoBuilder(accountKey: accountKey),
            blockVersion: Self.rthBlockVersion)

        for input in inputs {
            if case .failure(let error) =
                builder.addInput(preparedTxInput: input, accountKey: accountKey)
            {
                return .failure(error)
            }
        }

        return outputs.map { recipient, amount in
            builder.addOutput(
                publicAddress: recipient,
                amount: amount.value,
                rng: rng,
                rngContext: rngContext
            ).map { $0.receipt }
        }.collectResult().flatMap { receipts in
            builder.build(rng: rng, rngContext: rngContext).map { transaction in
                (transaction, receipts)
            }
        }
    }

    static func output(
        publicAddress: PublicAddress,
        amount: UInt64,
        fogResolver: FogResolver = FogResolver(),
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<TxOut, TransactionBuilderError> {
        outputWithReceipt(
            publicAddress: publicAddress,
            amount: amount,
            tombstoneBlockIndex: 0,
            fogResolver: fogResolver,
            rng: rng,
            rngContext: rngContext
        ).map { $0.txOut }
    }

    static func outputWithReceipt(
        publicAddress: PublicAddress,
        amount: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver = FogResolver(),
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<(txOut: TxOut, receipt: Receipt), TransactionBuilderError> {
        let transactionBuilder = TransactionBuilder(
            fee: 0,
            tombstoneBlockIndex: tombstoneBlockIndex,
            fogResolver: fogResolver,
            blockVersion: Self.rthBlockVersion)
        return transactionBuilder.addOutput(
            publicAddress: publicAddress,
            amount: amount,
            rng: rng,
            rngContext: rngContext)
    }

    private static func outputsAddingChangeOutputIfNeeded(
        inputs: [PreparedTxInput],
        outputs: [(recipient: PublicAddress, amount: PositiveUInt64)],
        changeAddress: PublicAddress,
        fee: UInt64
    ) -> Result<[(recipient: PublicAddress, amount: PositiveUInt64)], TransactionBuilderError> {
        remainingAmount(
            inputValues: inputs.map { $0.knownTxOut.value },
            outputValues: outputs.map { $0.amount.value },
            fee: fee
        ).map { remainingAmount in
            var outputArray = outputs
            if remainingAmount > 0, let changeAmount = PositiveUInt64(remainingAmount) {
                outputArray.append((changeAddress, changeAmount))
            }
            return outputArray
        }
    }

    private static func remainingAmount(inputValues: [UInt64], outputValues: [UInt64], fee: UInt64)
        -> Result<UInt64, TransactionBuilderError>
    {
        guard UInt64.safeCompare(
                sumOfValues: inputValues,
                isGreaterThanOrEqualToSumOfValues: outputValues + [fee])
        else {
            return .failure(.invalidInput("Total input amount < total output amount + fee"))
        }

        guard let remainingAmount = UInt64.safeSubtract(
                sumOfValues: inputValues,
                minusSumOfValues: outputValues + [fee])
        else {
            return .failure(.invalidInput("Change amount overflows UInt64"))
        }

        return .success(remainingAmount)
    }

    private static func positiveRemainingAmount(inputValues: [UInt64], fee: UInt64)
        -> Result<PositiveUInt64, TransactionBuilderError>
    {
        guard UInt64.safeCompare(sumOfValues: inputValues, isGreaterThanValue: fee) else {
            return .failure(.invalidInput("Total input amount <= fee"))
        }

        guard let remainingAmount = UInt64.safeSubtract(sumOfValues: inputValues, minusValue: fee)
        else {
            return .failure(.invalidInput("Change amount overflows UInt64"))
        }

        guard let positiveRemainingAmount = PositiveUInt64(remainingAmount) else {
            // This condition should be redundant with the first check, but we throw an error
            // anyway, rather than calling fatalError.
            return .failure(.invalidInput("Total input amount == fee"))
        }

        return .success(positiveRemainingAmount)
    }
    
    private let tombstoneBlockIndex: UInt64

    private let ptr: OpaquePointer
    
    private let memoBuilder: TxOutMemoBuilder

    private init(
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        fogResolver: FogResolver = FogResolver(),
        memoBuilder: TxOutMemoBuilder = DefaultMemoBuilder(),
        blockVersion: UInt32
    ) {
        self.tombstoneBlockIndex = tombstoneBlockIndex
        self.memoBuilder = memoBuilder
        self.ptr = memoBuilder.withUnsafeOpaquePointer { memoBuilderPtr in
            fogResolver.withUnsafeOpaquePointer { fogResolverPtr in
                // Safety: mc_transaction_builder_create should never return nil.
                withMcInfallible {
                    mc_transaction_builder_create(fee, tombstoneBlockIndex, fogResolverPtr, memoBuilderPtr, blockVersion)
                }
            }
        }
    }

    deinit {
        mc_transaction_builder_free(ptr)
    }

    private func addInput(preparedTxInput: PreparedTxInput, accountKey: AccountKey)
        -> Result<(), TransactionBuilderError>
    {
        guard let subaddressSpendPrivateKey = accountKey.subaddressSpendPrivateKey(index: preparedTxInput.subaddressIndex) else {
            return .failure(TransactionBuilderError.invalidInput("Tx subaddress index out of bounds"))
        }
        return addInput(
                preparedTxInput: preparedTxInput,
                viewPrivateKey: accountKey.viewPrivateKey,
                subaddressSpendPrivateKey: subaddressSpendPrivateKey)
    }

    private func addInput(
        preparedTxInput: PreparedTxInput,
        viewPrivateKey: RistrettoPrivate,
        subaddressSpendPrivateKey: RistrettoPrivate
    ) -> Result<(), TransactionBuilderError> {
        let ring = McTransactionBuilderRing(ring: preparedTxInput.ring)
        return viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
            subaddressSpendPrivateKey.asMcBuffer { subaddressSpendPrivateKeyPtr in
                ring.withUnsafeOpaquePointer { ringPtr in
                    withMcError { errorPtr in
                        mc_transaction_builder_add_input(
                            ptr,
                            viewPrivateKeyPtr,
                            subaddressSpendPrivateKeyPtr,
                            preparedTxInput.realInputIndex,
                            ringPtr,
                            &errorPtr)
                    }.mapError {
                        switch $0.errorCode {
                        case .invalidInput:
                            return .invalidInput("\(redacting: $0.description)")
                        default:
                            // Safety: mc_transaction_builder_add_input should not throw
                            // non-documented errors.
                            logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                        }
                    }
                }
            }
        }
    }

    private func addOutput(
        publicAddress: PublicAddress,
        amount: UInt64,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<(txOut: TxOut, receipt: Receipt), TransactionBuilderError> {
        var confirmationNumberData = Data32()
        return publicAddress.withUnsafeCStructPointer { publicAddressPtr in
            withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
                confirmationNumberData.asMcMutableBuffer { confirmationNumberPtr in
                    Data.make(withMcDataBytes: { errorPtr in
                        mc_transaction_builder_add_output(
                            ptr,
                            amount,
                            publicAddressPtr,
                            rngCallbackPtr,
                            confirmationNumberPtr,
                            &errorPtr)
                    }).mapError {
                        switch $0.errorCode {
                        case .invalidInput:
                            return .invalidInput("\(redacting: $0.description)")
                        case .attestationVerificationFailed:
                            return .attestationVerificationFailed("\(redacting: $0.description)")
                        default:
                            // Safety: mc_transaction_builder_add_output should not throw
                            // non-documented errors.
                            logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                        }
                    }
                }
            }
        }.map { txOutData in
            guard let txOut = TxOut(serializedData: txOutData) else {
                // Safety: mc_transaction_builder_add_output should always return valid data on
                // success.
                logger.fatalError("mc_transaction_builder_add_output returned invalid data: " +
                    "\(redacting: txOutData.base64EncodedString())")
            }

            let confirmationNumber = TxOutConfirmationNumber(confirmationNumberData)
            let receipt = Receipt(
                txOut: txOut,
                confirmationNumber: confirmationNumber,
                tombstoneBlockIndex: tombstoneBlockIndex)
            return (txOut, receipt)
        }
    }

    private func addChangeOutput(
        publicAddress: PublicAddress,
        accountKey: AccountKey,
        amount: UInt64,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<(txOut: TxOut, receipt: Receipt), TransactionBuilderError> {

        var confirmationNumberData = Data32()

        return McAccountKey.withUnsafePointer(
            viewPrivateKey: accountKey.viewPrivateKey,
            spendPrivateKey: accountKey.spendPrivateKey,
            reportUrl: publicAddress.fogReportUrl!.url.absoluteString,
            reportId: publicAddress.fogReportId!,
            authoritySpki: accountKey.fogAuthoritySpki!
        ) { accountKeyPtr in
                withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
                    confirmationNumberData.asMcMutableBuffer { confirmationNumberPtr in
                        Data.make(withMcDataBytes: { errorPtr in
//                            mc_transaction_builder_add_change_output(accountKeyPtr, ptr, amount, rngCallbackPtr, confirmationNumberPtr, &errorPtr)
                            mc_transaction_builder_add_change_output(
                                accountKeyPtr,
                                ptr,
                                amount,
                                rngCallbackPtr,
                                confirmationNumberPtr,
                                &errorPtr)
                        }).mapError {
                            switch $0.errorCode {
                            case .invalidInput:
                                return .invalidInput("\(redacting: $0.description)")
                            case .attestationVerificationFailed:
                                return .attestationVerificationFailed("\(redacting: $0.description)")
                            default:
                                // Safety: mc_transaction_builder_add_output should not throw
                                // non-documented errors.
                                logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                            }
                        }
                    }
                 }
        }.map { txOutData in
            guard let txOut = TxOut(serializedData: txOutData) else {
                // Safety: mc_transaction_builder_add_output should always return valid data on
                // success.
                logger.fatalError("mc_transaction_builder_add_output returned invalid data: " +
                    "\(redacting: txOutData.base64EncodedString())")
            }

            let confirmationNumber = TxOutConfirmationNumber(confirmationNumberData)
            let receipt = Receipt(
                txOut: txOut,
                confirmationNumber: confirmationNumber,
                tombstoneBlockIndex: tombstoneBlockIndex)
            return (txOut, receipt)
        }
    }

    private func build(
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<Transaction, TransactionBuilderError> {
        withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
            Data.make(withMcDataBytes: { errorPtr in
                mc_transaction_builder_build(ptr, rngCallbackPtr, &errorPtr)
            }).mapError {
                switch $0.errorCode {
                case .invalidInput:
                    return .invalidInput("\(redacting: $0.description)")
                default:
                    // Safety: mc_transaction_builder_build should not throw non-documented errors.
                    logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                }
            }
        }.map { txBytes in
            guard let transaction = Transaction(serializedData: txBytes) else {
                // Safety: mc_transaction_builder_build should always return valid data on success.
                logger.fatalError("mc_transaction_builder_build returned invalid data: " +
                    "\(redacting: txBytes.base64EncodedString())")
            }
            return transaction
        }
    }
}

private final class McTransactionBuilderRing {
    private let ptr: OpaquePointer

    init(ring: [(TxOut, TxOutMembershipProof)]) {
        // Safety: mc_transaction_builder_ring_create should never return nil.
        self.ptr = withMcInfallible(mc_transaction_builder_ring_create)

        for (txOut, membershipProof) in ring {
            addElement(txOut: txOut, membershipProof: membershipProof)
        }
    }

    deinit {
        mc_transaction_builder_ring_free(ptr)
    }

    func addElement(txOut: TxOut, membershipProof: TxOutMembershipProof) {
        txOut.serializedData.asMcBuffer { txOutBytesPtr in
            membershipProof.serializedData.asMcBuffer { membershipProofDataPtr in
                // Safety: mc_transaction_builder_ring_add_element should never return nil.
                withMcInfallible {
                    mc_transaction_builder_ring_add_element(
                        ptr,
                        txOutBytesPtr,
                        membershipProofDataPtr)
                }
            }
        }
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        try body(ptr)
    }
}
