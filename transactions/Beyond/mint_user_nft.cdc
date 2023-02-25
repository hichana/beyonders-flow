import NonFungibleToken from "../../contracts/core/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/core/MetadataViews.cdc"
import FlowToken from "../../contracts/core/FlowToken.cdc"
import Beyond from "../../contracts/Beyond.cdc"

transaction(mintPrice: UFix64) {

    let buyerCollection: &{NonFungibleToken.CollectionPublic}
    let mintPrice: UFix64
    let buyerPaymentVault: &FlowToken.Vault

    prepare(signer: AuthAccount) {

        self.mintPrice = mintPrice

        if signer.borrow<&Beyond.Collection>(from: Beyond.CollectionStoragePath) == nil {
            signer.save(<-Beyond.createEmptyCollection(), to: Beyond.CollectionStoragePath)
        }

        if signer.getLinkTarget(Beyond.CollectionPublicPath) == nil {
            signer.link<&Beyond.Collection{Beyond.BeyondNFTCollectionPublic, NonFungibleToken.CollectionPublic}>(Beyond.CollectionPublicPath, target: Beyond.CollectionStoragePath)
        }

        self.buyerCollection = signer.borrow<&Beyond.Collection{NonFungibleToken.CollectionPublic}>(
            from: Beyond.CollectionStoragePath
        ) ?? panic("Cannot borrow Beyond collection receiver capability from signer")

        self.buyerPaymentVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Can't borrow the Flow Token vault for the main payment from acct storage")
    }

    execute {
        Beyond.mintNFT(
            recipient: self.buyerCollection,
            payment: <- self.buyerPaymentVault.withdraw(amount: self.mintPrice)
        )
    }
}
 