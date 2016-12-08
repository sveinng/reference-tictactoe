var _ = require('lodash');

module.exports = function (injected) {

    return function (history) {

        var gamefull=false;
        var board = [
          [0,0,0],
          [0,0,0],
          [0,0,0]
        ]

        function processEvent(event) {
            if(event.type==="GameJoined") {
                gamefull=true;
            }
            if(event.type==="PlaceMove") {
                if ((board)[event.cell.y][event.cell.x] === "0") {
                    (board)[event.cell.y][event.cell.x] = event.side;
                }
            }
        }

        function processEvents(history) {
            _.each(history, processEvent);
        }

        function gameFull() {
            return gamefull;
        }

        function cellEmpty(event) {
            return board[event.cell.y][event.cell.x] == "0";
        }

        processEvents(history);

        return {
            gameFull: gameFull,
            cellEmpty: cellEmpty,
            processEvents: processEvents
        }
    };
};
