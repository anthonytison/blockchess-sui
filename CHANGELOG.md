# Changelog - BlockChess Move Contracts

## [1.1] - 2024

### Added
- Transaction sponsoring support - All transactions can now be sponsored by a server account
- Enhanced authorization checks in `badge.move` to support sponsored transactions
- Better error handling for mint authorization scenarios

### Changed
- **Breaking**: `mint_badge` function now allows three authorization paths:
  1. Direct minting by authorized minter
  2. Sponsored minting where recipient is the authorized minter
  3. Self-minting by any user
- Enhanced security checks in `end_game` to support sponsored transactions

### Security
- Improved authorization logic in `badge.move` for sponsored transactions
- Better validation in `game.move` for sponsored game ending transactions

### Documentation
- Added comments explaining authorization logic
- Updated README with information about transaction sponsoring
- Added documentation about badge registry and authorized minter management

### Notes
- The `authorized_minter` in `BadgeRegistry` must match the sponsor address for NFT minting to work
- Use the `set_authorized_minter` function to update the authorized minter after deployment
- The `update-authorized-minter.ts` script can be used to update the authorized minter

---

## [1.0] - Initial Release

### Features
- Game creation, joining, move recording, and game ending
- NFT badge reward system
- Support for Solo and Versus game modes
- Difficulty levels (Easy, Medium, Hard)
- Event emission for all game state changes

