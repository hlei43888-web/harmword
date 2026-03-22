import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { HttpUtil } from '../utils/HttpUtil';
import { AudioUtil } from '../utils/AudioUtil';
import { WordItem } from '../models/Models';

interface StudyParams {
  words: string;
  mode: string;
}

interface SubmitResultData {
  word_id: number;
  result: number;
}

interface FavoriteData {
  word_id: number;
  type: number;
}

@Entry
@Component
@Preview
struct StudyPage {
  @State words: WordItem[] = [];
  @State currentIndex: number = 0;
  @State showAnswer: boolean = false;
  @State submitting: boolean = false;
  @State finished: boolean = false;
  @State correctCount: number = 0;
  @State totalCount: number = 0;
  @State playingAudio: boolean = false;
  @State favoritedSet: Set<number> = new Set<number>();
  @State mode: string = 'card';
  // 听写/拼写模式状态
  @State userInput: string = '';
  @State inputSubmitted: boolean = false;
  @State inputCorrect: boolean = false;
  private debounceTimer: number = -1;

  aboutToAppear(): void {
    const params = router.getParams() as StudyParams;
    if (params && params.words) {
      this.words = JSON.parse(params.words) as WordItem[];
      this.totalCount = this.words.length;
    }
    if (params && params.mode) {
      this.mode = params.mode;
    }
    // 听写模式自动播放第一个单词
    if (this.mode === 'dictation' && this.words.length > 0) {
      this.handlePlayAudio();
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#333')
          .onClick(() => {
            router.back();
          })
          .padding(12)

        Text(`${this.currentIndex + 1} / ${this.totalCount}`)
          .fontSize(16)
          .fontColor('#666')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 进度指示
        Text(`${Math.round((this.currentIndex / Math.max(this.totalCount, 1)) * 100)}%`)
          .fontSize(14)
          .fontColor('#4A90D9')
          .padding(12)
      }
      .width('100%')
      .padding({ left: 4, right: 4, top: 8 })

      // 进度条
      Progress({ value: this.currentIndex, total: Math.max(this.totalCount, 1), type: ProgressType.Linear })
        .width('90%')
        .height(4)
        .color('#4A90D9')
        .backgroundColor('#E8E8E8')
        .margin({ bottom: 20 })

      if (this.finished) {
        this.FinishedView()
      } else if (this.words.length > 0) {
        if (this.mode === 'card') {
          this.CardModeView()
        } else if (this.mode === 'dictation') {
          this.DictationModeView()
        } else if (this.mode === 'spell') {
          this.SpellModeView()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
    .expandSafeArea([SafeAreaType.KEYBOARD])
  }

  @Builder
  FinishedView() {
    Column() {
      Text('🎉')
        .fontSize(60)
        .margin({ bottom: 16 })

      Text('学习完成！')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')

      Text(`本轮共学习 ${this.totalCount} 个单词`)
        .fontSize(15)
        .fontColor('#666')
        .margin({ top: 12 })

      if (this.mode === 'card') {
        Text(`记住 ${this.correctCount} 个，正确率 ${Math.round((this.correctCount / Math.max(this.totalCount, 1)) *
          100)}%`)
          .fontSize(15)
          .fontColor('#4A90D9')
          .margin({ top: 8 })
      } else {
        Text(`拼写正确 ${this.correctCount} 个，正确率 ${Math.round((this.correctCount / Math.max(this.totalCount, 1)) *
          100)}%`)
          .fontSize(15)
          .fontColor('#4A90D9')
          .margin({ top: 8 })
      }

      Button('返回首页')
        .width('60%')
        .height(46)
        .backgroundColor('#4A90D9')
        .fontColor(Color.White)
        .fontSize(16)
        .borderRadius(12)
        .margin({ top: 40 })
        .onClick(() => {
          router.back();
        })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // ========== 卡片模式 ==========
  @Builder
  CardModeView() {
    Column() {
      this.WordCard()
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)

    if (this.showAnswer) {
      Row() {
        Button('忘记')
          .layoutWeight(1)
          .height(50)
          .backgroundColor('#E74C3C')
          .fontColor(Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .borderRadius(12)
          .margin({ right: 6 })
          .enabled(!this.submitting)
          .onClick(() => {
            this.submitResult(0);
          })

        Button('模糊')
          .layoutWeight(1)
          .height(50)
          .backgroundColor('#F39C12')
          .fontColor(Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .borderRadius(12)
          .margin({ left: 6, right: 6 })
          .enabled(!this.submitting)
          .onClick(() => {
            this.submitResult(1);
          })

        Button('记住')
          .layoutWeight(1)
          .height(50)
          .backgroundColor('#27AE60')
          .fontColor(Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .borderRadius(12)
          .margin({ left: 6 })
          .enabled(!this.submitting)
          .onClick(() => {
            this.submitResult(2);
          })
      }
      .width('90%')
      .padding({ bottom: 30 })
    } else {
      Button('点击显示答案')
        .width('90%')
        .height(50)
        .backgroundColor('#4A90D9')
        .fontColor(Color.White)
        .fontSize(16)
        .borderRadius(12)
        .margin({ bottom: 30 })
        .onClick(() => {
          this.showAnswer = true;
        })
    }
  }

  // ========== 听写模式 ==========
  @Builder
  DictationModeView() {
    if (this.currentIndex < this.words.length) {
      Scroll() {
        Column() {
          // 发音按钮卡片
          Column() {
            Text(this.playingAudio ? '🔊' : '🔈')
              .fontSize(60)
              .fontColor(this.playingAudio ? '#4A90D9' : '#999')
              .onClick(() => {
                this.handlePlayAudio();
              })

            Text('点击播放发音')
              .fontSize(14)
              .fontColor('#999')
              .margin({ top: 12 })
          }
          .width('85%')
          .padding(40)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 12, color: '#1A000000', offsetY: 4 })
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 20 })

          // 输入区域
          TextInput({ placeholder: '请输入听到的单词...', text: this.userInput })
            .width('85%')
            .height(50)
            .fontSize(18)
            .margin({ top: 30 })
            .borderRadius(12)
            .enabled(!this.inputSubmitted)
            .onChange((value: string) => {
              this.handleInputChange(value);
            })

          // 提交按钮
          if (!this.inputSubmitted) {
            Button('提交答案')
              .width('85%')
              .height(48)
              .backgroundColor('#4A90D9')
              .fontColor(Color.White)
              .fontSize(16)
              .borderRadius(12)
              .margin({ top: 16 })
              .enabled(this.userInput.trim().length > 0 && !this.submitting)
              .onClick(() => {
                this.checkAnswer();
              })
          }

          // 答案反馈
          if (this.inputSubmitted) {
            Column() {
              if (this.inputCorrect) {
                Text('✅ 正确！')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#27AE60')
              } else {
                Text('❌ 错误')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E74C3C')

                Text(`正确答案: ${this.words[this.currentIndex].word}`)
                  .fontSize(18)
                  .fontColor('#333')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 8 })
              }

              // 释义
              Text(this.words[this.currentIndex].meaning)
                .fontSize(16)
                .fontColor('#4A90D9')
                .margin({ top: 12 })

              Button('下一个')
                .width('60%')
                .height(44)
                .backgroundColor('#4A90D9')
                .fontColor(Color.White)
                .fontSize(16)
                .borderRadius(12)
                .margin({ top: 20 })
                .onClick(() => {
                  this.goNext();
                })
            }
            .margin({ top: 20 })
            .alignItems(HorizontalAlign.Center)
          }
        }
        .width('100%')
        .padding({ bottom: 30 })
      }
      .layoutWeight(1)
    }
  }

  // ========== 拼写模式 ==========
  @Builder
  SpellModeView() {
    if (this.currentIndex < this.words.length) {
      Scroll() {
        Column() {
          // 释义卡片（不显示英文）
          Column() {
            Text(this.words[this.currentIndex].meaning)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4A90D9')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 16 })

            if (this.words[this.currentIndex].example) {
              Divider()
                .width('80%')
                .color('#E8E8E8')
                .margin({ bottom: 16 })

              // 例句中隐藏英文单词
              Text(this.words[this.currentIndex].example
                .replace(new RegExp(this.words[this.currentIndex].word, 'gi'), '______'))
                .fontSize(15)
                .fontColor('#666')
                .textAlign(TextAlign.Center)
                .padding({ left: 20, right: 20 })
            }
          }
          .width('85%')
          .padding(30)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 12, color: '#1A000000', offsetY: 4 })
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 20 })

          // 输入区域
          TextInput({ placeholder: '请输入对应的英文单词...', text: this.userInput })
            .width('85%')
            .height(50)
            .fontSize(18)
            .margin({ top: 30 })
            .borderRadius(12)
            .enabled(!this.inputSubmitted)
            .onChange((value: string) => {
              this.handleInputChange(value);
            })

          // 提交按钮
          if (!this.inputSubmitted) {
            Button('提交答案')
              .width('85%')
              .height(48)
              .backgroundColor('#4A90D9')
              .fontColor(Color.White)
              .fontSize(16)
              .borderRadius(12)
              .margin({ top: 16 })
              .enabled(this.userInput.trim().length > 0 && !this.submitting)
              .onClick(() => {
                this.checkAnswer();
              })
          }

          // 答案反馈
          if (this.inputSubmitted) {
            Column() {
              if (this.inputCorrect) {
                Text('✅ 正确！')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#27AE60')
              } else {
                Text('❌ 错误')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E74C3C')

                Text(`正确答案: ${this.words[this.currentIndex].word}`)
                  .fontSize(18)
                  .fontColor('#333')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 8 })
              }

              // 发音按钮
              Text(this.playingAudio ? '🔊' : '🔈')
                .fontSize(28)
                .fontColor(this.playingAudio ? '#4A90D9' : '#999')
                .margin({ top: 12 })
                .onClick(() => {
                  this.handlePlayAudio();
                })

              Button('下一个')
                .width('60%')
                .height(44)
                .backgroundColor('#4A90D9')
                .fontColor(Color.White)
                .fontSize(16)
                .borderRadius(12)
                .margin({ top: 20 })
                .onClick(() => {
                  this.goNext();
                })
            }
            .margin({ top: 20 })
            .alignItems(HorizontalAlign.Center)
          }
        }
        .width('100%')
        .padding({ bottom: 30 })
      }
      .layoutWeight(1)
    }
  }

  @Builder
  WordCard() {
    if (this.currentIndex < this.words.length) {
      Column() {
        // 收藏按钮（右上角）
        Row() {
          Blank()
          Text(this.favoritedSet.has(this.words[this.currentIndex].id) ? '❤️' : '🤍')
            .fontSize(24)
            .onClick(() => {
              this.toggleFavorite();
            })
        }
        .width('100%')

        // 单词
        Text(this.words[this.currentIndex].word)
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ bottom: 8 })

        // 音标 + 发音按钮
        Row() {
          Text(this.words[this.currentIndex].phonetic)
            .fontSize(18)
            .fontColor('#999')

          // 发音按钮
          Text(this.playingAudio ? '🔊' : '🔈')
            .fontSize(22)
            .fontColor(this.playingAudio ? '#4A90D9' : '#999')
            .margin({ left: 10 })
            .onClick(() => {
              this.handlePlayAudio();
            })
        }
        .margin({ bottom: 24 })
        .justifyContent(FlexAlign.Center)

        if (this.showAnswer) {
          // 分隔线
          Divider()
            .width('80%')
            .color('#E8E8E8')
            .margin({ bottom: 20 })

          // 释义
          Text(this.words[this.currentIndex].meaning)
            .fontSize(20)
            .fontColor('#4A90D9')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 16 })
            .textAlign(TextAlign.Center)

          // 例句
          Text(this.words[this.currentIndex].example)
            .fontSize(15)
            .fontColor('#666')
            .textAlign(TextAlign.Center)
            .padding({ left: 20, right: 20 })

          // 难度标签
          Text(`难度: ${'★'.repeat(this.words[this.currentIndex].difficulty)}${'☆'.repeat(5 -
          this.words[this.currentIndex].difficulty)}`)
            .fontSize(13)
            .fontColor('#F39C12')
            .margin({ top: 16 })
        } else {
          Text('点击下方按钮查看释义')
            .fontSize(14)
            .fontColor('#CCC')
            .margin({ top: 20 })
        }
      }
      .width('85%')
      .padding(30)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 12, color: '#1A000000', offsetY: 4 })
      .alignItems(HorizontalAlign.Center)
    }
  }

  // 防抖处理输入
  handleInputChange(value: string): void {
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
    }
    this.debounceTimer = setTimeout(() => {
      this.userInput = value;
      this.debounceTimer = -1;
    }, 150) as number;
  }

  // 检查拼写答案
  async checkAnswer(): Promise<void> {
    if (this.currentIndex >= this.words.length || this.inputSubmitted) {
      return;
    }
    const correctWord = this.words[this.currentIndex].word.trim().toLowerCase();
    const userAnswer = this.userInput.trim().toLowerCase();
    this.inputCorrect = userAnswer === correctWord;
    this.inputSubmitted = true;

    // 自动提交结果
    const result = this.inputCorrect ? 2 : 0;
    await this.submitResult(result);
  }

  // 进入下一个单词
  goNext(): void {
    this.userInput = '';
    this.inputSubmitted = false;
    this.inputCorrect = false;

    this.currentIndex++;
    this.showAnswer = false;

    if (this.currentIndex >= this.words.length) {
      this.finished = true;
    } else if (this.mode === 'dictation') {
      // 听写模式自动播放下一个单词
      this.handlePlayAudio();
    }
  }

  async toggleFavorite(): Promise<void> {
    if (this.currentIndex >= this.words.length) {
      return;
    }
    const wordId = this.words[this.currentIndex].id;
    try {
      if (this.favoritedSet.has(wordId)) {
        await HttpUtil.delete(`/api/favorites/${wordId}?type=0`);
        this.favoritedSet.delete(wordId);
        // 触发 UI 更新
        this.favoritedSet = new Set<number>(this.favoritedSet);
        promptAction.showToast({ message: '已取消收藏', duration: 1000 });
      } else {
        const data: FavoriteData = { word_id: wordId, type: 0 };
        await HttpUtil.post('/api/favorites', data);
        this.favoritedSet.add(wordId);
        this.favoritedSet = new Set<number>(this.favoritedSet);
        promptAction.showToast({ message: '已收藏', duration: 1000 });
      }
    } catch (err) {
      console.error('toggleFavorite error', JSON.stringify(err));
    }
  }

  async handlePlayAudio(): Promise<void> {
    if (this.playingAudio || this.currentIndex >= this.words.length) {
      return;
    }
    this.playingAudio = true;
    try {
      const word = this.words[this.currentIndex].word;
      await AudioUtil.playWord(word);
    } catch (err) {
      console.error('playAudio error', JSON.stringify(err));
    } finally {
      this.playingAudio = false;
    }
  }

  async submitResult(result: number): Promise<void> {
    if (this.submitting || this.currentIndex >= this.words.length) {
      return;
    }
    this.submitting = true;

    try {
      const wordId = this.words[this.currentIndex].id;
      const data: SubmitResultData = {
        word_id: wordId,
        result: result
      };
      await HttpUtil.post('/api/words/result', data);

      if (result === 2) {
        this.correctCount++;
      }

      // 卡片模式在此处推进下一词，听写/拼写模式在 goNext 中推进
      if (this.mode === 'card') {
        this.currentIndex++;
        this.showAnswer = false;

        if (this.currentIndex >= this.words.length) {
          this.finished = true;
        }
      }
    } catch (err) {
      console.error('submitResult error', JSON.stringify(err));
    } finally {
      this.submitting = false;
    }
  }
}
