var _ = require('lodash');

module.exports = function (injected) {
    const generateUUID = injected('generateUUID');
    const commandRouter = injected('commandRouter');
    const eventRouter = injected('eventRouter');
    const eventStore = injected('eventStore');
    const Aggregate = injected('aggregate');

    var handleCommand = function (cmd) {
        eventStore.loadEvents(cmd.gameId, null, function (eventStream) {
            var aggregate = Aggregate(eventStream);

            aggregate.executeCommand(cmd, function (resultingEvents) {
                _.each(resultingEvents, function (event) {
                    event.eventId=generateUUID();
                    event.userSession = cmd._session;
                    event.gameId=cmd.gameId;
                    eventRouter.routeMessage(
                        event
                    )
                });
            });
        });
    };

    return {
        startHandling(){
            commandRouter.on('*', function (commandMessage) {
                if(commandMessage.gameId){
                    handleCommand(commandMessage);
                } // else this is not a game command, ignore it
            })
        }
    }
};

