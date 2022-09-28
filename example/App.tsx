import * as ExpoWebexCalling from "expo-webex-calling";
import { useEffect, useState } from "react";
import { Button, StyleSheet, Text, View } from "react-native";

export default function App() {
  const [isCallActive, setIsCallActive] = useState(false);
  const [isCallIncoming, setIsCallIncoming] = useState(false);
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  useEffect(() => {
    const subscriptions = [
      ExpoWebexCalling.onLogin(({ isLoggedIn }) => {
        console.debug("onLogin", { isLoggedIn });
        setIsLoggedIn(isLoggedIn);
      }),
      ExpoWebexCalling.onStatusChange(({ status }) => {
        console.log("onStatusChange", { status });

        switch (status) {
          case ExpoWebexCalling.CallStatus.Disconnected:
            setIsCallIncoming(false);
            setIsCallActive(false);
            break;
          case ExpoWebexCalling.CallStatus.Connected:
            setIsCallActive(true);
            setIsCallIncoming(false);
            break;

          default:
            console.error("Unhandled status", { status });
        }
      }),
      ExpoWebexCalling.onIncomingCall((event) => {
        console.log("onIncomingCall", JSON.stringify(event));
        setIsCallIncoming(true);
      }),
      ExpoWebexCalling.onCallParticipantChange((event) => {
        console.log("onCallParticipantChange", {
          event: JSON.stringify(event),
          memberships: event.memberships && JSON.stringify(event.memberships),
        });
      }),
    ];

    return () => {
      subscriptions.forEach((subscription) => {
        subscription.remove();
      });
    };
  }, []);

  return (
    <View style={styles.container}>
      <Text>{isCallActive ? "Call Active" : ""}</Text>

      <Button
        title="Initialize"
        onPress={async () => {
          const data = await ExpoWebexCalling.initWebex();
          console.log({ data });
        }}
      />

      {isCallIncoming && (
        <Button
          title="Answer"
          onPress={async () => {
            const data = await ExpoWebexCalling.answerCall();
            console.log({ data });
          }}
        />
      )}

      {!isLoggedIn && (
        <Button
          title="Authenticate"
          onPress={async () => {
            const data = await ExpoWebexCalling.authenticate(
              "OTc0Mzg1MjQtODljNS00NzNjLWIxZjUtNWYwYTIzZWEwYmVkODMzNGFkMGYtYzc3_PF84_488b9dff-0deb-4421-98ae-d35be1f1c0fa"
            );
            console.log({ data });
          }}
        />
      )}

      {isCallActive && (
        <ExpoWebexCalling.ExpoWebexCallingView
          name="incoming"
          style={{
            width: 300,
            height: 300,
            backgroundColor: "red",
          }}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fafafa",
    alignItems: "center",
    justifyContent: "center",
  },
});
