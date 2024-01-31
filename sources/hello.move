
// publish
// aptos move publish

// execute
// aptos move run --function-id 'default::Henlo::create_msg' --args 'string:henlo frien'    

// check result at
// https://fullnode.devnet.aptoslabs.com/v1/accounts/25df7a0403b7a2a4771676dffedfe55426e03d10dd553c6f0665765ad44e303a/resource/0x25df7a0403b7a2a4771676dffedfe55426e03d10dd553c6f0665765ad44e303a::Henlo::Message

module SuperEnterprises::Henlo {

    use std::string::{String,Self};
    use std::signer;
    use aptos_framework::account;

    struct Message has key {
        str: String
    }

    public entry fun create_msg(account: &signer, msg: String) acquires Message {
        
        let signer_addr = signer::address_of(account);
        
        if (!exists<Message>(signer_addr)) {
            let message = Message { str: msg };
            move_to(account, message);
        } else {
            let message = borrow_global_mut<Message>(signer_addr);
            message.str = msg;
        }
    }

    #[test(owner = @0xCAFE)]
    public entry fun test(owner: signer) acquires Message {
        account::create_account_for_test(signer::address_of(&owner));
        create_msg(&owner, string::utf8(b"message 1"));
        create_msg(&owner, string::utf8(b"message 2"));

        let msg = borrow_global<Message>(signer::address_of(&owner));
        assert!(msg.str == string::utf8(b"message 2"), 10);
    }
}