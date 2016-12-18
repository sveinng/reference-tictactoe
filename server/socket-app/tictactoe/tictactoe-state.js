var _ = require('lodash');

module.exports = function (injected) {

    return function (history) {

        var turns = 0;
        var lastturn = "O";
        var gamefull = false;
        var gameover = false;
        var board = [
          [0,0,0],
          [0,0,0],
          [0,0,0]
        ]

        function processEvent(event) {
            if(event.type==="GameJoined") {
                gamefull=true;
            }
            if(event.type==="MoveMade") {
                if ((board)[event.coordinates.y][event.coordinates.x] === 0) {
                    (board)[event.coordinates.y][event.coordinates.x] = event.side;
                    lastturn = event.side;
                    turns++;
                }
            }
        }

        function processEvents(history) {
            _.each(history, processEvent);
        }

        function gameFull() {
            return gamefull;
        }

        function isNotTurn(side) {
            return side == lastturn;
        }

        function cellEmpty(event) {
            return board[event.coordinates.y][event.coordinates.x] === 0;
        }

        function gameWon(side) {
            for(var i = 0; i < 3; i++){
                if ((board)[0][i] ===  side && (board)[1][i] ===  side && (board)[2][i] ===  side) return true;
                if ((board)[i][0] ===  side && (board)[i][1] ===  side && (board)[i][2] ===  side) return true;
            }
            if ((board)[2][0] ===  side && (board)[1][1] ===  side && (board)[0][2] ===  side) return true;
            if ((board)[0][0] ===  side && (board)[1][1] ===  side && (board)[2][2] ===  side) return true;
            return false;
        }

        function gameDraw() {
            return turns >= 9;
        }

        function getBoard() {
            return board;
        }

        processEvents(history);

        return {
            gameFull: gameFull,
            isNotTurn: isNotTurn,
            cellEmpty: cellEmpty,
            gameWon: gameWon,
            gameDraw: gameDraw,
            getBoard: getBoard,
            processEvents: processEvents
        }
    };
};
