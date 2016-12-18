const io = require('socket.io-client');
const RoutingContext = require('../client/src/routing-context');
var UserAPI = require('./fluentapi/user-api');
var TestAPI = require('./fluentapi/test-api');

const userAPI = UserAPI(inject({
    io,
    RoutingContext
}));

const testAPI = TestAPI(inject({
    io,
    RoutingContext
}));

jasmine.DEFAULT_TIMEOUT_INTERVAL = 50000;

describe('TicTacToe load test', function(){

    beforeEach(function(done){
        var testapi = testAPI();
        testapi.waitForCleanDatabase().cleanDatabase().then(()=>{
            testapi.disconnect();
            done();
        });
    });

    const count = 100;
    const timelimit = 50000;

    it('should start ' + count + ' games within ' + timelimit + ' ms', function(done){

        var startMillis = new Date().getTime();

        var user;
        var users=[];
        for(var i=0; i<count; i++){
            user = userAPI("User#" + i);
            users.push(user);
            user.createGame();
        }

        user = userAPI("Final user");
        user.expectGameCreated()
            .createGame()
            .then(function(){
                user.disconnect();
                _.each(users, function(usr){
                    usr.disconnect();
                });

                var endMillis = new Date().getTime();
                var duration = endMillis - startMillis;
                if(duration > timelimit){
                    done.fail(duration + " exceeds limit " + timelimit);
                } else {
                    console.log(count + ' games created in ' + duration + ' ms');
                    done();
                }
            });
    });

    it('should play ' + count + ' games within ' + timelimit + ' ms', function(done){
        var startMillis = new Date().getTime();
        for(var i=0; i<count; i++){
            var userA = userAPI("userA#" + i);
            var userB = userAPI("userB#" + i);
            userA.expectGameCreated().createGame().then(()=> {
                userB.expectGameJoined().joinGame(userA.getGame().gameId).then(function () {
                    userA.expectMoveMade().placeMove(0, 0).then(()=> {
                        userA.expectMoveMade();
                        userB.expectMoveMade().placeMove(1, 0).then(()=> {
                            userB.expectMoveMade(); // By other user
                            userA.expectMoveMade().placeMove(1, 1).then(()=> {
                                userA.expectMoveMade(); // By other user
                                userB.expectMoveMade().placeMove(1, 2).then(()=> {
                                    userB.expectMoveMade(); // By other user
                                    userA.expectMoveMade().placeMove(2, 2).expectGameWon().then(function() {
                                        userA.disconnect();
                                        userB.disconnect();
                                    })
                                })
                            })
                        })
                    })
                })
            });
        }

        var userFinalA = userAPI("Final userA");
        var userFinalB = userAPI("Final userB");
        userFinalA.expectGameCreated().createGame().then(()=> {
            userFinalB.expectGameJoined().joinGame(userFinalA.getGame().gameId).then(function () {
                userFinalA.expectMoveMade().placeMove(0, 0).then(()=> {
                    userFinalA.expectMoveMade();
                    userFinalB.expectMoveMade().placeMove(1, 0).then(()=> {
                        userFinalB.expectMoveMade(); // By other user
                        userFinalA.expectMoveMade().placeMove(1, 1).then(()=> {
                            userFinalA.expectMoveMade(); // By other user
                            userFinalB.expectMoveMade().placeMove(1, 2).then(()=> {
                                userFinalB.expectMoveMade(); // By other user
                                userFinalA.expectMoveMade().placeMove(2, 2).expectGameWon().then(function () {
                                    userFinalA.disconnect();
                                    userFinalB.disconnect();
                                    var endMillis = new Date().getTime();
                                    var duration = endMillis - startMillis;
                                    if(duration > timelimit){
                                        done.fail(duration + " exceeds limit " + timelimit);
                                    } else {
                                        console.log(count + ' games played in ' + duration + ' ms');
                                        done();
                                    }
                                })
                            })
                        })
                    })
                })
            })
        })

    });
});
