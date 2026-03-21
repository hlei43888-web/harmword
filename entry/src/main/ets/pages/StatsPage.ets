import { HttpUtil } from '../utils/HttpUtil';

@Component
export struct StatsPage {
  @State totalWords: number = 0;
  @State learnedWords: number = 0;
  @State masteredWords: number = 0;
  @State todayStudied: number = 0;
  @State streakDays: number = 0;
  @State accuracyPercent: number = 0;
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.loadStats();
  }

  build() {
    Column() {
      Text('学习统计')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 16 })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 今日学习卡片
            Column() {
              Text('今日已学')
                .fontSize(14)
                .fontColor('#999')
              Text(`${this.todayStudied}`)
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor('#4A90D9')
                .margin({ top: 4 })
              Text('个单词')
                .fontSize(14)
                .fontColor('#999')
            }
            .width('90%')
            .padding(24)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
            .margin({ top: 8, bottom: 16 })

            // 连续打卡 + 正确率
            Row() {
              Column() {
                Text(`${this.streakDays}`)
                  .fontSize(32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E67E22')
                Text('连续打卡(天)')
                  .fontSize(12)
                  .fontColor('#999')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })

              Column() {
                Text(`${this.accuracyPercent}%`)
                  .fontSize(32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#27AE60')
                Text('正确率')
                  .fontSize(12)
                  .fontColor('#999')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
              .margin({ left: 12 })
            }
            .width('90%')
            .margin({ bottom: 16 })

            // 词汇进度卡片
            Column() {
              Text('词汇进度')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')
                .width('100%')
                .margin({ bottom: 16 })

              this.ProgressRow('总词汇量', this.totalWords, this.totalWords)
              this.ProgressRow('已学习', this.learnedWords, this.totalWords)
              this.ProgressRow('已掌握', this.masteredWords, this.totalWords)
              this.ProgressRow('未学习', this.totalWords - this.learnedWords, this.totalWords)
            }
            .width('90%')
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
            .margin({ bottom: 20 })
          }
          .width('100%')
          .padding({ bottom: 20 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  ProgressRow(label: string, current: number, total: number) {
    Column() {
      Row() {
        Text(label)
          .fontSize(14)
          .fontColor('#666')
        Text(`${current} / ${total}`)
          .fontSize(14)
          .fontColor('#333')
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Progress({ value: current, total: Math.max(total, 1), type: ProgressType.Linear })
        .width('100%')
        .height(6)
        .color('#4A90D9')
        .backgroundColor('#E8E8E8')
        .margin({ top: 6, bottom: 14 })
    }
  }

  async loadStats(): Promise<void> {
    this.loading = true;
    try {
      const res = await HttpUtil.get('/api/stats/overview');
      this.totalWords = res['total_words'] as number;
      this.learnedWords = res['learned_words'] as number;
      this.masteredWords = res['mastered_words'] as number;
      this.todayStudied = res['today_studied'] as number;
      this.streakDays = res['streak_days'] as number;
      this.accuracyPercent = res['accuracy_percent'] as number;
    } catch (err) {
      console.error('loadStats error', JSON.stringify(err));
    } finally {
      this.loading = false;
    }
  }
}
