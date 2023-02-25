package main

import (
	o "github.com/bjartek/overflow"
)

func main() {

	flow_network := "embedded"
	// flow_network := "emulator"

	// create the overflow client
	c := o.Overflow(o.WithNetwork(flow_network), o.WithFlowForNewUsers(1000.0))

	// USER1 MINTS A BEYOND NFT
	c.Tx(
		"Beyond/mint_user_nft",
		o.WithArg("mintPrice", 1.0),
		o.WithSigner("user1")).
		Print()

	// get user1 affiliate
	c.Script(
		"Beyond/get_affiliate_by_address",
		o.WithArg("address", "user1")).
		Print()

}
