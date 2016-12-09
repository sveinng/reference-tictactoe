# Test examples for Tictactoe
## Given, When, Then

### should emit game created event
Given[],
When[CreateGame],
Then[GameCreated]

### should emit game joined event
Given[GameCreated],
When[JoinGame],
Then[GameJoined]

### should emit FullGameJoinAttempted event when game full
Given[CreateGame, GameJoined],
When[JoinGame],
Then[FullGameJoinAttempted]

### should emit MoveMade on first game move
Given[GameCreated,JoinGame],
When[PlaceMove(0,0:X)],
Then[MoveMade(0,0:X)]

### should emit IllegalMove when square is already occupied
Given[GameCreated,MoveMade(0,0:X)],
When[PlaceMove(0,0:O)],
Then[MoveIllegal]

### should emit NotYourMove if attempting to make move out of turn
Given[GameCreated,MoveMade(0,0,X)],
When[PlaceMove(0,0,X)],
Then[NotYourMove]

### should emit GameWon on winning the game (1 / 4 - vertical)
Given[GameCreated,MoveMade(0,0,X),MoveMade(1,0,X)],
When[PlaceMove(2,0,X)],
Then[GameWon]

### should emit GameWon on winning the game (2 / 4 - horizontal)
Given[GameCreated,MoveMade(0,0,X),MoveMade(0,1,X)],
When[PlaceMove(0,2,X)],
Then[GameWon]

### should emit GameWon on winning the game (3 / 4 - top left 2 bottom right)
Given[GameCreated,PlaceMove(0,0,X),PlaceMove(1,1,X)],
When[PlaceMove(2,2,X)],
Then[GameWon]

### should emit GameWon on winning the game (4 / 4 - top right 2 bottom left)
Given[GameCreated,PlaceMove(0,2,X),PlaceMove(1,1,X)],
When[PlaceMove(2,0,X)],
Then[GameWon]

### should emit GameDraw after 9 plays without winner
Given[GameCreated,MovePlacedCount(8)],
When[PlaceMove(0,0,X)],
Then[GameStaleMate]
