module blockchess::game;

use std::string::{String, utf8};
use std::option::{some, none, is_some, is_none, borrow};
use sui::clock::{Clock, timestamp_ms};
use sui::event;
use sui::object::{new, uid_to_inner};
use sui::tx_context::sender;

// === Enums ===

public enum Color has copy, drop, store {
    white,
    black,
}

public enum GameMode has copy, drop, store {
    Solo,
    Versus,
}

public enum GameDifficulty has copy, drop, store {
    Easy,
    Medium,
    Hard,
}

public enum GameStatus has copy, drop, store {
    Active,
    Finished,
    Cancelled,
}

// === Errors ===

const E_INVALID_GAME_MODE: u64 = 0;
const E_INVALID_PLAYER: u64 = 1;
const E_GAME_NOT_ACTIVE: u64 = 2;
const E_PLAYER2_ALREADY_SET: u64 = 3;
const E_ONLY_VERSUS_MODE: u64 = 4;

// === Structs ===

public struct Game has key, store {
    id: sui::object::UID,
    player1: address,
    player2: std::option::Option<address>,
    mode: GameMode,
    difficulty: GameDifficulty,
    status: GameStatus,
    created_at: u64,
    updated_at: std::option::Option<u64>,
    ended_at: std::option::Option<u64>,
    winner: std::option::Option<address>,
    result: std::option::Option<String>,
    final_fen: std::option::Option<String>,
    moves_count: u8,
    last_move_hash: std::option::Option<String>
}

// === Events ===

public struct GameCreated has copy, drop {
    game_id: sui::object::ID,
    player1: address,
    mode: GameMode,
    difficulty: GameDifficulty,
    created_at: u64,
}

public struct PlayerJoined has copy, drop {
    game_id: sui::object::ID,
    player2: address,
    created_at: u64,
}

public struct MovePlayed has copy, drop {
    game_id: sui::object::ID,
    player: address,
    is_computer: bool,
    move_number: u8,
    move_san: String,
    fen: String,
    move_hash: String,
    timestamp: u64,
}

public struct GameEnded has copy, drop {
    game_id: sui::object::ID,
    winner: std::option::Option<address>,
    result: String,
    final_fen: String,
    moves_count: u8,
    ended_at: u64,
}

public struct GameCancelled has copy, drop {
    game_id: sui::object::ID,
    cancelled_at: u64,
}

// === Helper Functions ===

public fun game_mode_solo(): GameMode {
    GameMode::Solo
}

public fun game_mode_versus(): GameMode {
    GameMode::Versus
}

public fun difficulty_easy(): GameDifficulty {
    GameDifficulty::Easy
}

public fun difficulty_medium(): GameDifficulty {
    GameDifficulty::Medium
}

public fun difficulty_hard(): GameDifficulty {
    GameDifficulty::Hard
}

// === Security Helper Functions ===

/// Verify that the given address is a player in the game
fun is_player(game: &Game, player: address): bool {
    if (player == game.player1) {
        true
    } else if (game.player2.is_some()) {
        player == *game.player2.borrow()
    } else {
        false
    }
}

// === Main Functions ===

/// Creates a new chess game on the Sui blockchain
/// 
/// This function creates a shareable Game object that can be accessed by multiple players.
/// The game is created as a shared object, allowing both players to interact with it.
/// 
/// @param mode - Game mode: 0 = Solo, 1 = Versus
/// @param difficulty - Difficulty level: 0 = Easy, 1 = Medium, 2 = Hard
/// @param clock - Sui Clock object for timestamping
/// @returns A shared Game object that can be accessed by all players
public fun create_game(
    mode: u8,
    difficulty: u8,
    clock: &Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    let game_id = new(ctx);
    let id_copy = uid_to_inner(&game_id);
    let player1 = sender(ctx);
    let created_at = timestamp_ms(clock);

    // Convert u8 to enum
    let game_mode = if (mode == 0) {
        GameMode::Solo
    } else if (mode == 1) {
        GameMode::Versus
    } else {
        abort E_INVALID_GAME_MODE
    };

    let game_difficulty = if (difficulty == 0) {
        GameDifficulty::Easy
    } else if (difficulty == 1) {
        GameDifficulty::Medium
    } else if (difficulty == 2) {
        GameDifficulty::Hard
    } else {
        abort E_INVALID_GAME_MODE
    };

    let player2 = if (game_mode == GameMode::Solo) {
        // For solo mode, player2 is the computer (represented as none initially)
        none()
    } else {
        none()
    };

    let game = Game {
        id: game_id,
        player1,
        player2,
        mode: game_mode,
        difficulty: game_difficulty,
        status: GameStatus::Active,
        created_at,
        updated_at: none(),
        ended_at: none(),
        winner: none(),
        result: none(),
        final_fen: none(),
        moves_count: 0,
        last_move_hash: none()
    };

    event::emit(GameCreated {
        game_id: id_copy,
        player1,
        mode: game_mode,
        difficulty: game_difficulty,
        created_at,
    });

    sui::transfer::share_object(game);
}

public fun join_game(
    game: &mut Game,
    player2: address,
    clock: &Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    let sender_addr = sender(ctx);
    assert!(game.mode == GameMode::Versus, E_ONLY_VERSUS_MODE);
    assert!(game.player2.is_none(), E_PLAYER2_ALREADY_SET);
    assert!(game.status == GameStatus::Active, E_GAME_NOT_ACTIVE);
    assert!(sender_addr == player2, E_INVALID_PLAYER);

    event::emit(PlayerJoined {
        game_id: uid_to_inner(&game.id),
        player2,
        created_at: timestamp_ms(clock),
    });

    game.player2 = some(player2);
}

public fun make_move(
    game: &mut Game,
    is_computer: bool,
    move_san: String,
    fen: String,
    move_hash: String,
    clock: &Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    assert!(game.status == GameStatus::Active, E_GAME_NOT_ACTIVE);

    let player = sender(ctx);
    assert!(is_player(game, player), E_INVALID_PLAYER);
    
    game.moves_count = game.moves_count + 1;
    game.last_move_hash = some(move_hash);

    event::emit(MovePlayed {
        game_id: uid_to_inner(&game.id),
        player,
        is_computer,
        move_number: game.moves_count,
        move_san,
        fen,
        move_hash,
        timestamp: timestamp_ms(clock),
    });
}

/// Ends a game and records the final result
/// 
/// This function supports both direct calls by players and sponsored transactions
/// where a server ends the game on behalf of a player. This enables transaction
/// sponsoring where the server pays gas fees for game completion.
/// 
/// Security checks:
/// - Only active games can be ended
/// - Either the sender must be a player, or the winner (if specified) must be a valid player
/// - This allows sponsored transactions where the server calls end_game with a valid winner
public fun end_game(
    game: &mut Game,
    winner: std::option::Option<address>,
    result: String,
    final_fen: String,
    clock: &Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    let sender_addr = sender(ctx);
    assert!(game.status == GameStatus::Active, E_GAME_NOT_ACTIVE);
    
    // Security: Allow ending game if:
    // 1. Sender is a player (direct call by one of the game participants), OR
    // 2. Winner is specified and is a valid player (sponsored transaction where server ends game for a player)
    // 
    // This design enables transaction sponsoring:
    // - Players can end games directly (paying their own gas)
    // - Server can end games on behalf of players (paying gas for them)
    // - The winner validation ensures only game participants can win
    let sender_is_player = is_player(game, sender_addr);
    let winner_is_valid = if (winner.is_some()) {
        let winner_addr = *winner.borrow();
        is_player(game, winner_addr)
    } else {
        true // No winner specified (draw), so this check passes
    };
    
    assert!(sender_is_player || winner_is_valid, E_INVALID_PLAYER);
    
    // Validate winner is a player in the game if specified
    if (winner.is_some()) {
        let winner_addr = *winner.borrow();
        assert!(is_player(game, winner_addr), E_INVALID_PLAYER);
    };

    let ended_at = timestamp_ms(clock);

    game.status = GameStatus::Finished;
    game.ended_at = some(ended_at);
    game.winner = winner;
    game.result = some(result);
    game.final_fen = some(final_fen);

    event::emit(GameEnded {
        game_id: uid_to_inner(&game.id),
        winner,
        result,
        final_fen,
        moves_count: game.moves_count,
        ended_at,
    });

    // Transfer ownership back to player1 for read-only access
    // Note: In Sui, we don't need to explicitly transfer back as the game object
    // remains accessible to the original owner
}

public fun cancel_game(game: &mut Game, clock: &Clock, ctx: &mut sui::tx_context::TxContext) {
    let sender_addr = sender(ctx);
    assert!(game.status == GameStatus::Active, E_GAME_NOT_ACTIVE);
    assert!(is_player(game, sender_addr), E_INVALID_PLAYER);

    let cancelled_at = timestamp_ms(clock);
    game.status = GameStatus::Cancelled;

    event::emit(GameCancelled {
        game_id: uid_to_inner(&game.id),
        cancelled_at,
    });
}

// === View Functions ===

public fun get_summary(
    game: &Game,
): (address, std::option::Option<address>, std::option::Option<address>, String, std::option::Option<String>) {
    let status_str = if (game.status == GameStatus::Active) {
        b"Active"
    } else if (game.status == GameStatus::Finished) {
        b"Finished"
    } else {
        b"Cancelled"
    };

    (game.player1, game.player2, game.winner, utf8(status_str), game.result)
}

public fun get_game_id(game: &Game): sui::object::ID {
    uid_to_inner(&game.id)
}

public fun get_moves_count(game: &Game): u8 {
    game.moves_count
}

public fun is_finished(game: &Game): bool {
    game.status == GameStatus::Finished
}

public fun is_cancelled(game: &Game): bool {
    game.status == GameStatus::Cancelled
}
