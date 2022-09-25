import { StyleSheet, Text, View } from "react-native";

import * as ExpoWebexCalling from "expo-webex-calling";

export default function App() {
  return (
    <View style={styles.container}>
      <Text>{ExpoWebexCalling.hello()}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
  },
});
