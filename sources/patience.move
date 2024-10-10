module patience::patience {
    // === Imports ===

    use patience::icon;
    
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::clock::Clock;
    use sui::event;
    use sui::random::{Self, Random};
    use sui::sui::SUI;

    // === Errors ===

    const E_COOLDOWN: u64 = 1;
    const E_INSUFFICIENT_FEE: u64 = 2;
    const E_MINING_PAUSED: u64 = 3;
    
    // === Structs ===

    /// One Time Witness
    public struct PATIENCE has drop {}

    /// Admin Cap for managing the director.
    public struct AdminCap has key {
        id: UID,
    }

    /// Shared object to coorinate mining and mint coins.
    public struct Director has store, key {
        id: UID,
        tcap: TreasuryCap<PATIENCE>,
        fee_balance: Balance<SUI>,
        last_claim: u64,
        scale: u64,

        // Settings
        claim_fee: u64,
        claim_cap: u64,
        scale_min: u64,
        scale_max: u64,
        cooldown: u64,
        paused: bool,
    }

    /// Claim event emitted on claim.
    public struct ClaimEvent has copy, drop {
        claimer: address,
        timestamp: u64,
        amount: u64,
        scale: u64,
    }

    // === Init Function ===

    /// Initialise currency, admin cap, and director.
    fun init(otw: PATIENCE, ctx: &mut TxContext) {
        // Create admin cap
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };
        transfer::transfer<AdminCap>(admin_cap, ctx.sender());
        
        // Create currency
        let (treasury, metadata) = coin::create_currency(
            otw, 
            9, 
            b"PATIENCE", 
            b"Patience", 
            b"The Proof of Patience Coin", 
            option::some(icon::get_icon_url()), 
            ctx
        );
        transfer::public_freeze_object(metadata);

        // Create director
        let director = Director {
            id: object::new(ctx),
            tcap: treasury,
            fee_balance: balance::zero(),
            last_claim: 0,
            scale: 0,

            // Settings
            claim_fee: 100_000_000,
            claim_cap: 50_000_000_000,
            scale_min: 1158, // 12 hours
            scale_max: 13888, // 1 hour
            cooldown: 30000, // 30 second
            paused: false,
        };
        transfer::share_object(director);
    }
    
    // === Public Function ===
    
    /// Claim function for public to claim the pot of PATIENCE
    /// Can't claim if paused
    /// Can't claim if in cooldown
    /// Can't claim if fee provided is not greater or equal to director fee
    /// This function uses the directors treasury cap to mint new PATIENCE
    entry fun claim(director: &mut Director, fee: Coin<SUI>, clock: &Clock, r: &Random, ctx: &mut TxContext) {
        // Check if paused
        assert!(director.paused == false, E_MINING_PAUSED);
        let mut generator = random::new_generator(r, ctx);

        // Check cooldown
        assert!(clock.timestamp_ms() - director.last_claim > director.cooldown, E_COOLDOWN);
        let time_since_claim = clock.timestamp_ms() - director.last_claim - director.cooldown;

        // Check fee
        let fee_balance = fee.into_balance();
        assert!(fee_balance.value() >= director.claim_fee, E_INSUFFICIENT_FEE);

        // Take fee
        director.fee_balance.join(fee_balance);

        // Get mint amount
        let mint_amount = if (director.last_claim == 0) {
            director.claim_cap
        } else {
            let cap = director.claim_cap;
            let scale = director.scale;

            let mint_amount = time_since_claim * scale;
            if (mint_amount > cap) {
                cap
            } else {
                mint_amount
            }
        };

        // Update director
        director.last_claim = clock.timestamp_ms();
        director.scale = random::generate_u64_in_range(&mut generator, director.scale_min, director.scale_max);

        // Mint and transfer
        coin::mint_and_transfer<PATIENCE>(&mut director.tcap, mint_amount, ctx.sender(), ctx);
        
        // Emit event
        emit_claim_event(clock.timestamp_ms(), mint_amount, director.scale, ctx.sender());
    }

    // === Private Functions ===

    fun emit_claim_event(timestamp: u64, amount: u64, scale: u64, claimer: address) {
        let event = ClaimEvent {
            claimer,
            timestamp,
            amount,
            scale,
        };

        event::emit(event);
    }

    // === Admin Functions ===

    /// Withdraw fees from director
    public fun withdraw_fee(director: &mut Director, _admin_cap: &mut AdminCap, ctx: &mut TxContext): Coin<SUI> {
        let value = director.fee_balance.value();
        coin::from_balance(director.fee_balance.split(value), ctx)
    }

    /// Transfer admin capability
    public fun admin_transfer(admin_cap: AdminCap, recipient: address) {
        transfer::transfer(admin_cap, recipient);
    }

    /// Destroy admin capability
    public fun admin_destroy(admin_cap: AdminCap) {
        let AdminCap { id: id } = admin_cap;
        object::delete(id);
    }

    /// Pause mining
    public fun admin_pause(director:&mut Director, _: &AdminCap) {
        director.paused = true;
    }

    /// Resume mining
    public fun admin_resume(director:&mut Director, _: &AdminCap) {
        director.paused = false;
    }

    /// Change claim fee settings
    public fun set_claim_fee(fee: u64, director: &mut Director, _: &AdminCap) {
        director.claim_fee = fee;
    }

    /// Change claim cap settings
    public fun set_claim_cap(cap: u64, director: &mut Director, _: &AdminCap) {
        director.claim_cap = cap;
    }

    /// Change scale min settings
    public fun set_scale_min(min: u64, director: &mut Director, _: &AdminCap) {
        director.scale_min = min;
    }

    /// Change scale max settings
    public fun set_scale_max(max: u64, director: &mut Director, _: &AdminCap) {
        director.scale_max = max;
    }
    
    /// Change cooldown settings
    public fun set_cooldown(cooldown: u64, director: &mut Director, _: &AdminCap) {
        director.cooldown = cooldown;
    }

    // === Test Functions ===

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(PATIENCE {}, ctx);
    }
}
