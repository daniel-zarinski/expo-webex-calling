import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

import { ExpoWebexCallingViewProps } from "./ExpoWebexCalling.types";

const NativeView: React.ComponentType<ExpoWebexCallingViewProps> =
  requireNativeViewManager("ExpoWebexCalling");

export default function ExpoWebexCallingView(props: ExpoWebexCallingViewProps) {
  return <NativeView {...props} />;
}
