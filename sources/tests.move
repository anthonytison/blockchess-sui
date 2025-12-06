#[test_only]
module blockchess::tests;

use blockchess::game::{Self, Game};
use sui::clock;
use sui::test_scenario;
use std::string;

#[test]
fun test_create_solo_game() {
    let mut scenario = test_scenario::begin(@0x1);
    let ctx = test_scenario::ctx(&mut scenario);
    
    let clock = clock::create_for_testing(ctx);
    
    game::create_game(
        0, // Solo mode
        0, // Easy difficulty
        &clock,
        ctx
    );
    
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
}

#[test]
fun test_create_versus_game() {
    let mut scenario = test_scenario::begin(@0x1);
    let ctx = test_scenario::ctx(&mut scenario);
    
    let clock = clock::create_for_testing(ctx);
    
    game::create_game(
        1, // Versus mode
        1, // Medium difficulty
        &clock,
        ctx
    );
    
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
}

#[test]
fun test_join_versus_game() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Create game
    {
        let ctx = test_scenario::ctx(&mut scenario);
        let clock = clock::create_for_testing(ctx);
        
        game::create_game(
            1, // Versus mode
            2, // Hard difficulty
            &clock,
            ctx
        );
        
        clock::destroy_for_testing(clock);
    };
    
    // Join game as player2
    test_scenario::next_tx(&mut scenario, @0x2);
    {
        let mut game_obj = test_scenario::take_shared<Game>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let clock = clock::create_for_testing(ctx);
        
        game::join_game(&mut game_obj, @0x2, &clock, ctx);
        
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(game_obj);
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_make_move() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Create game
    {
        let ctx = test_scenario::ctx(&mut scenario);
        let clock = clock::create_for_testing(ctx);
        
        game::create_game(
            0, // Solo mode
            0, // Easy difficulty
            &clock,
            ctx
        );
        
        clock::destroy_for_testing(clock);
    };
    
    // Make a move
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut game_obj = test_scenario::take_shared<Game>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let clock = clock::create_for_testing(ctx);
        
        game::make_move(
            &mut game_obj,
            true,
            string::utf8(b"e4"),
            string::utf8(b"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"),
            string::utf8(b"move_hash_1"),
            &clock,
            ctx
        );
        
        assert!(game::get_moves_count(&game_obj) == 1, 0);
        
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(game_obj);
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_end_game() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Create game
    {
        let ctx = test_scenario::ctx(&mut scenario);
        let clock = clock::create_for_testing(ctx);
        
        game::create_game(
            0, // Solo mode
            0, // Easy difficulty
            &clock,
            ctx
        );
        
        clock::destroy_for_testing(clock);
    };
    
    // End game
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut game_obj = test_scenario::take_shared<Game>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let clock = clock::create_for_testing(ctx);
        
        game::end_game(
            &mut game_obj,
            std::option::some(@0x1),
            string::utf8(b"1-0"),
            string::utf8(b"final_fen_position"),
            &clock,
            ctx
        );
        
        assert!(game::is_finished(&game_obj), 0);
        
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(game_obj);
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_cancel_game() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Create game
    {
        let ctx = test_scenario::ctx(&mut scenario);
        let clock = clock::create_for_testing(ctx);
        
        game::create_game(
            1, // Versus mode
            1, // Medium difficulty
            &clock,
            ctx
        );
        
        clock::destroy_for_testing(clock);
    };
    
    // Cancel game
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut game_obj = test_scenario::take_shared<Game>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let clock = clock::create_for_testing(ctx);
        
        game::cancel_game(&mut game_obj, &clock, ctx);
        
        assert!(game::is_cancelled(&game_obj), 0);
        
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(game_obj);
    };
    
    test_scenario::end(scenario);
}