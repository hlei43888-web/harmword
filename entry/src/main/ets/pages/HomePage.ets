import { router } from '@kit.ArkUI';
import { HttpUtil } from '../utils/HttpUtil';
import { WordItem } from '../models/Models';

@Component
export struct HomePage {
  @State reviewWords: WordItem[] = [];
  @State newWords: WordItem[] = [];
  @State dailyGoal: number = 20;
  @State totalToday: number = 0;
  @State loading: boolean = true;
  @State dateStr: string = '';

  aboutToAppear(): void {
    this.loadTodayWords();
  }

  build() {
    Column() {
      // 顶部标题
      Text('今日学习')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 12 })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999')
            .margin({ top: 12 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 任务概览卡片
            Column() {
              Text(this.dateStr)
                .fontSize(13)
                .fontColor('#999')
                .margin({ bottom: 12 })

              Row() {
                this.StatBlock(`${this.totalToday}`, '今日任务')
                this.StatBlock(`${this.reviewWords.length}`, '待复习')
                this.StatBlock(`${this.newWords.length}`, '新单词')
                this.StatBlock(`${this.dailyGoal}`, '每日目标')
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
            }
            .width('90%')
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
            .margin({ top: 8, bottom: 20 })

            // 开始学习按钮
            if (this.totalToday > 0) {
              Button('开始学习')
                .width('90%')
                .height(52)
                .backgroundColor('#4A90D9')
                .fontColor(Color.White)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .borderRadius(14)
                .margin({ bottom: 24 })
                .onClick(() => {
                  const allWords: WordItem[] = [...this.reviewWords, ...this.newWords];
                  router.pushUrl({
                    url: 'pages/StudyPage',
                    params: { words: JSON.stringify(allWords) }
                  });
                })
            } else {
              Column() {
                Text('🎉')
                  .fontSize(48)
                Text('今日任务已完成！')
                  .fontSize(18)
                  .fontColor('#4A90D9')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 12 })
              }
              .margin({ top: 20, bottom: 24 })
            }

            // 待复习单词列表
            if (this.reviewWords.length > 0) {
              Text('待复习')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#666')
                .width('90%')
                .margin({ bottom: 8 })

              ForEach(this.reviewWords, (item: WordItem) => {
                this.WordRow(item, true)
              }, (item: WordItem) => item.id.toString())
            }

            // 新词列表
            if (this.newWords.length > 0) {
              Text('新单词')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#666')
                .width('90%')
                .margin({ top: 16, bottom: 8 })

              ForEach(this.newWords, (item: WordItem) => {
                this.WordRow(item, false)
              }, (item: WordItem) => item.id.toString())
            }
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
  StatBlock(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4A90D9')
      Text(label)
        .fontSize(12)
        .fontColor('#999')
        .margin({ top: 4 })
    }
  }

  @Builder
  WordRow(item: WordItem, isReview: boolean) {
    Row() {
      Column() {
        Text(item.word)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Text(item.meaning)
          .fontSize(13)
          .fontColor('#666')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (isReview) {
        Text(`Lv.${item.mastery_level}`)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#4A90D9')
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      } else {
        Text('NEW')
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#E67E22')
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      }
    }
    .width('90%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  async loadTodayWords(): Promise<void> {
    this.loading = true;
    try {
      const res = await HttpUtil.get('/api/words/today');
      this.dateStr = res['date'] as string;
      this.dailyGoal = res['daily_goal'] as number;
      this.totalToday = res['total'] as number;

      const reviewArr = res['review_words'];
      const newArr = res['new_words'];
      this.reviewWords = JSON.parse(JSON.stringify(reviewArr)) as WordItem[];
      this.newWords = JSON.parse(JSON.stringify(newArr)) as WordItem[];
    } catch (err) {
      console.error('loadTodayWords error', JSON.stringify(err));
    } finally {
      this.loading = false;
    }
  }
}
