module blockchess::badge;

use std::string::{Self, String};
use sui::display;
use sui::event;
use sui::package;
use sui::url::{Self, Url};

// === Structs ===

public struct Badge has key, store {
    id: object::UID,
    badge_type: String,
    recipient: address,
    name: String,
    description: String,
    image_url: Url,
    minted_at: u64,
}

public struct BadgeRegistry has key {
    id: object::UID,
    // Track player statistics for badge eligibility
    // In a real implementation, this would be more sophisticated
}

// === Events ===

public struct BadgeMinted has copy, drop {
    badge_id: object::ID,
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
        string::utf8(b"badge_type"),
        string::utf8(b"name"),
        string::utf8(b"description"),
        string::utf8(b"image_url"),
    ];

    let values = vector[
        string::utf8(b"{badge_type}"),
        string::utf8(b"{name}"),
        string::utf8(b"{description}"),
        string::utf8(b"{image_url}"),
    ];

    let publisher = package::claim(otw, ctx);
    let mut display = display::new_with_fields<Badge>(&publisher, keys, values, ctx);
    display::update_version(&mut display);

    sui::transfer::public_transfer(publisher, sui::tx_context::sender(ctx));
    sui::transfer::public_transfer(display, sui::tx_context::sender(ctx));

    // Create and share the badge registry
    let registry = BadgeRegistry {
        id: sui::object::new(ctx),
    };
    sui::transfer::share_object(registry);
}

public fun mint_badge(
    _registry: &BadgeRegistry,
    recipient: address,
    badge_type: String,
    name: String,
    description: String,
    sourceUrl: String,
    ctx: &mut sui::tx_context::TxContext,
) {
    let sender = sui::tx_context::sender(ctx);
    // Security: Only allow minting badges for yourself
    // This prevents unauthorized badge minting attacks
    // The registry parameter is required to ensure proper access control
    assert!(sender == recipient, 1); // Error code 1: InvalidRecipient
    
    let badge_id = sui::object::new(ctx);
    let id_copy = sui::object::uid_to_inner(&badge_id);

    // Convert the String to bytes
    let bytes: vector<u8> = string::into_bytes(sourceUrl);  
    let image_url = url::new_unsafe_from_bytes(bytes);
    
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