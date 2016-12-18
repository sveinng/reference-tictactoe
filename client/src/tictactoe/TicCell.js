import React from 'react';

export default function (injected) {
    const eventRouter = injected('eventRouter');
    const commandPort = injected('commandPort');
    const generateUUID = injected('generateUUID');

    class TicCell extends React.Component {
        constructor() {
            super();
            this.state = {
                value: ''
            }
            this.placeMove = this.placeMove.bind(this);
        }
        componentWillMount(){
            var moveMade = (cmd)=>{
                if(cmd.gameId===this.props.gameId) {
                    if(cmd.coordinates.x===this.props.coordinates.x &&
                        cmd.coordinates.y===this.props.coordinates.y) {
                        this.setState({ side: cmd.side});
                    }
                }
            };
            eventRouter.on('MoveMade', moveMade);
        }
        placeMove() {
            var commandId = generateUUID();
            var timestamp = new Date();

            var message = {
                commandId:commandId,
                type:"PlaceMove",
                gameId:this.props.gameId,
                timeStamp:timestamp,
                side:this.props.mySide,
                coordinates:this.props.coordinates
            };
            commandPort.routeMessage(message);
        }
        render() {
            console.debug("this.state", this.props);
            return <div className="ticcell" onClick={this.placeMove}>
                {this.state.side}
            </div>
        }
    }
    return TicCell;
}
