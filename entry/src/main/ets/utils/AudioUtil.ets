import { media } from '@kit.MediaKit';
import { BASE_URL } from './Constants';
import { HttpUtil } from './HttpUtil';

interface TtsResponse {
  url: string | null;
  fallback: string;
}

export class AudioUtil {
  private static avPlayer: media.AVPlayer | null = null;
  private static isPlaying: boolean = false;

  /**
   * 播放单词发音
   * 1. 调用后端 /api/tts/:word 获取音频 URL
   * 2. 优先播放后端缓存的本地音频
   * 3. 失败则降级到有道 TTS 在线链接
   */
  static async playWord(word: string): Promise<void> {
    if (AudioUtil.isPlaying) {
      return;
    }
    AudioUtil.isPlaying = true;

    try {
      // 获取音频 URL
      const res = await HttpUtil.get(`/api/tts/${word}`) as Record<string, Object>;
      const url = res['url'] as string | null;
      const fallback = res['fallback'] as string;

      let audioUrl: string;
      if (url) {
        audioUrl = BASE_URL + url;
      } else {
        audioUrl = fallback;
      }

      await AudioUtil.play(audioUrl);
    } catch (err) {
      // 所有方式都失败，直接用有道在线链接
      const fallbackUrl = `https://dict.youdao.com/dictvoice?audio=${word}&type=1`;
      try {
        await AudioUtil.play(fallbackUrl);
      } catch (e) {
        console.error('AudioUtil playWord all failed', JSON.stringify(e));
      }
    } finally {
      AudioUtil.isPlaying = false;
    }
  }

  private static async play(url: string): Promise<void> {
    return new Promise<void>(async (resolve, reject) => {
      try {
        // 释放旧播放器
        if (AudioUtil.avPlayer) {
          await AudioUtil.avPlayer.release();
          AudioUtil.avPlayer = null;
        }

        const player = await media.createAVPlayer();
        AudioUtil.avPlayer = player;

        player.on('stateChange', (state: string) => {
          if (state === 'initialized') {
            player.prepare();
          } else if (state === 'prepared') {
            player.play();
          } else if (state === 'completed') {
            player.release();
            AudioUtil.avPlayer = null;
            resolve();
          } else if (state === 'error') {
            player.release();
            AudioUtil.avPlayer = null;
            reject(new Error('AVPlayer error'));
          }
        });

        player.on('error', (err: Error) => {
          player.release();
          AudioUtil.avPlayer = null;
          reject(err);
        });

        player.url = url;
      } catch (err) {
        reject(err);
      }
    });
  }

  static getIsPlaying(): boolean {
    return AudioUtil.isPlaying;
  }
}
