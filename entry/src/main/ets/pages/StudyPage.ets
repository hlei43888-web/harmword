import { router } from '@kit.ArkUI';
import { HttpUtil } from '../utils/HttpUtil';
import { WordItem } from '../models/Models';

interface StudyParams {
  words: string;
}

interface SubmitResultData {
  word_id: number;
  result: number;
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

  aboutToAppear(): void {
    const params = router.getParams() as StudyParams;
    if (params && params.words) {
      this.words = JSON.parse(params.words) as WordItem[];
      this.totalCount = this.words.length;
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
        // 学习完成页
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

          Text(`记住 ${this.correctCount} 个，正确率 ${Math.round((this.correctCount / Math.max(this.totalCount, 1)) *
            100)}%`)
            .fontSize(15)
            .fontColor('#4A90D9')
            .margin({ top: 8 })

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
      } else if (this.words.length > 0) {
        // 单词卡片区域
        Column() {
          this.WordCard()
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        // 底部操作按钮
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  WordCard() {
    if (this.currentIndex < this.words.length) {
      Column() {
        // 单词
        Text(this.words[this.currentIndex].word)
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ bottom: 8 })

        // 音标
        Text(this.words[this.currentIndex].phonetic)
          .fontSize(18)
          .fontColor('#999')
          .margin({ bottom: 24 })

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

      // 下一个单词
      this.currentIndex++;
      this.showAnswer = false;

      if (this.currentIndex >= this.words.length) {
        this.finished = true;
      }
    } catch (err) {
      console.error('submitResult error', JSON.stringify(err));
    } finally {
      this.submitting = false;
    }
  }
}
