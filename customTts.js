const fs = require("fs");
const path = require("path");

class AudioResources
{
    constructor()
    {
        this.resources = {};
    }

    getResourceKey(text, voiceInfo) {
        return [
          voiceInfo.lang ?? "",
          voiceInfo.speaker ?? "",
          voiceInfo.emotion ?? "Neutral",
          voiceInfo.speed ?? 1,
          voiceInfo.variation ?? 0,
          text,
        ].join("|");
      }

    async appendJson(folder, pack)
    {
        const errors = [];
        let i = 0;
        for (const phrase of pack.phrases ?? []) {
          i++;
          // валидация
          if (phrase.phrase === undefined) {
            errors.push(`For ${i} phrase field 'phrase' is undefined`);
            continue;
          }
          if (phrase.audio === undefined) {
            errors.push(`For ${i} phrase field 'audio' is undefined`);
            continue;
          }
          const audioFile = path.join(folder, phrase.audio);
          if (!fs.existsSync(audioFile)) {
            errors.push(`For ${i} phrase "${phrase.phrase}" file not found`);
            continue;
          }
          phrase.voice = { ...pack.voice, ...phrase.voice };
          const resourceKey = this.getResourceKey(phrase.phrase, phrase.voice ?? {});
          if (resourceKey in this.resources) {
            // дубликат - не ошибка
            console.warn("Skip", i, "phrase because it's duplicate");
            continue;
          }
          this.resources[resourceKey] = audioFile;
        }
        if(errors.length > 0)
        {
          console.error(`Was errors ${JSON.stringify(errors)}`)
        }
    }

    async addFolder(folder)
    {
        const files = fs.readdirSync(folder);
        for (const fileName of files)
        {
            if (path.extname(fileName) === ".json")
            {
                const fname = path.join(folder, fileName);
                console.log(`Parsing ${fname}`);
                await this.appendJson(folder, JSON.parse(fs.readFileSync(fname).toString()));
            }
        }
    }

    GetPath(text, voiceInfo)
    {
        const key = this.getResourceKey(text, voiceInfo);
        const fpath = this.resources[key];
        if (fpath === undefined)
          throw new Error(`Failed to get ${key}`);
        return fpath;
    }
}


module.exports = AudioResources;