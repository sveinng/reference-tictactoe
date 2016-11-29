window.console.debug = window.console.log;

import inject from './common/framework/inject';
import React from 'react';
import ReactDOM from 'react-dom';

import './index.css';

import AppContextModule from "./appcontext";

import _ from "lodash";

const {App} = AppContextModule(
    inject({
        io:window.io,
        env:process.env.NODE_ENV
    })
);
ReactDOM.render(
  <App />,
  document.getElementById('root')
);
