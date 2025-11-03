rollback_define_player(oPlayer); //

if(!rollback_join_game()) //checks if player was invited, if not return false
{
    rollback_create_game(2, false); //create a new game with a maximum of 2 players, true enables offline testing
}
