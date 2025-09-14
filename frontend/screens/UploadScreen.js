import React, { useState } from "react";
import { View, Button, Text } from "react-native";
import DocumentPicker from "react-native-document-picker";
import axios from "axios";
import Sound from "react-native-sound";

export default function UploadScreen() {
  const [status, setStatus] = useState("");
  const [sound, setSound] = useState(null);

  const pickFile = async () => {
    try {
      const res = await DocumentPicker.pickSingle({ type: [DocumentPicker.types.allFiles] });
      setStatus("Uploading...");

      const formData = new FormData();
      formData.append("file", {
        uri: res.uri,
        type: res.type,
        name: res.name
      });

      const response = await axios.post("http://10.0.2.2:8000/upload", formData, {
        headers: { "Content-Type": "multipart/form-data" },
        responseType: "arraybuffer"
      });

      const blob = new Blob([response.data], { type: "audio/mpeg" });
      const audioUrl = URL.createObjectURL(blob);

      const newSound = new Sound(audioUrl, null, (err) => {
        if (err) console.log("Error loading sound:", err);
        else {
          setSound(newSound);
          setStatus("Ready to play");
        }
      });

    } catch (err) {
      console.log(err);
      setStatus("Error uploading file");
    }
  };

  return (
    <View style={{ flex:1, justifyContent:"center", alignItems:"center" }}>
      <Button title="Pick a File" onPress={pickFile} />
      <Text>{status}</Text>
      {sound && (
        <>
          <Button title="Play" onPress={() => sound.play()} />
          <Button title="Pause" onPress={() => sound.pause()} />
        </>
      )}
    </View>
  );
}
