module seki_mondre::shit_coin 
{
    use std::signer;

    const ERR_BALANCE_DOESNT_EXIST: u64 = 1;
    const ERR_BALANCE_ALREADY_EXISTS: u64 = 2;
    const ERR_NOT_ENOUGH_BALANCE: u64 = 3;
    const ERR_SAME_ADDRESS: u64 = 4;

    #[test_only]
    const ERR_ALREADY_HAS_BALANCE: u64 = 101;

    struct ShitCoin has store { 
        value: u64 
    }

    struct Balance has key {
        coin: ShitCoin
    }

    public fun mint(value: u64): ShitCoin {
        let new_coin = ShitCoin { value };
        new_coin
    }

    public fun burn(coin: ShitCoin) {
        let ShitCoin { value: _ } = coin;
    }

    public fun create_balance(owner: &signer) {
        let acc_address = signer::address_of(owner);
        assert!(!exists<Balance>(acc_address), ERR_BALANCE_ALREADY_EXISTS);
        let zero = ShitCoin { value: 0 };
        move_to(owner, Balance { coin: zero });
    }

    public fun balance_of(owner: address): u64 acquires Balance {
        borrow_global<Balance>(owner).coin.value
    }

    public fun deposit(account: address, coin: ShitCoin) acquires Balance {
        let balance = balance_of(account);
        assert!(exists<Balance>(account), ERR_BALANCE_DOESNT_EXIST);
        let balance_ref = &mut borrow_global_mut<Balance>(account).coin.value;
        let ShitCoin { value } = coin;
        *balance_ref = balance + value;
    }

    public fun withdraw(account: address, value: u64): ShitCoin acquires Balance {
        assert!(exists<Balance>(account), ERR_BALANCE_DOESNT_EXIST);
        let balance = balance_of(account);
        assert!(balance >= value, ERR_NOT_ENOUGH_BALANCE);
        let balance_ref = &mut borrow_global_mut<Balance>(account).coin.value;
        *balance_ref = balance - value;
        ShitCoin { value }
    }

    public fun transfer(sender: &signer, recipient: address, amount: u64) acquires Balance {
        let sender_address = signer::address_of(sender);
        assert!(sender_address != recipient, ERR_SAME_ADDRESS);
        let coin = withdraw(sender_address, amount);
        deposit(recipient, coin);
    }

    #[test(acc = @0x1337)]
    fun test_basic_stuff(acc: signer) acquires Balance {
        let acc_addr = signer::address_of(&acc);
        let coins_10 = mint(10);

        create_balance(&acc);
        deposit(acc_addr,coins_10);
        assert!(balance_of(acc_addr)==10, ERR_NOT_ENOUGH_BALANCE);

        let coins_5 = withdraw(acc_addr, 5);
        assert!(balance_of(acc_addr)==5, ERR_ALREADY_HAS_BALANCE);

        burn(coins_5);
    }
}