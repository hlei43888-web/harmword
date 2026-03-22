import { router } from '@kit.ArkUI';
import { StorageUtil } from '../utils/StorageUtil';
import { HomePage } from './HomePage';
import { StatsPage } from './StatsPage';
import { FavoritesPage } from './FavoritesPage';
import { MinePage } from './MinePage';

@Entry
@Component
@Preview
struct Index {
  @State currentTab: number = 0;
  @State isReady: boolean = false;

  async aboutToAppear(): Promise<void> {
    await StorageUtil.init(getContext(this));

    const loggedIn = await StorageUtil.isLoggedIn();
    if (!loggedIn) {
      router.replaceUrl({ url: 'pages/LoginPage' });
      return;
    }
    this.isReady = true;
  }

  build() {
    if (this.isReady) {
      Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
        TabContent() {
          HomePage()
        }
        .tabBar(this.TabBarItem(0, '首页', '🏠'))

        TabContent() {
          FavoritesPage()
        }
        .tabBar(this.TabBarItem(1, '错词本', '📝'))

        TabContent() {
          StatsPage()
        }
        .tabBar(this.TabBarItem(2, '统计', '📊'))

        TabContent() {
          MinePage()
        }
        .tabBar(this.TabBarItem(3, '我的', '👤'))
      }
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.currentTab = index;
      })
    } else {
      Column() {
        LoadingProgress()
          .width(50)
          .height(50)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
  }

  @Builder
  TabBarItem(index: number, label: string, icon: string) {
    Column() {
      Text(icon)
        .fontSize(22)
      Text(label)
        .fontSize(11)
        .fontColor(this.currentTab === index ? '#4A90D9' : '#999')
        .margin({ top: 2 })
    }
    .width('100%')
    .padding({ top: 6, bottom: 4 })
    .justifyContent(FlexAlign.Center)
  }
}
