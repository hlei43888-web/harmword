import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { HttpUtil } from '../utils/HttpUtil';
import { WordItem } from '../models/Models';

@Component
export struct FavoritesPage {
  @State currentTab: number = 1; // 0=收藏夹, 1=错词本
  @State words: WordItem[] = [];
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.loadList();
  }

  build() {
    Column() {
      Text('错词本')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 12 })

      // Tab 切换
      Row() {
        this.TabButton('收藏夹', 0)
        this.TabButton('错词本', 1)
      }
      .width('90%')
      .backgroundColor('#F0F0F0')
      .borderRadius(10)
      .padding(3)
      .margin({ bottom: 16 })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.words.length === 0) {
        Column() {
          Text(this.currentTab === 0 ? '📑' : '✅')
            .fontSize(48)
          Text(this.currentTab === 0 ? '收藏夹为空' : '没有错词，继续加油！')
            .fontSize(16)
            .fontColor('#999')
            .margin({ top: 12 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 单词列表
        List() {
          ForEach(this.words, (item: WordItem) => {
            ListItem() {
              Row() {
                Column() {
                  Row() {
                    Text(item.word)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#333')

                    Text(item.phonetic)
                      .fontSize(13)
                      .fontColor('#999')
                      .margin({ left: 8 })
                  }

                  Text(item.meaning)
                    .fontSize(13)
                    .fontColor('#666')
                    .margin({ top: 4 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 删除按钮
                Text(this.currentTab === 0 ? '❤️' : '✕')
                  .fontSize(this.currentTab === 0 ? 20 : 18)
                  .fontColor(this.currentTab === 0 ? '#E74C3C' : '#999')
                  .padding(8)
                  .onClick(() => {
                    this.removeItem(item);
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor(Color.White)
              .borderRadius(12)
            }
            .margin({ left: '5%', right: '5%', bottom: 8 })
          }, (item: WordItem) => `${item.id}_${this.currentTab}`)
        }
        .layoutWeight(1)

        // 底部按钮
        if (this.currentTab === 1 && this.words.length > 0) {
          Button(`开始学习错词 (${this.words.length})`)
            .width('90%')
            .height(50)
            .backgroundColor('#E74C3C')
            .fontColor(Color.White)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .borderRadius(14)
            .margin({ top: 8, bottom: 20 })
            .onClick(() => {
              const wordsWithDefaults: WordItem[] = this.words.map((w: WordItem): WordItem => {
                return {
                  id: w.id,
                  word: w.word,
                  phonetic: w.phonetic,
                  meaning: w.meaning,
                  example: w.example,
                  difficulty: w.difficulty,
                  mastery_level: 0,
                  review_count: 0,
                  next_review_at: null
                };
              });
              router.pushUrl({
                url: 'pages/StudyPage',
                params: { words: JSON.stringify(wordsWithDefaults) }
              });
            })
        }

        if (this.currentTab === 0 && this.words.length > 0) {
          Button(`复习收藏单词 (${this.words.length})`)
            .width('90%')
            .height(50)
            .backgroundColor('#4A90D9')
            .fontColor(Color.White)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .borderRadius(14)
            .margin({ top: 8, bottom: 20 })
            .onClick(() => {
              const wordsWithDefaults: WordItem[] = this.words.map((w: WordItem): WordItem => {
                return {
                  id: w.id,
                  word: w.word,
                  phonetic: w.phonetic,
                  meaning: w.meaning,
                  example: w.example,
                  difficulty: w.difficulty,
                  mastery_level: 0,
                  review_count: 0,
                  next_review_at: null
                };
              });
              router.pushUrl({
                url: 'pages/StudyPage',
                params: { words: JSON.stringify(wordsWithDefaults) }
              });
            })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  TabButton(label: string, index: number) {
    Text(label)
      .fontSize(14)
      .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.currentTab === index ? Color.White : '#666')
      .backgroundColor(this.currentTab === index ? '#4A90D9' : Color.Transparent)
      .borderRadius(8)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        if (this.currentTab !== index) {
          this.currentTab = index;
          this.loadList();
        }
      })
  }

  async loadList(): Promise<void> {
    this.loading = true;
    try {
      const res = await HttpUtil.get(`/api/favorites?type=${this.currentTab}`);
      this.words = JSON.parse(JSON.stringify(res['words'])) as WordItem[];
    } catch (err) {
      console.error('loadFavorites error', JSON.stringify(err));
    } finally {
      this.loading = false;
    }
  }

  async removeItem(item: WordItem): Promise<void> {
    try {
      await HttpUtil.delete(`/api/favorites/${item.id}?type=${this.currentTab}`);
      // 从本地列表移除
      this.words = this.words.filter((w: WordItem) => w.id !== item.id);
      promptAction.showToast({
        message: this.currentTab === 0 ? '已取消收藏' : '已移出错词本',
        duration: 1500
      });
    } catch (err) {
      promptAction.showToast({ message: '操作失败', duration: 1500 });
    }
  }
}
