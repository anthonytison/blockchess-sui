#[test_only]
module blockchess::tests;

use blockchess::game::{Self, Game};
use sui::clock::{create_for_testing, destroy_for_testing};
use sui::test_scenario::{begin, end, next_tx, ctx, take_shared, return_shared};
use std::string::utf8;
use std::option::some;

#[test]
fun test_create_solo_game() {
    let mut scenario = begin(@0x1);
    let ctx = ctx(&mut scenario);
    
    let clock = create_for_testing(ctx);
    
    game::create_game(
        0, // Solo mode
        0, // Easy difficulty
        &clock,
        ctx
    );
    
    destroy_for_testing(clock);
    end(scenario);
}

#[test]
fun test_create_versus_game() {
    let mut scenario = begin(@0x1);
    let ctx = ctx(&mut scenario);
    
    let clock = create_for_testing(ctx);
    
    game::create_game(
        1, // Versus mode
        1, // Medium difficulty
        &clock,
        ctx
    );
    
    destroy_for_testing(clock);
    end(scenario);
}

#[test]
fun test_join_versus_game() {
    let mut scenario = begin(@0x1);
    
    // Create game
    {
        let ctx = ctx(&mut scenario);
        let clock = create_for_testing(ctx);
        
        game::create_game(
            1, // Versus mode
            2, // Hard difficulty
            &clock,
            ctx
        );
        
        destroy_for_testing(clock);
    };
    
    // Join game as player2
    next_tx(&mut scenario, @0x2);
    {
        let mut game_obj = take_shared<Game>(&scenario);
        let ctx = ctx(&mut scenario);
        let clock = create_for_testing(ctx);
        
        game::join_game(&mut game_obj, @0x2, &clock, ctx);
        
        destroy_for_testing(clock);
        return_shared(game_obj);
    };
    
    end(scenario);
}

#[test]
fun test_make_move() {
    let mut scenario = begin(@0x1);
    
    // Create game
    {
        let ctx = ctx(&mut scenario);
        let clock = create_for_testing(ctx);
        
        game::create_game(
            0, // Solo mode
            0, // Easy difficulty
            &clock,
            ctx
        );
        
        destroy_for_testing(clock);
    };
    
    // Make a move
    next_tx(&mut scenario, @0x1);
    {
        let mut game_obj = take_shared<Game>(&scenario);
        let ctx = ctx(&mut scenario);
        let clock = create_for_testing(ctx);
        
        game::make_move(
            &mut game_obj,
            true,
            utf8(b"e4"),
            utf8(b"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"),
            utf8(b"move_hash_1"),
            &clock,
            ctx
        );
        
        assert!(game::get_moves_count(&game_obj) == 1, 0);
        
        destroy_for_testing(clock);
        return_shared(game_obj);
    };
    
    end(scenario);
}

#[test]
fun test_end_game() {
    let mut scenario = begin(@0x1);
    
    // Create game
    {
        let ctx = ctx(&mut scenario);
        let clock = create_for_testing(ctx);
        
        game::create_game(
            0, // Solo mode
            0, // Easy difficulty
            &clock,
            ctx
        );
        
        destroy_for_testing(clock);
    };
    
    // End game
    next_tx(&mut scenario, @0x1);
    {
        let mut game_obj = take_shared<Game>(&scenario);
        let ctx = ctx(&mut scenario);
        let clock = create_for_testing(ctx);
        
        game::end_game(
            &mut game_obj,
            some(@0x1),
            utf8(b"1-0"),
            utf8(b"final_fen_position"),
            &clock,
            ctx
        );
        
        assert!(game::is_finished(&game_obj), 0);
        
        destroy_for_testing(clock);
        return_shared(game_obj);
    };
    
    end(scenario);
}

#[test]
fun test_cancel_game() {
    let mut scenario = begin(@0x1);
    
    // Create game
    {
        let ctx = ctx(&mut scenario);
        let clock = create_for_testing(ctx);
        
        game::create_game(
            1, // Versus mode
            1, // Medium difficulty
            &clock,
            ctx
        );
        
        destroy_for_testing(clock);
    };
    
    // Cancel game
    next_tx(&mut scenario, @0x1);
    {
        let mut game_obj = take_shared<Game>(&scenario);
        let ctx = ctx(&mut scenario);
        let clock = create_for_testing(ctx);
        
        game::cancel_game(&mut game_obj, &clock, ctx);
        
        assert!(game::is_cancelled(&game_obj), 0);
        
        destroy_for_testing(clock);
        return_shared(game_obj);
    };
    
    end(scenario);
}