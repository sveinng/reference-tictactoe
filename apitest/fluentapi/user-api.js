module.exports=function(injected){

    const io = require('socket.io-client');
    const RoutingContext = require('../../client/src/routing-context');
    const generateUUID = require('../../client/src/common/framework/uuid');
    var ENV = process.env.NODE_ENV;

    var connectCount =0;

    function userAPI(){
        var waitingFor=[];
        var commandId=0;
        var thisGame = { };

        var routingContext = RoutingContext(inject({
            io,
            env:ENV
        }));

        connectCount++;
        const me = {
            expectUserAck:(cb)=>{
                waitingFor.push("expectUserAck");
                routingContext.socket.on('userAcknowledged', function(ackMessage){
                    expect(ackMessage.clientId).not.toBeUndefined();
                    waitingFor.pop();
                });
                return me;
            },
            sendChatMessage:(message)=>{
                var cmdId = generateUUID();
                routingContext.commandRouter.routeMessage({commandId:cmdId, type:"chatCommand", message });
                return me;
            },
            expectChatMessageReceived:(message)=>{
                waitingFor.push("expectChatMessageReceived");
                routingContext.eventRouter.on('chatMessageReceived', function(chatMessage){
                    expect(chatMessage.sender).not.toBeUndefined();
                    if(chatMessage.message===message){
                        waitingFor.pop();
                    }
                });
                return me;
            },
            cleanDatabase:()=>{
                var cmdId = commandId++;
                routingContext.commandRouter.routeMessage({commandId:cmdId, type:"cleanDatabase"});
                return me;

            },
            waitForCleanDatabase:()=>{
                waitingFor.push("expectChatMessageReceived");
                routingContext.eventRouter.on('databaseCleaned', function(chatMessage){
                    waitingFor.pop();
                });
                return me;

            },
            createGame:()=>{
                commandId = generateUUID();
                thisGame.gameId = generateUUID();
                var timestampe = new Date();
                routingContext.commandRouter.routeMessage({commandId:commandId, type:"CreateGame", gameId:thisGame.gameId, timeStamp:timestampe});
                return me;
            },
            expectGameCreated:()=>{
                waitingFor.push("expectGameCreated");
                routingContext.eventRouter.on('GameCreated', function(game){
                    expect(game.gameId).not.toBeUndefined();
                    if(game.gameId===thisGame.gameId){
                        waitingFor.pop();
                        thisGame = game;
                    }
                });
                return me;
            },
            joinGame:(gameId)=>{
                var timestampe = new Date();
                thisGame.commandId = generateUUID();
                thisGame.gameId = gameId;
                routingContext.commandRouter.routeMessage({commandId:thisGame.commandId, type:"JoinGame", gameId:gameId, timeStamp:timestampe});
                return me;
            },
            expectGameJoined:()=>{
                waitingFor.push("expectGameJoined");
                routingContext.eventRouter.on('GameJoined', function(game){
                    expect(game.gameId).not.toBeUndefined();
                    if(game.gameId===thisGame.gameId && game.commandId===thisGame.commandId){
                        waitingFor.pop();
                        thisGame = game;
                    }
                });
                return me;
            },
            getGame:()=>{
                return thisGame;
            },
            placeMove:(x, y)=>{
                thisGame.commandId = generateUUID();
                var timestampe = new Date();
                var coordinate = { "x": x, "y": y };
                routingContext.commandRouter.routeMessage({commandId:thisGame.commandId, type:"PlaceMove", gameId:thisGame.gameId, timeStamp:timestampe, side:thisGame.side, coordinates:coordinate});
                return me;
            },
            expectMoveMade:()=>{
                waitingFor.push("expectMoveMade");
                routingContext.eventRouter.on('MoveMade', function(game){
                    expect(game.gameId).not.toBeUndefined();
                    if(game.gameId===thisGame.gameId && game.commandId===thisGame.commandId) {
                        waitingFor.pop();
                    }
                });
                return me;
            },
            expectGameWon:()=>{
                waitingFor.push("expectGameWon");
                routingContext.eventRouter.on('GameWon', function(game){
                    expect(game.gameId).not.toBeUndefined();
                    if(game.gameId===thisGame.gameId && game.commandId===thisGame.commandId){
                        waitingFor.pop();
                    }
                });
                return me;
            },
            then:(whenDoneWaiting)=>{
                function waitLonger(){
                    if(waitingFor.length>0){
                        setTimeout(waitLonger, 20);
                        return;
                    }
                    whenDoneWaiting();
                }
                waitLonger();
                return me;
            },
            disconnect:function(){
                routingContext.socket.disconnect();
            }

        };
        return me;

    }

    return userAPI;
};
