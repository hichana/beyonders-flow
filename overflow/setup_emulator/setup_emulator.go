package main

import (
	o "github.com/bjartek/overflow"
)

func main() {

	// flow_network := "embedded"
	flow_network := "emulator"

	// create the overflow client
	c := o.Overflow(o.WithNetwork(flow_network), o.WithFlowForNewUsers(1000.0))

	// SERVICE ACCOUNT MINTS A BEYOND NFT
	c.Tx(
		"Beyond/mint_user_nft",
		o.WithArg("mintPrice", 1.0),
		o.WithSigner("account")).
		Print()

	// GET SERVICE ACCOUNT AFFILIATE
	c.Script(
		"Beyond/get_affiliate_by_address",
		o.WithArg("address", "account")).
		Print()

}
