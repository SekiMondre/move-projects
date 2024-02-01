module seki_mondre::checklist 
{
    use aptos_framework::account;
    use aptos_framework::event;
    use std::signer;
    use aptos_std::table::{Self, Table};
    use std::string::String;

    const ERR_UNINITIALIZED: u64 = 1;
    const ERR_ITEM_NOT_FOUND: u64 = 2;
    const ERR_ITEM_ALREADY_CHECKED: u64 = 3;

    struct Checklist has key {
        items: Table<u64, Item>,
        set_item_event: event::EventHandle<Item>,
        counter: u64,
    }

    struct Item has store, drop, copy {
        id: u64,
        address: address,
        content: String,
        completed: bool,
    }

    public entry fun create_list(account: &signer) {
        let list = Checklist {
            items: table::new(),
            set_item_event: account::new_event_handle<Item>(account),
            counter: 0
        };
        move_to(account, list);
    }

    public entry fun create_item(account: &signer, content: String) acquires Checklist {
        let signer_address = signer::address_of(account);
        assert!(exists<Checklist>(signer_address), ERR_UNINITIALIZED);

        let list = borrow_global_mut<Checklist>(signer_address);
        let counter = list.counter + 1;
        let new_item = Item {
            id: counter,
            address: signer_address,
            content,
            completed: false
        };
        table::upsert(&mut list.items, counter, new_item);
        list.counter = counter;
        event::emit_event<Item>(
            &mut borrow_global_mut<Checklist>(signer_address).set_item_event,
            new_item,
        );
    }

    public entry fun check_item(account: &signer, id: u64) acquires Checklist {
        let signer_address = signer::address_of(account);
        assert!(exists<Checklist>(signer_address), ERR_UNINITIALIZED);

        let list = borrow_global_mut<Checklist>(signer_address);
        assert!(table::contains(&list.items, id), ERR_ITEM_NOT_FOUND);

        let record = table::borrow_mut(&mut list.items, id);
        assert!(record.completed == false, ERR_ITEM_ALREADY_CHECKED);

        record.completed = true;
    }

    #[test_only]
    use std::string;

    #[test(owner = @0xdeadbeef)]
    public entry fun test(owner: signer) acquires Checklist {
        
        account::create_account_for_test(signer::address_of(&owner));
        create_list(&owner);
        create_item(&owner, string::utf8(b"wow much item"));

        let count = event::counter(&borrow_global<Checklist>(signer::address_of(&owner)).set_item_event);
        assert!(count == 1, 4);

        let list = borrow_global<Checklist>(signer::address_of(&owner));
        assert!(list.counter == 1, 5);

        let record = table::borrow(&list.items, list.counter);
        assert!(record.id == 1, 6);
        assert!(record.completed == false, 7);
        assert!(record.content == string::utf8(b"wow much item"), 8);
        assert!(record.address == signer::address_of(&owner), 9);

        check_item(&owner, 1);
        let list = borrow_global<Checklist>(signer::address_of(&owner)); // shadowing previous list
        let record = table::borrow(&list.items, 1);
        assert!(record.id == 1, 10);
        assert!(record.completed == true, 11);
        assert!(record.content == string::utf8(b"wow much item"), 12);
        assert!(record.address == signer::address_of(&owner), 13);
    }

    #[test(owner = @0xdeadbeef)]
    #[expected_failure(abort_code = ERR_UNINITIALIZED)]
    public entry fun test_update_fail(owner: signer) acquires Checklist {
        account::create_account_for_test(signer::address_of(&owner));
        check_item(&owner, 2);
    }
}