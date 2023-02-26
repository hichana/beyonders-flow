package main

import (
	o "github.com/bjartek/overflow"
)

func main() {

	flow_network := "testnet"

	// create the overflow client
	c := o.Overflow(o.WithNetwork(flow_network), o.WithFlowForNewUsers(1000.0))

	// SERVICE ACCOUNT SELF SETS UP WITH ROYALTY RECEIVER
	c.Tx(
		"ExampleNFTs/set_up_royalty_receiver",
		o.WithArg("vaultPath", "/storage/flowTokenVault"),
		o.WithSigner("account")).
		Print()

}
