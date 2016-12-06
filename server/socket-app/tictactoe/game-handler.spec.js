var Handler = require('./game-handler');

describe("Tictactoe command handler", function () {


    var handler;

    var context, commandRouter, eventRouter, eventStore;

    var MessageRouter = require('client/src/common/framework/message-router');

    var executedCommand;
    var aggregate = function(events){
        return{
            executeCommand:function(commandMessage, resultingEventCb){
                executedCommand = commandMessage;
                resultingEventCb([
                    {'resulting':'event'}
                ])
            }
        }
    };

    var givenEvents=[];
    var eventStore;

    var resultingEvents =[];

    beforeEach(function () {
        executedCommand = undefined;
        commandRouter = MessageRouter();
        eventRouter = MessageRouter();
        resultingEvents=[];

        eventStore = {
            loadEvents:function(aggregateId, err, success){
                eventStore.loadedEvents = true;
                success(givenEvents);
            }
        };
        handler = Handler(inject({
            generateUUID : function(){
                return "fakeId"
            },
            commandRouter,
            eventRouter,
            eventStore,
            aggregate
        }));
        eventRouter.on("*", function(event){
            resultingEvents.push(event)
        });
        handler.startHandling();
    });


    it('should not handle command without gameId attribute', function () {
        commandRouter.routeMessage({
            crap:'message'
        });
        expect(resultingEvents.length).toBe(0);
    });

    it('should load events for game Id',function(){
        commandRouter.routeMessage({
            gameId:"thisIsTheGame"
        });
        expect(eventStore.loadedEvents).toBeTruthy();
    });

    it('should execute command on tictactoe aggregate',function(){
        commandRouter.routeMessage({
            gameId:"thisIsTheGame"
        });
        expect(executedCommand.gameId).toEqual("thisIsTheGame");
    });

    it('should route resulting events to event router with all relevant information',function(){
        commandRouter.routeMessage({
            gameId:"thisIsTheGame",
            _session :{
                clientId:999,
            }
        });
        expect(resultingEvents.length).toEqual(1);
        expect(resultingEvents[0].gameId).toEqual('thisIsTheGame');
        expect(resultingEvents[0].userSession.clientId).toEqual(999);
    });

});