import Beyond from "../../contracts/Beyond.cdc"

pub fun main(address: Address): Beyond.Affiliate? {
    return Beyond.getAffiliateByAddress(address: address)!
}