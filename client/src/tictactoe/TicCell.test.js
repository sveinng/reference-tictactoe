import ReactTestUtils from 'react-addons-test-utils';
import TictactoeBoardModule from './TictactoeBoard';
import ReactDOM from 'react-dom';
import React from 'react';
import { shallow } from 'enzyme';

import TicCellComponent from './TicCell';
import MessageRouter from '../common/framework/message-router';



var div, component, TicCell, side;
var cords, gameId;

var commandRouter = MessageRouter(inject({}));
var eventRouter = MessageRouter(inject({}));
var commandsReceived=[];

commandRouter.on("*", function(cmd){
    commandsReceived.push(cmd);
} );

beforeEach(function () {
    commandsReceived.length=0;
    TicCell = TicCellComponent(inject({
        generateUUID:()=>{
            return "youyouid"
        },
        commandPort: commandRouter,
        eventRouter
    }));

    div = document.createElement('div');
    side = 'X';
    cords = {x:0, y:0};
    gameId = '666';

    component = shallow(<TicCell />, div);
    component.setProps({coordinates: cords, mySide: side, gameId: gameId});
});

describe("Tic Cell", function () {

    it('should render without error', function () {
        expect(component.state('error')).toBeFalsy();
    });

    it('should record move with matching game id and coordinates ',function(){
        var message = {
            commandId:1,
            type:"MoveMade",
            gameId:'666',
            side:'X',
            coordinates: {x:0, y:0}
        };
        eventRouter.routeMessage(message);
        expect(component.state('side')).toBe('X');
    });

    it('should ignore move with matching gameId but not coordinates',function(){
        var message = {
            commandId:1,
            type:"MoveMade",
            gameId:'666',
            side:'X',
            coordinates: {x:0, y:0}
        };
        eventRouter.routeMessage(message);
        expect(component.state('side')).toBe('X');
    });

    it('should ignore move with matching coordinates, but not matching gameId',function(){
        var message = {
            commandId:1,
            type:"MoveMade",
            gameId:'666',
            side:'X',
            coordinates: {x:0, y:0}
        };
        eventRouter.routeMessage(message);
        expect(component.state('side')).toBe('X');
    });

    it('should issue PlaceMove command with gameId, mySide and coordinates when clicked', ()=>{
        component.find('div').simulate('click');

    //    .. check whether correct command was dispatched through command router
    });

});
