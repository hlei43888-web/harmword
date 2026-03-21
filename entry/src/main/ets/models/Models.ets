// 单词模型
export interface WordItem {
  id: number;
  word: string;
  phonetic: string;
  meaning: string;
  example: string;
  difficulty: number;
  mastery_level: number;
  review_count: number;
  next_review_at: string | null;
}

// 今日任务响应
export interface TodayResponse {
  date: string;
  daily_goal: number;
  review_words: WordItem[];
  new_words: WordItem[];
  total: number;
}

// 统计概览
export interface StatsOverview {
  total_words: number;
  learned_words: number;
  mastered_words: number;
  today_studied: number;
  streak_days: number;
  accuracy_percent: number;
}

// 登录/注册响应
export interface AuthResponse {
  message: string;
  token: string;
  user: UserInfo;
}

export interface UserInfo {
  id: number;
  username: string;
}
