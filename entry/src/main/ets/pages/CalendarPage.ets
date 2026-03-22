import { router } from '@kit.ArkUI';
import { HttpUtil } from '../utils/HttpUtil';

interface CalendarDay {
  date: string;
  count: number;
}

interface CalendarSummary {
  total_checkin_days: number;
  max_streak: number;
  month_checkin_days: number;
  current_month: string;
}

interface DayDetail {
  date: string;
  word_count: number;
  correct_count: number;
  forgotten_count: number;
  accuracy_percent: number;
}

@Entry
@Component
struct CalendarPage {
  @State calendarDays: CalendarDay[] = [];
  @State summary: CalendarSummary = {
    total_checkin_days: 0,
    max_streak: 0,
    month_checkin_days: 0,
    current_month: ''
  };
  @State loading: boolean = true;
  @State selectedDay: DayDetail | null = null;
  @State showPanel: boolean = false;
  @State panelLoading: boolean = false;

  // 热力图显示的数据（对齐到周一开始，共 12 周 = 84 格 + 前置空格）
  @State gridData: CalendarDay[] = [];
  @State leadingBlanks: number = 0;

  private weekLabels: string[] = ['一', '二', '三', '四', '五', '六', '日'];

  aboutToAppear(): void {
    this.loadCalendar();
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#333')
          .onClick(() => {
            router.back();
          })
          .padding(12)

        Text('学习日历')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('')
          .padding(12)
          .width(48)
      }
      .width('100%')
      .padding({ left: 4, right: 4, top: 8 })

      if (this.loading) {
        Column() {
          LoadingProgress().width(50).height(50)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 统计概览卡片
            Row() {
              this.SummaryBlock(`${this.summary.total_checkin_days}`, '总打卡')
              this.SummaryBlock(`${this.summary.max_streak}`, '最长连续')
              this.SummaryBlock(`${this.summary.month_checkin_days}`, '本月打卡')
            }
            .width('90%')
            .justifyContent(FlexAlign.SpaceAround)
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
            .margin({ top: 12, bottom: 20 })

            // 热力图标题
            Text('过去 12 周学习热力图')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
              .width('90%')
              .margin({ bottom: 12 })

            // 颜色图例
            Row() {
              Text('少')
                .fontSize(11)
                .fontColor('#999')
                .margin({ right: 6 })
              this.LegendBox('#EBEDF0')
              this.LegendBox('#9BE9A8')
              this.LegendBox('#40C463')
              this.LegendBox('#216E39')
              Text('多')
                .fontSize(11)
                .fontColor('#999')
                .margin({ left: 6 })
            }
            .width('90%')
            .justifyContent(FlexAlign.End)
            .margin({ bottom: 12 })

            // 星期标签 + 热力图网格
            Row() {
              // 星期标签列
              Column() {
                ForEach(this.weekLabels, (label: string) => {
                  Text(label)
                    .fontSize(10)
                    .fontColor('#999')
                    .height(16)
                    .textAlign(TextAlign.Center)
                    .margin({ bottom: 2 })
                }, (label: string, index: number) => `week_${index}`)
              }
              .margin({ right: 6 })

              // 热力图主体
              Scroll() {
                Column() {
                  this.HeatmapGrid()
                }
              }
              .scrollable(ScrollDirection.Horizontal)
              .layoutWeight(1)
            }
            .width('90%')
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
            .margin({ bottom: 20 })

            // 日期详情面板
            if (this.showPanel && this.selectedDay !== null) {
              Column() {
                Text(`📅 ${this.selectedDay!.date}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333')
                  .margin({ bottom: 12 })

                if (this.panelLoading) {
                  LoadingProgress().width(30).height(30)
                } else if (this.selectedDay!.word_count === 0) {
                  Text('当天没有学习记录')
                    .fontSize(14)
                    .fontColor('#999')
                } else {
                  Row() {
                    this.DetailBlock(`${this.selectedDay!.word_count}`, '学习词数', '#4A90D9')
                    this.DetailBlock(`${this.selectedDay!.correct_count}`, '记住', '#27AE60')
                    this.DetailBlock(`${this.selectedDay!.forgotten_count}`, '忘记', '#E74C3C')
                    this.DetailBlock(`${this.selectedDay!.accuracy_percent}%`, '正确率', '#F39C12')
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceAround)
                }
              }
              .width('90%')
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
              .margin({ bottom: 20 })
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
  HeatmapGrid() {
    // 将数据按列排列（每列=一周，7行）
    // 先计算总列数
    Row() {
      ForEach(this.getWeekColumns(), (week: CalendarDay[]) => {
        Column() {
          ForEach(week, (day: CalendarDay) => {
            if (day.date === '') {
              // 空白占位
              Text('')
                .width(14)
                .height(14)
                .margin({ bottom: 2 })
            } else {
              Text('')
                .width(14)
                .height(14)
                .backgroundColor(this.getHeatColor(day.count))
                .borderRadius(3)
                .margin({ bottom: 2 })
                .onClick(() => {
                  this.loadDayDetail(day.date);
                })
            }
          }, (day: CalendarDay, index: number) => `${day.date}_${index}`)
        }
        .margin({ right: 2 })
      }, (week: CalendarDay[], index: number) => `week_col_${index}`)
    }
  }

  getWeekColumns(): CalendarDay[][] {
    // 将 gridData 分成每 7 个一组（每组=一周，竖向排列）
    // 先在前面补空白，使第一天对齐到正确的星期几
    const allDays: CalendarDay[] = [];

    // 补前置空白
    for (let i = 0; i < this.leadingBlanks; i++) {
      allDays.push({ date: '', count: 0 });
    }
    for (const d of this.gridData) {
      allDays.push(d);
    }

    // 按 7 个一组分列
    const weeks: CalendarDay[][] = [];
    for (let i = 0; i < allDays.length; i += 7) {
      const week = allDays.slice(i, i + 7);
      // 补齐最后一周
      while (week.length < 7) {
        week.push({ date: '', count: 0 });
      }
      weeks.push(week);
    }
    return weeks;
  }

  @Builder
  SummaryBlock(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4A90D9')
      Text(label)
        .fontSize(12)
        .fontColor('#999')
        .margin({ top: 4 })
    }
  }

  @Builder
  DetailBlock(value: string, label: string, color: string) {
    Column() {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(11)
        .fontColor('#999')
        .margin({ top: 2 })
    }
  }

  @Builder
  LegendBox(color: string) {
    Text('')
      .width(12)
      .height(12)
      .backgroundColor(color)
      .borderRadius(2)
      .margin({ left: 3, right: 3 })
  }

  getHeatColor(count: number): string {
    if (count === 0) {
      return '#EBEDF0';
    }
    if (count <= 5) {
      return '#9BE9A8';
    }
    if (count <= 15) {
      return '#40C463';
    }
    return '#216E39';
  }

  async loadCalendar(): Promise<void> {
    this.loading = true;
    try {
      const res = await HttpUtil.get('/api/stats/calendar?days=84');
      const days = JSON.parse(JSON.stringify(res['days'])) as CalendarDay[];
      const summaryObj = res['summary'] as Record<string, Object>;
      this.summary = {
        total_checkin_days: summaryObj['total_checkin_days'] as number,
        max_streak: summaryObj['max_streak'] as number,
        month_checkin_days: summaryObj['month_checkin_days'] as number,
        current_month: summaryObj['current_month'] as string
      };

      // 计算第一天是星期几（0=周日，需转为 0=周一）
      if (days.length > 0) {
        const firstDate = new Date(days[0].date);
        let dayOfWeek = firstDate.getDay(); // 0=Sun, 1=Mon...
        // 转为周一=0, 周日=6
        this.leadingBlanks = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
      }

      this.gridData = days;
      this.calendarDays = days;
    } catch (err) {
      console.error('loadCalendar error', JSON.stringify(err));
    } finally {
      this.loading = false;
    }
  }

  async loadDayDetail(date: string): Promise<void> {
    this.showPanel = true;
    this.panelLoading = true;
    this.selectedDay = { date: date, word_count: 0, correct_count: 0, forgotten_count: 0, accuracy_percent: 0 };

    try {
      const res = await HttpUtil.get(`/api/stats/day/${date}`);
      this.selectedDay = {
        date: res['date'] as string,
        word_count: res['word_count'] as number,
        correct_count: res['correct_count'] as number,
        forgotten_count: res['forgotten_count'] as number,
        accuracy_percent: res['accuracy_percent'] as number
      };
    } catch (err) {
      console.error('loadDayDetail error', JSON.stringify(err));
    } finally {
      this.panelLoading = false;
    }
  }
}
