import NonFungibleToken from "./core/NonFungibleToken.cdc"
import FlowToken from "./core/FlowToken.cdc"
import MetadataViews from "./core/MetadataViews.cdc"
import FungibleToken from "./core/FungibleToken.cdc"

pub contract Beyond: NonFungibleToken {

    /// Total supply of ExampleNFTs in existence
    pub var totalSupply: UInt64

    access(account) var paymentRecipient: Address
    access(account) var mintPrice: UFix64
    access(contract) let affiliatesByUUID: {UInt64: Affiliate}
    access(contract) let affiliatesByAddress: {Address: UInt64}

    pub struct Affiliate{
        pub var payoutRecipient: Address

        init(payoutRecipient: Address) {
            self.payoutRecipient = payoutRecipient
        }

        pub fun changeRecipientAddress(newRecipient: Address) {
            self.payoutRecipient = newRecipient
        }

    }

    /// The event that is emitted when the contract is created
    pub event ContractInitialized()

    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)

    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    /// The core resource that represents a Non Fungible Token. 
    /// New instances will be created
    /// and stored in the Collection resource
    ///
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        
        /// The unique ID that each NFT has
        pub let id: UInt64

        /// Metadata fields
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        access(self) let metadata: {String: AnyStruct}
   
        init(
            id: UInt64,
            name: String,
            description: String,
            thumbnail: String,
            metadata: {String: AnyStruct},
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.metadata = metadata
        }

        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type] {
            // note, we don't have a royalties receiver as our NFTs are meant for registering members only
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        /// Function that resolves a metadata view for this token.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "Beyond NFT Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://beyond.casa/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Beyond.CollectionStoragePath,
                        publicPath: Beyond.CollectionPublicPath,
                        providerPath: /private/beyondCollection,
                        publicCollection: Type<&Beyond.Collection{Beyond.BeyondNFTCollectionPublic}>(),
                        publicLinkedType: Type<&Beyond.Collection{Beyond.BeyondNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Beyond.Collection{Beyond.BeyondNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-Beyond.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://i0.wp.com/post.medicalnewstoday.com/wp-content/uploads/sites/3/2022/07/what_to_know_apples_green_red_1296x728_header-1024x575.jpg"
                        ),
                        mediaType: "image/jpeg"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The Beyond Collection",
                        description: "Spread the word about NFT projects you love, get paid and go beyond just being a collector.",
                        externalURL: MetadataViews.ExternalURL("https://beyond.casa"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/BeyondNFTFlow")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime to mark it as "Date" type and still use 'dictToTraits'
                    let excludedTraits = ["mintedTime"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    // add back mintedTime, which is a unix timestamp. Mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)
                    
                    return traitsView
            }
            return nil
        }
    }

    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface BeyondNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowBeyondNFT(id: UInt64): &Beyond.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Beyond reference: the ID of the returned reference is incorrect"
            }
        }
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: BeyondNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        /// Removes an NFT from the collection and moves it to the caller
        ///
        /// @param withdrawID: The ID of the NFT that wants to be withdrawn
        /// @return The NFT resource that has been taken out of the collection
        ///
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        /// Adds an NFT to the collections dictionary and adds the ID to the id array
        ///
        /// @param token: The NFT resource to be included in the collection
        /// 
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Beyond.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        /// Helper method for getting the collection IDs
        ///
        /// @return An array containing the IDs of the NFTs in the collection
        ///
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///        
        pub fun borrowBeyondNFT(id: UInt64): &Beyond.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Beyond.NFT
            }

            return nil
        }

        /// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
        /// interface so that the caller can retrieve the views that the NFT
        /// is implementing and resolve them
        ///
        /// @param id: The ID of the wanted NFT
        /// @return The resource reference conforming to the Resolver interface
        /// 
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let exampleNFT = nft as! &Beyond.NFT
            return exampleNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    /// Allows anyone to create a new empty collection
    ///
    /// @return The new Collection resource
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    /// Mints a new NFT with a new ID and deposit it in the
    /// recipients collection using their collection reference
    ///
    /// @param recipient: A capability to the collection where the new NFT will be deposited
    /// @param royalties: An array of Royalty structs, see MetadataViews docs 
    ///     
    pub fun mintNFT(
        recipient: &{NonFungibleToken.CollectionPublic},
        payment: @FungibleToken.Vault
    ) {
        pre {
            payment.balance >= Beyond.mintPrice: "Payment amount is not correct"
        }

        let metadata: {String: AnyStruct} = {}
        let currentBlock = getCurrentBlock()
        metadata["mintedBlock"] = currentBlock.height
        metadata["mintedTime"] = currentBlock.timestamp
        metadata["minter"] = recipient.owner!.address

        // accept payment
        let paymentRecipientRef = getAccount(Beyond.paymentRecipient).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()
            ?? panic("couldn't borrow Flow token receiver cap")
        paymentRecipientRef.deposit(from: <-payment)

        // create a new NFT
        var newNFT <- create NFT(
            id: Beyond.totalSupply,
            name: "Beyond NFT",
            description: "Spread the word about NFT projects you love, get paid and go beyond just being a collector.",
            thumbnail: "https://upload.wikimedia.org/wikipedia/commons/1/15/Cat_August_2010-4.jpg",
            metadata: metadata,
        )

        // add the affiliate, initially payout address is minter's address
        Beyond.affiliatesByUUID.insert(key: newNFT.uuid, Beyond.Affiliate(paymentRecipient: recipient.owner!.address))
        Beyond.affiliatesByAddress.insert(key: recipient.owner!.address, newNFT.uuid)

        // deposit it in the recipient's account using their reference
        recipient.deposit(token: <-newNFT)

        Beyond.totalSupply = Beyond.totalSupply + UInt64(1)
    }

    pub resource Admin{

        pub fun changeMintPrice(newMintPrice: UFix64) {
            Beyond.mintPrice = newMintPrice
        }

        pub fun changePaymentRecipient(newPaymentRecipient: Address) {

            // borrow the receiver cap and check it
            let flowTokenReceiverCap = getAccount(newPaymentRecipient).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            assert(flowTokenReceiverCap.borrow() != nil, message: "Missing or mis-typed FlowToken receiver")

            Beyond.paymentRecipient = newPaymentRecipient
        }

    }

    pub fun getAllAffiliatesByUUID(): {UInt64: Beyond.Affiliate} {
        return Beyond.affiliatesByUUID
    }

    pub fun getAffiliatesByUUIDKeys(): [UInt64] {
        return Beyond.affiliatesByUUID.keys
    }

    pub fun getAffiliateByUUID(uuid: UInt64): Beyond.Affiliate? {
        return Beyond.affiliatesByUUID[uuid]
    }

    pub fun getAllAffiliatesByAddress(): {Address: UInt64} {
        return Beyond.affiliatesByAddress
    }

    pub fun getAffiliatesByAddressKeys(): [Address] {
        return Beyond.affiliatesByAddress.keys
    }

    pub fun getAffiliateByAddress(address: Address): Beyond.Affiliate? {
        let uuid = Beyond.affiliatesByAddress[address]!
        return Beyond.getAffiliateByUUID(uuid: uuid)!
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        self.paymentRecipient = self.account.address
        self.mintPrice = 1.0
        self.affiliatesByUUID = {}
        self.affiliatesByAddress = {}

        // Set the named paths
        self.CollectionStoragePath = /storage/beyondCollection
        self.CollectionPublicPath = /public/beyondCollection
        self.AdminStoragePath = /storage/beyondAdmin

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&Beyond.Collection{NonFungibleToken.CollectionPublic, Beyond.BeyondNFTCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create an Admin resource and save it to storage
        let admin <- create Admin()
        self.account.save(<-admin, to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}