import type { StyleProp, ViewStyle } from "react-native";

export type ChangeEventPayload = {
  value: string;
  [key: string]: any;
};

export type ExpoWebexCallingViewProps = {
  name: string;
  style?: StyleProp<ViewStyle>;
};
