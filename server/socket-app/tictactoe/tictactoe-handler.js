
module.exports = function(injected){
    var TictactoeState = injected('TictactoeState');

    return function(history){

        var gameState = TictactoeState(history);

        return {
            executeCommand: function(cmd, eventHandler){

                var cmdHandlers = {
                    "CreateGame": function (cmd) {
                        eventHandler([{
                            gameId: cmd.gameId,
                            type: "GameCreated",
                            user: cmd.user,
                            name: cmd.name,
                            timeStamp: cmd.timeStamp,
                            side:'X'
                        }]);

                    },

                    "JoinGame": function (cmd) {
                        if(gameState.gameFull()){
                            eventHandler( [{
                                gameId: cmd.gameId,
                                type: "FullGameJoinAttempted",
                                user: cmd.user,
                                name: cmd.name,
                                timeStamp: cmd.timeStamp
                            }]);
                            return;
                        }
                        eventHandler([{
                            gameId: cmd.gameId,
                            type: "GameJoined",
                            user: cmd.user,
                            name: cmd.name,
                            timeStamp: cmd.timeStamp,
                            side:'O'
                        }]);
                    },

                    "PlaceMove": function(cmd){
                        if(gameState.isNotTurn(cmd.side)){
                            eventHandler( [{
                                gameId: cmd.gameId,
                                type: "NotYourMove",
                                user: cmd.user,
                                name: cmd.name,
                                timeStamp: cmd.timeStamp
                            }]);
                            return;
                        }
                        if(!gameState.cellEmpty(cmd)){
                            eventHandler( [{
                                gameId: cmd.gameId,
                                type: "MoveIllegal",
                                user: cmd.user,
                                name: cmd.name,
                                timeStamp: cmd.timeStamp
                            }]);
                            return;
                        }

                        var events = [{
                            gameId: cmd.gameId,
                            type: "MoveMade",
                            user: cmd.user,
                            name: cmd.name,
                            timeStamp: cmd.timeStamp,
                            side: cmd.side,
                            coordinates: cmd.coordinates
                        }];

                        gameState.processEvents(events);

                        if(gameState.gameWon(cmd.side)){
                            events.push({
                                gameId: cmd.gameId,
                                type: "GameWon",
                                user: cmd.user,
                                name: cmd.name,
                                timeStamp: cmd.timeStamp
                            });
                        }

                        eventHandler(events);

                    }
                };

                if(!cmdHandlers[cmd.type]){
                    throw new Error("I do not handle command of type " + cmd.type)
                }
                cmdHandlers[cmd.type](cmd);
            }
        }
    }
};
