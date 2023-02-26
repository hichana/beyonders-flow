# EMULATOR
- need to have golang and overflow installed: https://github.com/bjartek/overflow
- emulator
    `flow emulator -v` (needs its own terminal window)
    `go run ./overflow/emulator/setup_emulator/setup_emulator.go`
    `flow dev-wallet` (needs its own terminal window)
- testnet
    `flow project deploy --network=testnet`
    `go run ./overflow/testnet/setup_testnet/setup_testnet.go`

# GETTING TEST NFTS ON TESTNET
- testnet floats: https://testnet.floats.city/
- testnet monster maker: https://monster-maker-web-client.vercel.app/view
