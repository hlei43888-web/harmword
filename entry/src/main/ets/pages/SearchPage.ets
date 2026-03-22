import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { HttpUtil } from '../utils/HttpUtil';
import { AudioUtil } from '../utils/AudioUtil';
import { SearchWordItem } from '../models/Models';

interface FavoriteData {
  word_id: number;
  type: number;
}

@Entry
@Component
@Preview
struct SearchPage {
  @State searchValue: string = '';
  @State results: SearchWordItem[] = [];
  @State loading: boolean = false;
  @State hasSearched: boolean = false;
  @State selectedItem: SearchWordItem | null = null;
  @State showPanel: boolean = false;
  @State playingAudio: boolean = false;
  private debounceTimer: number = -1;

  build() {
    Column() {
      // 顶部导航 + 搜索栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#333')
          .onClick(() => {
            router.back();
          })
          .padding({
            left: 12,
            right: 8,
            top: 12,
            bottom: 12
          })

        Search({ value: this.searchValue, placeholder: '搜索单词或释义...' })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F0F0F0')
          .borderRadius(20)
          .onChange((value: string) => {
            this.searchValue = value;
            this.debounceSearch(value);
          })
      }
      .width('100%')
      .padding({ right: 16, top: 8, bottom: 8 })

      // 内容区
      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text('搜索中...')
            .fontSize(14)
            .fontColor('#999')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasSearched && this.results.length === 0) {
        // 空态
        Column() {
          Text('🔍')
            .fontSize(60)
            .margin({ bottom: 16 })
          Text('未找到匹配的单词')
            .fontSize(16)
            .fontColor('#999')
          Text('试试其他关键词吧')
            .fontSize(14)
            .fontColor('#CCC')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.results.length > 0) {
        List() {
          ForEach(this.results, (item: SearchWordItem) => {
            ListItem() {
              this.ResultRow(item)
            }
            .onClick(() => {
              this.selectedItem = item;
              this.showPanel = true;
            })
          }, (item: SearchWordItem) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12, top: 4 })
        .divider({
          strokeWidth: 0.5,
          color: '#F0F0F0',
          startMargin: 16,
          endMargin: 16
        })
      } else {
        // 初始状态
        Column() {
          Text('🔎')
            .fontSize(60)
            .margin({ bottom: 16 })
          Text('输入单词或中文释义进行搜索')
            .fontSize(15)
            .fontColor('#999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }

      // 底部 Panel
      if (this.showPanel && this.selectedItem !== null) {
        this.DetailPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  ResultRow(item: SearchWordItem) {
    Row() {
      Column() {
        Row() {
          Text(item.word)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')

          if (item.phonetic) {
            Text(item.phonetic)
              .fontSize(13)
              .fontColor('#999')
              .margin({ left: 8 })
          }
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

      // 掌握等级标签
      Text(this.getMasteryLabel(item.mastery_level))
        .fontSize(11)
        .fontColor(Color.White)
        .backgroundColor(this.getMasteryColor(item.mastery_level))
        .borderRadius(8)
        .padding({
          left: 8,
          right: 8,
          top: 3,
          bottom: 3
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 6 })
  }

  @Builder
  DetailPanel() {
    Column() {
      // 遮罩层
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#00000000')
        .onClick(() => {
          this.showPanel = false;
          this.selectedItem = null;
        })

      // 面板内容
      Column() {
        // 拖拽指示条
        Row()
          .width(40)
          .height(4)
          .backgroundColor('#DDD')
          .borderRadius(2)
          .margin({ top: 12, bottom: 16 })

        // 单词 + 发音
        Row() {
          Text(this.selectedItem!.word)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')

          Text(this.playingAudio ? '🔊' : '🔈')
            .fontSize(24)
            .fontColor(this.playingAudio ? '#4A90D9' : '#999')
            .margin({ left: 12 })
            .onClick(() => {
              this.handlePlayAudio();
            })
        }
        .justifyContent(FlexAlign.Center)

        // 音标
        if (this.selectedItem!.phonetic) {
          Text(this.selectedItem!.phonetic)
            .fontSize(16)
            .fontColor('#999')
            .margin({ top: 4 })
        }

        // 释义
        Text(this.selectedItem!.meaning)
          .fontSize(18)
          .fontColor('#4A90D9')
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16 })
          .textAlign(TextAlign.Center)

        // 例句
        if (this.selectedItem!.example) {
          Text(this.selectedItem!.example)
            .fontSize(14)
            .fontColor('#666')
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
            .padding({ left: 16, right: 16 })
        }

        // 掌握等级 + 难度
        Row() {
          Text(`掌握: ${this.getMasteryLabel(this.selectedItem!.mastery_level)}`)
            .fontSize(13)
            .fontColor('#666')

          Text(`难度: ${'★'.repeat(this.selectedItem!.difficulty)}${'☆'.repeat(5 - this.selectedItem!.difficulty)}`)
            .fontSize(13)
            .fontColor('#F39C12')
            .margin({ left: 20 })
        }
        .margin({ top: 16 })

        // 收藏按钮
        Button(this.selectedItem!.is_favorite ? '已收藏 ❤️' : '加入收藏 🤍')
          .width('80%')
          .height(44)
          .backgroundColor(this.selectedItem!.is_favorite ? '#F0F0F0' : '#4A90D9')
          .fontColor(this.selectedItem!.is_favorite ? '#999' : Color.White)
          .fontSize(16)
          .borderRadius(12)
          .margin({ top: 24, bottom: 30 })
          .onClick(() => {
            this.toggleFavorite();
          })
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 20, topRight: 20 })
      .shadow({ radius: 16, color: '#33000000', offsetY: -4 })
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  getMasteryLabel(level: number | null): string {
    if (level === null || level === undefined) {
      return 'NEW';
    }
    if (level >= 7) {
      return '✓已掌握';
    }
    return `Lv.${level}`;
  }

  getMasteryColor(level: number | null): string {
    if (level === null || level === undefined) {
      return '#E67E22';
    }
    if (level >= 7) {
      return '#27AE60';
    }
    return '#4A90D9';
  }

  debounceSearch(query: string): void {
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
    }
    this.debounceTimer = setTimeout(() => {
      this.doSearch(query);
      this.debounceTimer = -1;
    }, 300) as number;
  }

  async doSearch(query: string): Promise<void> {
    const q = query.trim();
    if (!q) {
      this.results = [];
      this.hasSearched = false;
      return;
    }
    this.loading = true;
    try {
      const res = await HttpUtil.get(`/api/words/search?q=${encodeURIComponent(q)}&limit=20`);
      this.results = JSON.parse(JSON.stringify(res)) as SearchWordItem[];
      this.hasSearched = true;
    } catch (err) {
      console.error('search error', JSON.stringify(err));
      this.results = [];
      this.hasSearched = true;
    } finally {
      this.loading = false;
    }
  }

  async handlePlayAudio(): Promise<void> {
    if (this.playingAudio || this.selectedItem === null) {
      return;
    }
    this.playingAudio = true;
    try {
      await AudioUtil.playWord(this.selectedItem!.word);
    } catch (err) {
      console.error('playAudio error', JSON.stringify(err));
    } finally {
      this.playingAudio = false;
    }
  }

  async toggleFavorite(): Promise<void> {
    if (this.selectedItem === null) {
      return;
    }
    const wordId = this.selectedItem!.id;
    try {
      if (this.selectedItem!.is_favorite) {
        await HttpUtil.delete(`/api/favorites/${wordId}?type=0`);
        this.selectedItem!.is_favorite = 0;
        // 同步更新列表
        this.updateResultFavorite(wordId, 0);
        promptAction.showToast({ message: '已取消收藏', duration: 1000 });
      } else {
        const data: FavoriteData = { word_id: wordId, type: 0 };
        await HttpUtil.post('/api/favorites', data);
        this.selectedItem!.is_favorite = 1;
        this.updateResultFavorite(wordId, 1);
        promptAction.showToast({ message: '已收藏', duration: 1000 });
      }
      // 触发 UI 刷新
      this.selectedItem = {
        id: this.selectedItem!.id,
        word: this.selectedItem!.word,
        phonetic: this.selectedItem!.phonetic,
        meaning: this.selectedItem!.meaning,
        example: this.selectedItem!.example,
        difficulty: this.selectedItem!.difficulty,
        mastery_level: this.selectedItem!.mastery_level,
        is_favorite: this.selectedItem!.is_favorite
      } as SearchWordItem;
    } catch (err) {
      console.error('toggleFavorite error', JSON.stringify(err));
    }
  }

  updateResultFavorite(wordId: number, isFav: number): void {
    const newResults: SearchWordItem[] = [];
    for (const item of this.results) {
      if (item.id === wordId) {
        const updated: SearchWordItem = {
          id: item.id,
          word: item.word,
          phonetic: item.phonetic,
          meaning: item.meaning,
          example: item.example,
          difficulty: item.difficulty,
          mastery_level: item.mastery_level,
          is_favorite: isFav
        };
        newResults.push(updated);
      } else {
        newResults.push(item);
      }
    }
    this.results = newResults;
  }
}
