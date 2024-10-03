// #[test_only]
// module patience::patience_tests {
//     use patience::patience;

//     use sui::test_scenario;
//     use sui::random::Random;
//     use sui::clock::Clock;

//     const ENotImplemented: u64 = 0;

//     public struct PATIENCE has drop {}

//     #[test]
//     fun test_claim() {
//         let mut scenario = test_scenario::begin(@0xA);
//         {
//             let ctx = test_scenario::ctx(&mut scenario);
//             patience::test_init(ctx);
//         };

//         let effects = test_scenario::next_tx(&mut scenario, @0xA);
        
//         let director_id = effects.shared()[0];
//         let mut director = scenario.take_shared_by_id<patience::Director>(director_id);

//         scenario.next_tx(@0x0);
//         let clock: Clock = {
//             let ctx = test_scenario::ctx(&mut scenario);
//             sui::clock::create_for_testing(ctx)
//         };

//         scenario.next_tx(@0x0);
//         {
//             let ctx = test_scenario::ctx(&mut scenario);
//             sui::random::create_for_testing(ctx);
//         };

//         scenario.next_tx(@0xA);
//         let random: Random = scenario.take_shared<Random>();
//         {
//             let ctx = test_scenario::ctx(&mut scenario);
//             patience::claim(&mut director, &clock, &random, ctx);
//         };

//         scenario.next_tx(@0xA);
//         {
//             let ctx = test_scenario::ctx(&mut scenario);
//             patience::claim(&mut director, &clock, &random, ctx);
//         };

//         std::debug::print(&director);
        

//         clock.destroy_for_testing();
//         test_scenario::return_shared(random);
//         test_scenario::return_shared(director);

//         scenario.end();
//     }

//     #[test, expected_failure(abort_code = ::patience::patience_tests::ENotImplemented)]
//     fun test_patience_fail() {
//         abort ENotImplemented
//     }
// }
