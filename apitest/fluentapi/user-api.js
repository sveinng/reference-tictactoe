module.exports=function(injected){

    const io = require('socket.io-client');
    const RoutingContext = require('../../client/src/routing-context');
    const generateUUID = require('../../client/src/common/framework/uuid');

    var connectCount =0;

    function userAPI(){
        var waitingFor=[];
        var commandId=0;
        var thisGame = { gameId: generateUUID() };

        var routingContext = RoutingContext(inject({
            io,
            env:"test"
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
            createGame:()=>{
                var cmdId = generateUUID();
                var ts = new Date();
                routingContext.commandRouter.routeMessage({commandId:cmdId, type:"CreateGame", gameId:thisGame.gameId, timeStamp:ts});
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
            joinGame:(id)=>{
                var cmdId = generateUUID();
                var ts = new Date();
                thisGame.gameId = id;
                routingContext.commandRouter.routeMessage({commandId:cmdId, type:"JoinGame", gameId:id, timeStamp:ts});
                return me;
            },
            expectGameJoined:()=>{
                waitingFor.push("expectGameJoined");
                routingContext.eventRouter.on('GameJoined', function(game){
                    expect(game.gameId).not.toBeUndefined();
                    if(game.gameId===thisGame.gameId){
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
                var cmdId = generateUUID();
                var ts = new Date();
                var coordinate = { "x": x, "y": y };
                routingContext.commandRouter.routeMessage({commandId:cmdId, type:"PlaceMove", gameId:thisGame.gameId, timeStamp:ts, side:thisGame.side, coordinates:coordinate});
                return me;
            },
            expectMoveMade:()=>{
                waitingFor.push("expectMoveMade");
                routingContext.eventRouter.on('MoveMade', function(game){
                    expect(game.gameId).not.toBeUndefined();
                    if(game.gameId===thisGame.gameId){
                        waitingFor.pop();
                    }
                });
                return me;
            },
            expectGameWon:()=>{
                waitingFor.push("expectGameWon");
                routingContext.eventRouter.on('GameWon', function(game){
                    expect(game.gameId).not.toBeUndefined();
                    if(game.gameId===thisGame.gameId){
                        waitingFor.pop();
                    }
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
            then:(whenDoneWaiting)=>{
                function waitLonger(){
                    if(waitingFor.length>0){
                        setTimeout(waitLonger, 0);
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
