const dasha = require("@dasha.ai/sdk");
const AudioResources = require("./customTts.js");
const fs = require("fs");

async function main() {
  const app = await dasha.deploy("./app");
  const audio = new AudioResources();
  audio.addFolder("audio");

  app.ttsDispatcher = (conv) => "custom";
  app.customTtsProvider = async (text, voice) => {
    console.log(`Tts asking for phrase with text ${text} and voice ${JSON.stringify(voice)}`);
    const fname = audio.GetPath(text, voice);

    console.log(`Found in file ${fname}`);
    return dasha.audio.fromFile(fname);
  };

  app.connectionProvider = async (conv) =>
    conv.input.phone === "chat"
      ? dasha.chat.connect(await dasha.chat.createConsoleChat())
      : dasha.sip.connect(new dasha.sip.Endpoint("default"));

  await app.start();

  const conv = app.createConversation({
    phone: process.argv[2],
  });

  if (conv.input.phone !== "chat") conv.on("transcription", console.log);

  const logFile = await fs.promises.open("./log.txt", "w");
  await logFile.appendFile("#".repeat(100) + "\n");

  conv.on("transcription", async (entry) => {
    await logFile.appendFile(`${entry.speaker}: ${entry.text}\n`);
  });

  conv.on("debugLog", async (event) => {
    if (event?.msg?.msgId === "RecognizedSpeechMessage") {
      const logEntry = event?.msg?.results[0]?.facts;
      await logFile.appendFile(JSON.stringify(logEntry, undefined, 2) + "\n");
    }
  });

  const result = await conv.execute();
  console.log(result.output);

  await app.stop();
  app.dispose();

  await logFile.close();
}

main();
