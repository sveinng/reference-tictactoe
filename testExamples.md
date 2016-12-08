# Test examples for Tictactoe
## Given, When, Then

### Create new game
Given[],
When[CreateGame],
Then[GameCreated]

### Join game
Given[GameCreated],
When[JoinGame],
Then[GameJoined]

### Join full game
Given[CreateGame, JoinGame],
When[JoinGame],
Then[FullGameJoinAttempted]

### Leave game
Given[CreateGame, JoinGame],
When[LeaveGame],
Then[GameLeft]

### Place move
Given[GameCreated],
When[PlaceMove(0,0,X)],
Then[MoveMade]

### Place illegal move
Given[GameCreated,PlaceMove(0,0,X)],
When[PlaceMove(0,0,X)],
Then[MoveIllegal]

### Place winning move (1 / 3)
Given[GameCreated,PlaceMove(0,0,X),PlaceMove(1,0,X)],
When[PlaceMove(2,0,X)],
Then[GameWon]

### Place winning move (2 / 3)
Given[GameCreated,PlaceMove(0,0,X),PlaceMove(0,1,X)],
When[PlaceMove(0,2,X)],
Then[GameWon]

### Place winning move (3 / 3)
Given[GameCreated,PlaceMove(0,0,X),PlaceMove(1,1,X)],
When[PlaceMove(2,2,X)],
Then[GameWon]

### Place stale mate move
Given[GameCreated,MovePlacedCount(8)],
When[PlaceMove(0,0,X)],
Then[GameStaleMate]
