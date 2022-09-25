import * as React from 'react';

import { ExpoWebexCallingViewProps } from './ExpoWebexCalling.types';

function ExpoWebexCallingWebView(props: ExpoWebexCallingViewProps) {
  return (
    <div>
      <span>{props.name}</span>
    </div>
  );
}

export default ExpoWebexCallingWebView;
