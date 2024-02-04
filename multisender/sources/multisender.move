module seki_mondre::multisender
{
    use std::signer;
    use std::vector;
    use std::coin;
    use std::aptos_coin::AptosCoin;
    use std::aptos_account;

    const ERR_NOT_ENOUGH_BALANCE: u64 = 1;

    public entry fun multi_transfer(sender: &signer, recipients: vector<address>, amount: u64) {
        let count: u64 = vector::length(&recipients);
        let balance: u64 = coin::balance<AptosCoin>(signer::address_of(sender));

        assert!(amount * count <= balance, ERR_NOT_ENOUGH_BALANCE);

        let i: u64 = 0;
        while (i < count) {
            let to_addr = *vector::borrow(&recipients, i);
            aptos_account::transfer(sender, to_addr, amount);
            i = i + 1;
        };
    }
}