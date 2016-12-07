var _ = require('lodash');

module.exports = function (injected) {

    return function (history) {

        var gamefull=false;

        function processEvent(event) {
            if(event.type==="GameJoined") {
                gamefull=true;
            }
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
