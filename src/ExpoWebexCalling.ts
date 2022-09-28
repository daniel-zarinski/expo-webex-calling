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

export function initWebex(): Promise<void> {
  return ExpoWebexCalling.initWebex();
}

export function answerCall(): Promise<void> {
  return ExpoWebexCalling.answerCall();
}

export function authenticate(token: string): Promise<boolean> {
  return ExpoWebexCalling.authenticate(token);
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

export enum EventTypes {
  onLogin = "onLogin",
  onCallIncoming = "onCallIncoming",
  onCallParticipantsChange = "onCallParticipantsChange",
  OnCallStatusChange = "OnCallStatusChange",
}

export enum CallStatus {
  Disconnected = "disconnected",
  ParticipantsChaned = "participants-changed",
  Connected = "connected",
}

export function onLogin(
  listener: (success: { isLoggedIn: boolean }) => void
): Subscription {
  return emitter.addListener(EventTypes.onLogin, listener);
}

export function onIncomingCall(listener: (data: any) => void): Subscription {
  return emitter.addListener(EventTypes.onCallIncoming, listener);
}

export function onStatusChange(
  listener: (data: { status: CallStatus }) => void
): Subscription {
  return emitter.addListener(EventTypes.OnCallStatusChange, listener);
}

export function onCallParticipantChange(
  listener: (data: any) => void
): Subscription {
  return emitter.addListener(EventTypes.onCallParticipantsChange, listener);
}

export { ExpoWebexCallingView, ExpoWebexCallingViewProps, ChangeEventPayload };
