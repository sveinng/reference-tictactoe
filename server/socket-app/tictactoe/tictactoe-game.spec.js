var should = require('should');
var _ = require('lodash');

var TictactoeState = require('./tictactoe-state')(inject({}));

var tictactoe = require('./tictactoe-handler')(inject({
    TictactoeState
}));

var eventCreateGame = {
    id:"123987",
    type: "CreateGame",
    user: { userName: "Uber" },
    name: "UberGame",
    timeStamp: "2016-12-07T20:55:29"
};

var eventGameCreated = {
    type: "GameCreated",
    user: { userName: "Uber" },
    name: "UberGame",
    timeStamp: "2016-12-07T20:55:29",
    side:'X'
};

var eventJoinGame = {
  type: "JoinGame",
  user: {
      userName: "Svenson"
  },
  name: "UberGame",
  timeStamp: "2016-12-07T20:55:40"
};

var eventGameJoined = {
    type: "GameJoined",
    user: { userName: "Svenson" },
    name: "UberGame",
    timeStamp: "2016-12-07T20:55:40",
    side:'O'
};

var eventJoinGameThirdPlayer = {
  type: "JoinGame",
  user: { userName: "Third Player" },
  name: "UberGame",
  timeStamp: "2016-12-07T20:56:29"
};

var eventFullGameJoinAttempted = {
  type: "FullGameJoinAttempted",
  user: { userName: "Third Player" },
  name: "UberGame",
  timeStamp: "2016-12-07T20:56:29"
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
