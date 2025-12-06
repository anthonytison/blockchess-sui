module blockchess::game;

use std::string::String;
use sui::clock::{Self, Clock};
use sui::event;

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

public enum GameError has copy, drop {
    InvalidGameMode,
    InvalidPlayer,
    GameNotActive,
    Player2AlreadySet,
    OnlyVersusMode,
}

// === Structs ===

public struct Game has key, store {
    id: sui::object::UID,
    player1: address,
    player2: Option<address>,
    mode: GameMode,
    difficulty: GameDifficulty,
    status: GameStatus,
    created_at: u64,
    updated_at: Option<u64>,
    ended_at: Option<u64>,
    winner: Option<address>,
    result: Option<String>,
    final_fen: Option<String>,
    moves_count: u8,
    last_move_hash: Option<String>
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
    winner: Option<address>,
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

fun error_code(error: GameError): u64 {
    match (error) {
        GameError::InvalidGameMode => 0,
        GameError::InvalidPlayer => 1,
        GameError::GameNotActive => 2,
        GameError::Player2AlreadySet => 3,
        GameError::OnlyVersusMode => 4,
    }
}

// === Security Helper Functions ===

/// Verify that the given address is a player in the game
fun is_player(game: &Game, player: address): bool {
    if (player == game.player1) {
        true
    } else if (option::is_some(&game.player2)) {
        player == *option::borrow(&game.player2)
    } else {
        false
    }
}

// === Main Functions ===

public fun create_game(
    mode: u8,
    difficulty: u8,
    clock: &Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    let game_id = sui::object::new(ctx);
    let id_copy = sui::object::uid_to_inner(&game_id);
    let player1 = sui::tx_context::sender(ctx);
    let created_at = clock::timestamp_ms(clock);

    // Convert u8 to enum
    let game_mode = if (mode == 0) {
        GameMode::Solo
    } else if (mode == 1) {
        GameMode::Versus
    } else {
        abort error_code(GameError::InvalidGameMode)
    };

    let game_difficulty = if (difficulty == 0) {
        GameDifficulty::Easy
    } else if (difficulty == 1) {
        GameDifficulty::Medium
    } else if (difficulty == 2) {
        GameDifficulty::Hard
    } else {
        abort error_code(GameError::InvalidGameMode)
    };

    let player2 = if (game_mode == GameMode::Solo) {
        // For solo mode, player2 is the computer (represented as none initially)
        option::none()
    } else {
        option::none()
    };

    let game = Game {
        id: game_id,
        player1,
        player2,
        mode: game_mode,
        difficulty: game_difficulty,
        status: GameStatus::Active,
        created_at,
        updated_at: option::none(),
        ended_at: option::none(),
        winner: option::none(),
        result: option::none(),
        final_fen: option::none(),
        moves_count: 0,
        last_move_hash: option::none()
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
    let sender = sui::tx_context::sender(ctx);
    assert!(game.mode == GameMode::Versus, error_code(GameError::OnlyVersusMode));
    assert!(option::is_none(&game.player2), error_code(GameError::Player2AlreadySet));
    assert!(game.status == GameStatus::Active, error_code(GameError::GameNotActive));
    assert!(sender == player2, error_code(GameError::InvalidPlayer));

    event::emit(PlayerJoined {
        game_id: sui::object::uid_to_inner(&game.id),
        player2,
        created_at: clock::timestamp_ms(clock),
    });

    game.player2 = option::some(player2);
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
    assert!(game.status == GameStatus::Active, error_code(GameError::GameNotActive));

    let player = sui::tx_context::sender(ctx);
    assert!(is_player(game, player), error_code(GameError::InvalidPlayer));
    
    game.moves_count = game.moves_count + 1;
    game.last_move_hash = option::some(move_hash);

    event::emit(MovePlayed {
        game_id: sui::object::uid_to_inner(&game.id),
        player,
        is_computer,
        move_number: game.moves_count,
        move_san,
        fen,
        move_hash,
        timestamp: clock::timestamp_ms(clock),
    });
}

public fun end_game(
    game: &mut Game,
    winner: option::Option<address>,
    result: String,
    final_fen: String,
    clock: &Clock,
    ctx: &mut sui::tx_context::TxContext,
) {
    let sender = sui::tx_context::sender(ctx);
    assert!(game.status == GameStatus::Active, error_code(GameError::GameNotActive));
    assert!(is_player(game, sender), error_code(GameError::InvalidPlayer));
    
    // Validate winner is a player in the game if specified
    if (option::is_some(&winner)) {
        let winner_addr = *option::borrow(&winner);
        assert!(is_player(game, winner_addr), error_code(GameError::InvalidPlayer));
    };

    let ended_at = clock::timestamp_ms(clock);

    game.status = GameStatus::Finished;
    game.ended_at = option::some(ended_at);
    game.winner = winner;
    game.result = option::some(result);
    game.final_fen = option::some(final_fen);

    event::emit(GameEnded {
        game_id: sui::object::uid_to_inner(&game.id),
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
    let sender = sui::tx_context::sender(ctx);
    assert!(game.status == GameStatus::Active, error_code(GameError::GameNotActive));
    assert!(is_player(game, sender), error_code(GameError::InvalidPlayer));

    let cancelled_at = clock::timestamp_ms(clock);
    game.status = GameStatus::Cancelled;

    event::emit(GameCancelled {
        game_id: sui::object::uid_to_inner(&game.id),
        cancelled_at,
    });
}

// === View Functions ===

public fun get_summary(
    game: &Game,
): (address, option::Option<address>, option::Option<address>, String, option::Option<String>) {
    let status_str = if (game.status == GameStatus::Active) {
        b"Active"
    } else if (game.status == GameStatus::Finished) {
        b"Finished"
    } else {
        b"Cancelled"
    };

    (game.player1, game.player2, game.winner, std::string::utf8(status_str), game.result)
}

public fun get_game_id(game: &Game): sui::object::ID {
    sui::object::uid_to_inner(&game.id)
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
