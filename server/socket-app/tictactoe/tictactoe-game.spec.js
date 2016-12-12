var should = require('should');
var _ = require('lodash');

var TictactoeState = require('./tictactoe-state')(inject({}));

var tictactoe = require('./tictactoe-handler')(inject({
    TictactoeState
}));

var eventCreateGame = {
    "gameId":"1337",
    "type": "CreateGame",
    "user": { "userName": "Uber" },
    "name": "UberGame",
    "timeStamp": "2016-12-07T20:55:29"
};

var eventGameCreated = {
    "gameId": "1337",
    "type": "GameCreated",
    "user": { "userName": "Uber" },
    "name": "UberGame",
    "timeStamp": "2016-12-07T20:55:29",
    "side":'X'
};

var eventJoinGame = {
    "gameId":"1337",
    "type": "JoinGame",
    "user": { "userName": "Svenson" },
    "name": "UberGame",
    "timeStamp": "2016-12-07T20:55:40"
};

var eventGameJoined = {
    "gameId":"1337",
    "type": "GameJoined",
    "user": { "userName": "Svenson" },
    "name": "UberGame",
    "timeStamp": "2016-12-07T20:55:40",
    "side":'O'
};

var eventJoinGameThirdPlayer = {
    "gameId":"1337",
    "type": "JoinGame",
    "user": { "userName": "Third Player" },
    "name": "UberGame",
    "timeStamp": "2016-12-07T20:56:29"
};

var eventFullGameJoinAttempted = {
    "gameId":"1337",
    "type": "FullGameJoinAttempted",
    "user": { "userName": "Third Player" },
    "name": "UberGame",
    "timeStamp": "2016-12-07T20:56:29"
};


describe('create game command', function() {

    var given, when, then;
    beforeEach(function(){
        given=undefined;
        when=undefined;
        then=undefined;
    });

    afterEach(function () {
        tictactoe(given).executeCommand(when, function(actualEvents){
            should(JSON.stringify(actualEvents)).be.exactly(JSON.stringify(then));
        });
    });

    it('should emit game created event', function(){
        given = [];
        when = eventCreateGame;
        then = [ eventGameCreated ];
    })
});


describe('join game command', function () {

    var given, when, then;
    beforeEach(function () {
        given = undefined;
        when = undefined;
        then = undefined;
    });

    afterEach(function () {
        tictactoe(given).executeCommand(when, function (actualEvents) {
            should(JSON.stringify(actualEvents)).be.exactly(JSON.stringify(then));
        });
    });

    it('should emit game joined event...', function () {
        given = [ eventGameCreated ];
        when = eventJoinGame;
        then = [ eventGameJoined ];
    });

    it('should emit FullGameJoinAttempted event when game full', function () {
      given = [ eventGameCreated, eventJoinGame, eventGameJoined ];
      when = eventJoinGameThirdPlayer;
      then = [ eventFullGameJoinAttempted ];
    });
});


describe('place move command', function () {

    var given, when, then;
    beforeEach(function () {
        given = undefined;
        when = undefined;
        then = undefined;
    });

    afterEach(function () {
        tictactoe(given).executeCommand(when, function (actualEvents) {
            should(JSON.stringify(actualEvents)).be.exactly(JSON.stringify(then));
        });
    });

    it('should emit MoveMade on first game move', function () {
        given = [ eventGameCreated, eventJoinGame ];
        when = {
            "gameId":"1337",
            "type": "PlaceMove",
            "user": { "userName": "Uber" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29",
            "side": "X",
            "coordinates": { "x": 0, "y": 0 }
        };
        then = [{
            "gameId": "1337",
            "type": "MoveMade",
            "user": { "userName": "Uber" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29",
            "side": "X",
            "coordinates": { "x": 0, "y": 0 }
        }];
    });

    it('should emit IllegalMove when square is already occupied', function () {
        given = [ eventGameCreated, eventJoinGame,
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 0 }
            } ];
        when = {
            "gameId":"1337",
            "type": "PlaceMove",
            "user": { "userName": "Svenson" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29",
            "side": "O",
            "coordinates": { "x": 0, "y": 0 }
        };
        then = [ {
            "gameId": "1337",
            "type": "MoveIllegal",
            "user": { "userName": "Svenson" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29"
        } ];
    });

    it('should emit NotYourMove if attempting to make move out of turn', function () {
        given = [ eventGameCreated, eventJoinGame,
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 0 }
            } ];
        when = {
            "gameId": "1337",
            "type": "PlaceMove",
            "user": { "userName": "Uber" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29",
            "side": "X",
            "coordinates": { "x": 1, "y": 0 }
        };
        then = [ {
            "gameId": "1337",
            "type": "NotYourMove",
            "user": { "userName": "Uber" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29"
        } ];
    });

    it('should emit GameWon on winning the game (vertical)', function () {
        given = [ eventGameCreated, eventJoinGame,
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 0 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 1, "y": 0 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Svenson" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "O",
                "coordinates": { "x": 1, "y": 2 }
            }
         ];
        when = {
            "gameId":"1337",
            "type": "PlaceMove",
            "user": { "userName": "Uber" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29",
            "side": "X",
            "coordinates": { "x": 2, "y": 0 }
        };
        then = [
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 2, "y": 0 }
            },
            {
                "gameId": "1337",
                "type": "GameWon",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X"
            } ];
    });

    it('should emit GameWon on winning the game (horizontal)', function () {
        given = [ eventGameCreated, eventJoinGame,
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 0 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 1 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Svenson" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "O",
                "coordinates": { "x": 1, "y": 2 }
            }
         ];
        when = {
            "gameId":"1337",
            "type": "PlaceMove",
            "user": { "userName": "Uber" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29",
            "side": "X",
            "coordinates": { "x": 0, "y": 2 }
        };
        then = [
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 2 }
            },
            {
                "gameId": "1337",
                "type": "GameWon",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X"
            } ];
    });

    it('should emit GameWon on winning the game (top left 2 bottom right)', function () {
        given = [ eventGameCreated, eventJoinGame,
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 0 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 1, "y": 1 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Svenson" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "O",
                "coordinates": { "x": 1, "y": 2 }
            }
         ];
        when = {
            "gameId":"1337",
            "type": "PlaceMove",
            "user": { "userName": "Uber" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29",
            "side": "X",
            "coordinates": { "x": 2, "y": 2 }
        };
        then = [
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 2, "y": 2 }
            },
            {
                "gameId": "1337",
                "type": "GameWon",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X"
            } ];
    });

    it('should emit GameWon on winning the game (top right 2 bottom left)', function () {
        given = [ eventGameCreated, eventJoinGame,
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 2 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 1, "y": 1 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Svenson" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "O",
                "coordinates": { "x": 1, "y": 2 }
            }
         ];
        when = {
            "gameId":"1337",
            "type": "PlaceMove",
            "user": { "userName": "Uber" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29",
            "side": "X",
            "coordinates": { "x": 2, "y": 0 }
        };
        then = [
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 2, "y": 0 }
            },
            {
                "gameId": "1337",
                "type": "GameWon",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X"
            } ];
    });


    it('should emit GameWon on winning the game (top left 2 bottom right)', function () {
        given = [ eventGameCreated, eventJoinGame,
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 0 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 1, "y": 1 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Svenson" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "O",
                "coordinates": { "x": 1, "y": 2 }
            }
         ];
        when = {
            "gameId":"1337",
            "type": "PlaceMove",
            "user": { "userName": "Uber" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29",
            "side": "X",
            "coordinates": { "x": 2, "y": 2 }
        };
        then = [
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 2, "y": 2 }
            },
            {
                "gameId": "1337",
                "type": "GameWon",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X"
            } ];
    });

    it('should emit GameDraw after 9 plays without winner', function () {
        given = [ eventGameCreated, eventJoinGame,
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 0 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 0, "y": 1 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Svenson" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "O",
                "coordinates": { "x": 0, "y": 2 }
            },
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Svenson" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "O",
                "coordinates": { "x": 1, "y": 0 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Svenson" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "O",
                "coordinates": { "x": 1, "y": 1 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 1, "y": 2 }
            },
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 2, "y": 0 }
            },
            {
                "gameId":"1337",
                "type": "MoveMade",
                "user": { "userName": "Uber" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "X",
                "coordinates": { "x": 2, "y": 1 }
            } ];
        when = {
            "gameId":"1337",
            "type": "PlaceMove",
            "user": { "userName": "Svenson" },
            "name": "UberGame",
            "timeStamp": "2016-12-07T20:56:29",
            "side": "O",
            "coordinates": { "x": 2, "y": 2 }
        };
        then = [
            {
                "gameId": "1337",
                "type": "MoveMade",
                "user": { "userName": "Svenson" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "O",
                "coordinates": { "x": 2, "y": 2 }
            },
            {
                "gameId": "1337",
                "type": "GameDraw",
                "user": { "userName": "Svenson" },
                "name": "UberGame",
                "timeStamp": "2016-12-07T20:56:29",
                "side": "O"
            } ];
    });

});
