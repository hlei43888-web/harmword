import { router } from '@kit.ArkUI';
import { HttpUtil } from '../utils/HttpUtil';
import { StorageUtil } from '../utils/StorageUtil';
import { AuthResponse } from '../models/Models';

interface AuthRequestData {
  username: string;
  password: string;
}

@Entry
@Component
struct LoginPage {
  @State isLogin: boolean = true; // true=登录, false=注册
  @State username: string = '';
  @State password: string = '';
  @State loading: boolean = false;
  @State errorMsg: string = '';

  build() {
    Column() {
      // 顶部 Logo 区域
      Column() {
        Text('📖')
          .fontSize(60)
        Text('HarmWord')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ top: 8 })
        Text('艾宾浩斯记忆法背单词')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 4 })
      }
      .margin({ top: 80, bottom: 50 })

      // 切换标签
      Row() {
        Text('登录')
          .fontSize(18)
          .fontWeight(this.isLogin ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.isLogin ? '#4A90D9' : '#999')
          .onClick(() => {
            this.isLogin = true;
            this.errorMsg = '';
          })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('注册')
          .fontSize(18)
          .fontWeight(!this.isLogin ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(!this.isLogin ? '#4A90D9' : '#999')
          .onClick(() => {
            this.isLogin = false;
            this.errorMsg = '';
          })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('80%')
      .margin({ bottom: 30 })

      // 输入框
      TextInput({ placeholder: '请输入用户名', text: this.username })
        .width('80%')
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .padding({ left: 16, right: 16 })
        .margin({ bottom: 16 })
        .onChange((value: string) => {
          this.username = value;
        })

      TextInput({ placeholder: '请输入密码', text: this.password })
        .width('80%')
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .padding({ left: 16, right: 16 })
        .type(InputType.Password)
        .margin({ bottom: 8 })
        .onChange((value: string) => {
          this.password = value;
        })

      // 错误提示
      if (this.errorMsg) {
        Text(this.errorMsg)
          .fontSize(13)
          .fontColor('#E74C3C')
          .margin({ top: 4, bottom: 8 })
      }

      // 提交按钮
      Button(this.loading ? '处理中...' : (this.isLogin ? '登 录' : '注 册'))
        .width('80%')
        .height(48)
        .backgroundColor('#4A90D9')
        .fontColor(Color.White)
        .fontSize(17)
        .borderRadius(12)
        .margin({ top: 20 })
        .enabled(!this.loading)
        .onClick(() => {
          this.handleSubmit();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  async handleSubmit(): Promise<void> {
    if (!this.username.trim() || !this.password.trim()) {
      this.errorMsg = '用户名和密码不能为空';
      return;
    }
    if (!this.isLogin && this.password.length < 6) {
      this.errorMsg = '密码长度不能少于6位';
      return;
    }

    this.loading = true;
    this.errorMsg = '';

    try {
      const url = this.isLogin ? '/api/auth/login' : '/api/auth/register';
      const data: AuthRequestData = {
        username: this.username,
        password: this.password
      };
      const res = await HttpUtil.post(url, data) as Record<string, Object>;
      const token = res['token'] as string;
      const user = res['user'] as Record<string, Object>;

      await StorageUtil.setToken(token);
      await StorageUtil.setUserId(user['id'] as number);
      await StorageUtil.setUsername(user['username'] as string);

      router.replaceUrl({ url: 'pages/Index' });
    } catch (err) {
      this.errorMsg = (err as Error).message || '操作失败，请重试';
    } finally {
      this.loading = false;
    }
  }
}
