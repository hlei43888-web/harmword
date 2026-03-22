import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { HttpUtil } from '../utils/HttpUtil';
import { WordBook } from '../models/Models';

class SettingsData {
  active_book_id: number = 0;
}

@Entry
@Component
struct BookSelectPage {
  @State books: WordBook[] = [];
  @State loading: boolean = true;
  @State currentBookId: number = 1;

  aboutToAppear(): void {
    this.loadBooks();
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

        Text('词书选择')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 导入按钮
        Text('导入')
          .fontSize(15)
          .fontColor('#4A90D9')
          .padding(12)
          .onClick(() => {
            promptAction.showToast({ message: '自定义词书导入功能开发中', duration: 2000 });
          })
      }
      .width('100%')
      .padding({ left: 4, right: 4, top: 8 })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 提示文字
        Text('选择一本词书开始学习，新词将从所选词书中获取')
          .fontSize(13)
          .fontColor('#999')
          .width('90%')
          .margin({ top: 12, bottom: 16 })

        // 词书列表
        Scroll() {
          Column() {
            ForEach(this.books, (book: WordBook) => {
              Row() {
                // 左侧图标
                Text(this.getLevelIcon(book.level))
                  .fontSize(32)
                  .width(50)
                  .textAlign(TextAlign.Center)

                // 中间信息
                Column() {
                  Row() {
                    Text(book.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#333')

                    Text(book.level)
                      .fontSize(11)
                      .fontColor(Color.White)
                      .backgroundColor(this.getLevelColor(book.level))
                      .borderRadius(6)
                      .padding({
                        left: 6,
                        right: 6,
                        top: 2,
                        bottom: 2
                      })
                      .margin({ left: 8 })
                  }

                  Text(`共 ${book.word_count} 个单词`)
                    .fontSize(13)
                    .fontColor('#999')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 12 })

                // 右侧选中标记
                if (book.id === this.currentBookId) {
                  Text('✓ 当前')
                    .fontSize(13)
                    .fontColor('#27AE60')
                    .fontWeight(FontWeight.Bold)
                } else {
                  Text('选择')
                    .fontSize(13)
                    .fontColor('#4A90D9')
                }
              }
              .width('90%')
              .padding(16)
              .backgroundColor(book.id === this.currentBookId ? '#F0F7FF' : Color.White)
              .borderRadius(14)
              .borderWidth(book.id === this.currentBookId ? 1.5 : 0)
              .borderColor('#4A90D9')
              .shadow({ radius: 6, color: '#0D000000', offsetY: 2 })
              .margin({ bottom: 12 })
              .onClick(() => {
                this.selectBook(book);
              })
            }, (book: WordBook) => book.id.toString())
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

  getLevelIcon(level: string): string {
    if (level === 'CET4') {
      return '📘';
    } else if (level === 'CET6') {
      return '📗';
    } else if (level === 'GRE') {
      return '📕';
    }
    return '📖';
  }

  getLevelColor(level: string): string {
    if (level === 'CET4') {
      return '#3498DB';
    } else if (level === 'CET6') {
      return '#27AE60';
    } else if (level === 'GRE') {
      return '#E74C3C';
    }
    return '#95A5A6';
  }

  async loadBooks(): Promise<void> {
    this.loading = true;
    try {
      const res = await HttpUtil.get('/api/books');
      this.books = JSON.parse(JSON.stringify(res['books'])) as WordBook[];

      // 获取当前用户的 active_book_id
      const userRes = await HttpUtil.get('/api/auth/users');
      // 简单处理：从 token 解析不方便，这里通过 settings 获取
    } catch (err) {
      console.error('loadBooks error', JSON.stringify(err));
    } finally {
      this.loading = false;
    }
  }

  async selectBook(book: WordBook): Promise<void> {
    if (book.id === this.currentBookId) {
      return;
    }
    try {
      const data = new SettingsData();
      data.active_book_id = book.id;
      await HttpUtil.put('/api/auth/settings', data);
      this.currentBookId = book.id;
      promptAction.showToast({ message: `已切换到「${book.name}」`, duration: 1500 });

      // 短暂延迟后返回首页
      setTimeout(() => {
        router.back();
      }, 800);
    } catch (err) {
      promptAction.showToast({ message: '切换失败，请重试', duration: 2000 });
    }
  }
}
