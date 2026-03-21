import { router } from '@kit.ArkUI';
import { StorageUtil } from '../utils/StorageUtil';

@Component
export struct MinePage {
  @State username: string = '';

  aboutToAppear(): void {
    this.loadUserInfo();
  }

  build() {
    Column() {
      Text('我的')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 16 })

      // 头像区域
      Column() {
        Text(this.username ? this.username.charAt(0).toUpperCase() : '?')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(80)
          .height(80)
          .backgroundColor('#4A90D9')
          .borderRadius(40)
          .textAlign(TextAlign.Center)

        Text(this.username)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ top: 12 })
      }
      .width('100%')
      .padding(30)
      .alignItems(HorizontalAlign.Center)

      // 菜单列表
      Column() {
        this.MenuItemClickable('词书选择', '切换词库', () => {
          router.pushUrl({ url: 'pages/BookSelectPage' });
        })
        this.MenuItem('每日目标', '20个单词')
        this.MenuItem('学习提醒', '每天 08:00')
        this.MenuItem('关于应用', 'v1.0.0')
      }
      .width('90%')
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
      .padding({ top: 4, bottom: 4 })

      Blank()

      // 退出登录
      Button('退出登录')
        .width('90%')
        .height(46)
        .backgroundColor(Color.White)
        .fontColor('#E74C3C')
        .fontSize(16)
        .borderRadius(12)
        .borderWidth(1)
        .borderColor('#E74C3C')
        .margin({ bottom: 40 })
        .onClick(async () => {
          await StorageUtil.clear();
          router.replaceUrl({ url: 'pages/LoginPage' });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  MenuItem(title: string, detail: string) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#333')
      Blank()
      Text(detail)
        .fontSize(14)
        .fontColor('#999')
      Text(' >')
        .fontSize(14)
        .fontColor('#CCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  MenuItemClickable(title: string, detail: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#333')
      Blank()
      Text(detail)
        .fontSize(14)
        .fontColor('#999')
      Text(' >')
        .fontSize(14)
        .fontColor('#CCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(onClick)
  }

  async loadUserInfo(): Promise<void> {
    this.username = await StorageUtil.getUsername();
  }
}
