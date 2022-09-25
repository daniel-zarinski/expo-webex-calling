import {
  NativeModulesProxy,
  EventEmitter,
  Subscription,
} from "expo-modules-core";

// Import the native module. On web, it will be resolved to ExpoWebexCalling.web.ts
// and on native platforms to ExpoWebexCalling.ts
import ExpoWebexCalling from "./ExpoWebexCallingModule";
import ExpoWebexCallingView from "./ExpoWebexCallingView";
import {
  ChangeEventPayload,
  ExpoWebexCallingViewProps,
} from "./ExpoWebexCalling.types";

// Get the native constant value.
export const PI = ExpoWebexCalling.PI;

export function hello(): string {
  return ExpoWebexCalling.hello();
}

export async function setValueAsync(value: string) {
  return await ExpoWebexCalling.setValueAsync(value);
}

// For now the events are not going through the JSI, so we have to use its bridge equivalent.
// This will be fixed in the stable release and built into the module object.
// Note: On web, NativeModulesProxy.ExpoWebexCalling is undefined, so we fall back to the directly imported implementation
const emitter = new EventEmitter(
  NativeModulesProxy.ExpoWebexCalling ?? ExpoWebexCalling
);

export function addChangeListener(
  listener: (event: ChangeEventPayload) => void
): Subscription {
  return emitter.addListener<ChangeEventPayload>("onChange", listener);
}

export { ExpoWebexCallingView, ExpoWebexCallingViewProps, ChangeEventPayload };
