var _ = require('lodash');

module.exports = function (injected) {

    return function (history) {

        var gamefull=false;

        function processEvent(event) {
//            console.debug("Event received:", event);
            if(event.type==="JoinGame") {
                gamefull=true;
//                console.debug("Game is now full");
            }
//            console.debug("event", event);
        }

        function processEvents(history) {
            _.each(history, processEvent);
        }

        function gameFull() {
            return gamefull;
        }

        processEvents(history);

        return {
            gameFull:gameFull,
            processEvents: processEvents
        }
    };
};
