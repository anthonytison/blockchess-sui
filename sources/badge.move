module blockchess::badge;

use std::string::{String, utf8, into_bytes};
use sui::display;
use sui::event;
use sui::package;
use sui::url::{Url, new_unsafe_from_bytes};
use sui::object::{new, uid_to_inner};
use sui::tx_context::sender;

// === Structs ===

public struct Badge has key, store {
    id: sui::object::UID,
    badge_type: String,
    recipient: address,
    name: String,
    description: String,
    image_url: Url,
    minted_at: u64,
}

public struct BadgeRegistry has key {
    id: sui::object::UID,
    authorized_minter: address,
    // Track player statistics for badge eligibility
    // In a real implementation, this would be more sophisticated
}

// === Events ===

public struct BadgeMinted has copy, drop {
    badge_id: sui::object::ID,
    recipient: address,
    badge_type: String,
    name: String,
    minted_at: u64,
}

// === One-Time Witness ===

public struct BADGE has drop {}

// === Functions ===

fun init(otw: BADGE, ctx: &mut sui::tx_context::TxContext) {
    let keys = vector[
        utf8(b"badge_type"),
        utf8(b"name"),
        utf8(b"description"),
        utf8(b"image_url"),
    ];

    let values = vector[
        utf8(b"{badge_type}"),
        utf8(b"{name}"),
        utf8(b"{description}"),
        utf8(b"{image_url}"),
    ];

    let publisher = package::claim(otw, ctx);
    let mut display = display::new_with_fields<Badge>(&publisher, keys, values, ctx);
    display::update_version(&mut display);

    sui::transfer::public_transfer(publisher, sender(ctx));
    sui::transfer::public_transfer(display, sender(ctx));

    // Create and share the badge registry
    // The authorized minter is the deployer (whoever calls init)
    let registry = BadgeRegistry {
        id: new(ctx),
        authorized_minter: sender(ctx),
    };
    sui::transfer::share_object(registry);
}

/// Mints a new badge NFT and transfers it to the recipient
/// 
/// This function supports three authorization scenarios:
/// 1. Direct minting: The sender is the authorized minter (can mint to anyone)
/// 2. Sponsored minting: The recipient is the authorized minter (allows server to sponsor transactions for authorized users)
/// 3. Self-minting: The sender is minting for themselves (anyone can mint their own badges)
/// 
/// The authorization logic enables transaction sponsoring where a server account
/// (the sponsor) pays for gas fees on behalf of users, while still maintaining
/// security by ensuring only authorized addresses can receive badges through
/// sponsored transactions.
public fun mint_badge(
    registry: &BadgeRegistry,
    recipient: address,
    badge_type: String,
    name: String,
    description: String,
    sourceUrl: String,
    ctx: &mut sui::tx_context::TxContext,
) {
    let sender_addr = sender(ctx);
    
    // Security check: Only allow minting if one of these conditions is met:
    // 1. Sender is the authorized minter (direct minting by authorized account)
    // 2. Recipient is the authorized minter (sponsored transaction - server pays gas for authorized user)
    // 3. Sender is minting for themselves (self-mint - anyone can mint their own badges)
    // 
    // This design enables transaction sponsoring where:
    // - The server (sponsor) has the authorized_minter address
    // - The server can mint badges for users (sponsored transactions)
    // - Users can also mint their own badges directly (self-mint)
    let is_authorized_minter = sender_addr == registry.authorized_minter;
    let is_authorized_recipient = recipient == registry.authorized_minter;
    let is_self_mint = sender_addr == recipient;
    assert!(is_authorized_minter || is_authorized_recipient || is_self_mint, 1); // Error code 1: InvalidRecipient
    
    let badge_id = new(ctx);
    let id_copy = uid_to_inner(&badge_id);

    // Convert the String to bytes
    let bytes: vector<u8> = into_bytes(sourceUrl);  
    let image_url = new_unsafe_from_bytes(bytes);
    
    let badge = Badge {
        id: badge_id,
        badge_type,
        recipient,
        name,
        description,
        image_url,
        minted_at: 0, // In real implementation, use clock
    };

    event::emit(BadgeMinted {
        badge_id: id_copy,
        recipient,
        badge_type,
        name,
        minted_at: 0,
    });

    sui::transfer::transfer(badge, recipient);
}

/// Updates the authorized minter address in the BadgeRegistry
/// 
/// This function allows the current authorized minter to transfer authorization
/// to a new address. This is useful when:
/// - Deploying a new server with a different sponsor keypair
/// - Changing the server account that sponsors transactions
/// - Migrating to a new authorized minter address
/// 
/// Only the current authorized minter can call this function.
/// 
/// @param registry - The BadgeRegistry shared object to update
/// @param new_minter - The new address that will become the authorized minter
public fun set_authorized_minter(
    registry: &mut BadgeRegistry,
    new_minter: address,
    ctx: &mut sui::tx_context::TxContext,
) {
    let sender_addr = sender(ctx);
    // Security: Only the current authorized minter can update this
    assert!(sender_addr == registry.authorized_minter, 2); // Error code 2: Unauthorized
    registry.authorized_minter = new_minter;
}

// === View Functions ===

public fun get_recipient(badge: &Badge): address {
    badge.recipient
}

public fun get_name(badge: &Badge): String {
    badge.name
}

public fun get_description(badge: &Badge): String {
    badge.description
}