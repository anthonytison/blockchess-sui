# BlockChess Sui Smart Contracts

![Sui Logo](https://sui.io/images/sui-logo.svg)

BlockChess smart contracts built on the **Sui blockchain** using the **Move programming language**. This package contains the on-chain game logic, state management, and NFT badge reward system.

## What is Sui?

**Sui** is a high-performance Layer 1 blockchain designed for instant settlement and low transaction costs. Built by Mysten Labs, Sui introduces several innovations that make it ideal for gaming and decentralized applications:

### Key Features

- **Object-Centric Model**: Sui uses objects instead of accounts, making it intuitive for representing game assets and state
- **Parallel Execution**: Transactions that don't conflict can be processed in parallel, enabling high throughput
- **Low Latency**: Sub-second finality with instant transaction confirmation
- **Low Gas Fees**: Efficient resource management results in minimal transaction costs
- **Move Language**: A safe, type-safe programming language specifically designed for blockchain development

### Why Sui for BlockChess?

1. **Game State as Objects**: Each chess game is a shareable object on-chain, allowing multiple players to interact with it
2. **Event-Driven Architecture**: Move events enable efficient tracking of game state changes and moves
3. **NFT Support**: Native support for NFT badges as achievements, stored directly in player wallets
4. **Performance**: Fast transaction processing ensures smooth gameplay without blocking user experience
5. **Cost Efficiency**: Low gas costs make on-chain game operations economically viable

## Move Programming Language

**Move** is Sui's native programming language, designed from the ground up for blockchain development:

### Key Concepts

- **Safety First**: Strong type system and compile-time checks prevent common blockchain vulnerabilities
- **Resource-Oriented**: Explicit resource handling ensures assets can't be duplicated or lost
- **Modules**: Code organization through modules with controlled access via capabilities
- **Abilities**: Objects have abilities (`key`, `store`, `copy`, `drop`) that define how they can be used
- **Ownership**: Clear ownership model - objects can be owned, shared, or immutable

### Move vs Other Languages

Unlike Solidity (Ethereum) or Rust (Solana), Move:
- Uses an object-centric model instead of account-based
- Provides built-in safety guarantees through the type system
- Has no concept of "reentrancy attacks" due to linear types
- Makes resource management explicit and safe

## Version 
**1.1**

### Version 1.1 Changes
- Added transaction sponsoring support for all functions
- Enhanced authorization checks to support sponsored transactions
- Improved security for game ending and badge minting
- Better error handling and authorization error messages

See [CHANGELOG.md](./CHANGELOG.md) for detailed changes. 

## Project Structure

```
blockchess/
├── Move.toml          # Package configuration and dependencies
├── sources/           # Move source code
│   ├── game.move     # Game state management module
│   └── badge.move    # NFT badge reward system
└── build/            # Compiled bytecode (generated)
```

### Modules

#### `game.move`
Manages chess game state on-chain:

- **Game Creation**: Create new games (Solo or Versus mode)
- **Game Joining**: Join versus games
- **Move Recording**: Record chess moves on-chain
- **Game Completion**: Finalize games with results
- **Game Cancellation**: Cancel active games
- **Events**: Emit events for all game state changes

#### `badge.move`
Handles NFT badge rewards:

- **Badge Minting**: Mint achievement badges as NFTs
- **Badge Transfer**: Transfer badges between addresses
- **Display Metadata**: Configure badge metadata (name, description, image)
- **Events**: Emit events when badges are minted

## Prerequisites

### Install Sui CLI

The Sui CLI is required to build, test, and deploy Move packages.

#### macOS / Linux

```bash
curl -fsSL https://get.sui.io | sh
```

#### Windows

```powershell
# Using PowerShell
irm https://get.sui.io | iex
```

#### Manual Installation

1. Visit [Sui Installation Guide](https://docs.sui.io/build/install)
2. Download the appropriate binary for your platform
3. Add to your PATH

**Verify Installation**:
```bash
sui --version
```

### Additional Tools (Optional)

- **Rust**: Required if building Sui from source
- **Git**: For cloning dependencies
- **IDE Extensions**: Move language support for VS Code, IntelliJ

## Quick Start

### 1. Build the Package

```bash
cd back/blockchess
sui move build
```

This will:
- Compile all Move modules
- Resolve dependencies
- Generate bytecode in `build/` directory
- Perform type checking and security analysis

### 2. Run Tests

```bash
sui move test
```

Run all unit tests defined in `sources/tests.move`:

- `test_create_solo_game()` - Test solo game creation
- `test_create_versus_game()` - Test versus game creation
- `test_join_versus_game()` - Test joining a game
- `test_make_move()` - Test recording moves
- `test_end_game()` - Test game completion
- `test_cancel_game()` - Test game cancellation

**Test Output Example**:
```
Running Move unit tests
[ PASS    ] blockchess::tests::test_create_solo_game
[ PASS    ] blockchess::tests::test_create_versus_game
[ PASS    ] blockchess::tests::test_join_versus_game
[ PASS    ] blockchess::tests::test_make_move
[ PASS    ] blockchess::tests::test_end_game
[ PASS    ] blockchess::tests::test_cancel_game

Test result: OK. Total tests: 6; passed: 6
```

### 3. Deploy to Local Network

#### Start Local Sui Network

```bash
# Start Sui node with faucet (for test SUI)
sui start --with-faucet

# Or with indexer and GraphQL (recommended)
RUST_LOG="off,sui_node=info" sui start \
  --with-faucet \
  --force-regenesis \
  --with-indexer \
  --with-graphql
```

This starts a local Sui network with:
- **RPC**: `http://127.0.0.1:9000`
- **GraphQL**: `http://127.0.0.1:8000/graphql` (if enabled)
- **Faucet**: `http://127.0.0.1:9123/gas`

#### Get Test SUI (Local Network)

```bash
# Request test SUI from faucet
curl -X POST http://127.0.0.1:9123/gas \
  -H "Content-Type: application/json" \
  -d '{"FixedAmountRequest": {"recipient": "YOUR_ADDRESS"}}'

# Or use Sui CLI
sui client faucet
```

#### Get Your Address

```bash
# List all addresses
sui client addresses

# Get active address
sui client active-address

# Switch active address (if you have multiple)
sui client switch --address <ADDRESS>
```

#### Publish Package

```bash
# Publish to local network
sui client publish --gas-budget 100000000

# The output will include the package ID
# Example: Published Objects:
#   PackageID: 0x39c62a7fc9e67b3642f110991315d68bba52d8020c1e6600bcedccdfc6991edb
```

**Important**: Save the Package ID - you'll need it for the frontend `.env` configuration:

```env
NEXT_PUBLIC_SUI_NETWORK_LOCALNET_PACKAGE_ID=0x39c62a7fc9e67b3642f110991315d68bba52d8020c1e6600bcedccdfc6991edb
```

### 4. Deploy to Testnet

#### Setup Testnet Client

```bash
# Switch to testnet
sui client switch --env testnet

# Get testnet SUI from faucet
# Visit: https://docs.sui.io/build/faucet
# Or use: sui client faucet
```

#### Publish to Testnet

```bash
sui client publish --gas-budget 100000000
```

Save the Package ID and update your frontend configuration:

```env
NEXT_PUBLIC_SUI_NETWORK_TYPE=testnet
NEXT_PUBLIC_SUI_NETWORK_TESTNET_PACKAGE_ID=0x...
```

### 5. Deploy to Mainnet

⚠️ **Warning**: Mainnet deployments are permanent and cost real SUI. Test thoroughly on localnet/testnet first.

```bash
# Switch to mainnet
sui client switch --env mainnet

# Publish (requires mainnet SUI)
sui client publish --gas-budget 100000000
```

Update frontend configuration:

```env
NEXT_PUBLIC_SUI_NETWORK_TYPE=mainnet
NEXT_PUBLIC_SUI_NETWORK_MAINNET_PACKAGE_ID=0x...
```

## Interacting with Contracts

### Using Sui CLI

#### Create a Game

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function create_game \
  --args 0 0 \
  --gas-budget 10000000
```

Arguments:
- `0` = Solo mode (1 = Versus mode)
- `0` = Easy difficulty (1 = Medium, 2 = Hard)

#### Join a Game

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function join_game \
  --args <GAME_OBJECT_ID> <PLAYER2_ADDRESS> \
  --gas-budget 10000000
```

#### Make a Move

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function make_move \
  --args <GAME_OBJECT_ID> false "e4" "fen_string" "move_hash" \
  --gas-budget 10000000
```

#### End a Game

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function end_game \
  --args <GAME_OBJECT_ID> <WINNER_ADDRESS_OR_NULL> "1-0" "final_fen" \
  --gas-budget 10000000
```

#### Mint a Badge

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module badge \
  --function mint_badge \
  --args <REGISTRY_OBJECT_ID> <RECIPIENT_ADDRESS> "first_game" "First Game" "Description" "https://image.url" \
  --gas-budget 10000000
```

### Viewing Objects

```bash
# Get object details
sui client object <OBJECT_ID>

# View package information
sui client object <PACKAGE_ID>

# List all objects owned by address
sui client objects <ADDRESS>
```

### Viewing Events

```bash
# Query recent events
sui client events --query "MoveEvent"

# Query events for a specific package
sui client events --package <PACKAGE_ID>
```

## Development Workflow

### 1. Local Development

```bash
# Start local Sui network
sui start --with-faucet --with-indexer --with-graphql

# In another terminal, build and test
sui move build
sui move test

# Deploy to local network
sui client publish --gas-budget 100000000
```

### 2. Making Changes

1. **Edit Move files** in `sources/`
2. **Build**: `sui move build` (checks for errors)
3. **Test**: `sui move test` (ensures functionality)
4. **Deploy**: `sui client publish` (updates on-chain)

### 3. Testing Workflow

```bash
# Run all tests
sui move test

# Run specific test
sui move test --filter test_create_solo_game

# Run tests with verbose output
sui move test --verbose

# Run tests with coverage
sui move test --coverage
```

### 4. Code Quality

```bash
# Format code (if formatter available)
# sui move format

# Lint code
sui move build  # Performs static analysis

# Check for security issues
sui move build  # Includes security checks
```

## Move.toml Configuration

The `Move.toml` file configures the package:

```toml
[package]
name = "blockchess"
edition = "2024"  # Move 2024 edition
license = "MIT"
authors = ["Your Name"]

[dependencies]
# Sui framework dependency
Sui = { 
  git = "https://github.com/MystenLabs/sui.git", 
  subdir = "crates/sui-framework/packages/sui-framework", 
  rev = "framework/testnet" 
}

[addresses]
blockchess = "0x0"  # Named address (replaced at compile time)
```

**Named Addresses**: Used in Move code as `@blockchess`. Resolved during compilation based on the package's actual address on-chain.

## Understanding the Contracts

### Game Module

The `game.move` module defines:

- **Enums**: `Color`, `GameMode`, `GameDifficulty`, `GameStatus`, `GameError`
- **Structs**: `Game` (key object storing game state)
- **Events**: `GameCreated`, `PlayerJoined`, `MovePlayed`, `GameEnded`, `GameCancelled`
- **Functions**: Public functions for game operations, view functions for reading state

**Key Design Decisions**:
- Games are **shared objects** (multiple users can access)
- Events enable efficient off-chain indexing
- Clock object provides timestamping
- Move validation happens off-chain (on-chain only stores results)

### Badge Module

The `badge.move` module handles:

- **Structs**: `Badge` (NFT), `BadgeRegistry` (global registry)
- **Events**: `BadgeMinted`
- **Functions**: `mint_badge` (create NFT), `init` (package initialization)

**Key Design Decisions**:
- Badges are **owned objects** (transferred to recipient)
- Display metadata configured via Sui Display standard
- **Transaction Sponsoring Support**: Authorization logic supports three scenarios:
  1. Direct minting by authorized minter
  2. Sponsored transactions (server pays gas for authorized users)
  3. Self-minting by any user
- One-Time Witness pattern for package initialization

**Transaction Sponsoring**:
- The `mint_badge` function supports transaction sponsoring where a server account pays gas fees
- The sponsor address must match `authorized_minter` in `BadgeRegistry` for sponsored minting
- Use `set_authorized_minter` to update the authorized minter after deployment
- See `back/ws-server/src/scripts/update-authorized-minter.ts` for a helper script

## Common Commands Reference

```bash
# Build
sui move build

# Test
sui move test
sui move test --filter <test_name>
sui move test --coverage

# Client management
sui client addresses
sui client active-address
sui client switch --address <ADDRESS>
sui client switch --env <localnet|testnet|mainnet>

# Network management
sui start                          # Start local network
sui start --with-faucet            # With test SUI faucet
sui start --with-indexer           # With indexer (for GraphQL)
sui start --with-graphql           # With GraphQL server

# Publishing
sui client publish                 # Publish package
sui client publish --gas-budget <AMOUNT>

# Object queries
sui client object <OBJECT_ID>
sui client objects <ADDRESS>
sui client gas

# Transaction queries
sui client transaction <TX_DIGEST>
sui client events
sui client events --package <PACKAGE_ID>
```

## Troubleshooting

### Build Errors

**"Module not found"**:
- Ensure dependencies are correctly specified in `Move.toml`
- Run `sui move build --skip-fetch-latest-deps` to use cached dependencies

**"Invalid address"**:
- Check `[addresses]` section in `Move.toml`
- Verify named addresses match usage in code

### Deployment Errors

**"Insufficient gas"**:
- Request more SUI from faucet: `sui client faucet`
- Increase gas budget: `--gas-budget 100000000`

**"Package already exists"**:
- Use `--force` flag: `sui client publish --force`
- Or publish with a new package name

### Test Errors

**"Test scenario error"**:
- Ensure `test_scenario` is properly initialized
- Check that all objects are properly returned in test cleanup

## Resources

### Official Documentation

- [Sui Documentation](https://docs.sui.io/)
- [Move Language](https://docs.sui.io/build/move)
- [Sui CLI Reference](https://docs.sui.io/build/cli-client)
- [Sui TypeScript SDK](https://github.com/MystenLabs/sui/tree/main/sdk/typescript)

### Learning Resources

- [Sui Move by Example](https://examples.sui.io/)
- [Move Book](https://move-language.github.io/move/)
- [Sui Developer Portal](https://sui.io/developers)

### Community

- [Sui Discord](https://discord.gg/sui)
- [Sui Forum](https://forums.sui.io/)
- [Sui GitHub](https://github.com/MystenLabs/sui)

## License

MIT License - See LICENSE file for details

## Contributing

When contributing to the Move contracts:

1. **Follow Move Best Practices**: Resource safety, access control, event emission
2. **Write Tests**: All new functions should have corresponding tests
3. **Document Functions**: Use documentation comments for public functions
4. **Test Locally**: Always test on localnet before testnet/mainnet
5. **Security Review**: Review code for common Move vulnerabilities

## Next Steps

After setting up the Sui development environment:

1. ✅ Build and test the contracts locally
2. ✅ Deploy to local network and test interactions
3. ✅ Integrate with the frontend (see `front/README.md`)
4. ✅ Deploy to testnet for testing
5. ✅ Deploy to mainnet for production (when ready)

For frontend integration, see the main project README: `../../front/README.md`

