import { preferences } from '@kit.ArkData';
import { TOKEN_KEY, USER_ID_KEY, USERNAME_KEY } from './Constants';

const STORE_NAME = 'harmword_prefs';
let prefs: preferences.Preferences | null = null;

export class StorageUtil {
  static async init(context: Context): Promise<void> {
    prefs = await preferences.getPreferences(context, STORE_NAME);
  }

  static async setToken(token: string): Promise<void> {
    if (!prefs) return;
    await prefs.put(TOKEN_KEY, token);
    await prefs.flush();
  }

  static async getToken(): Promise<string> {
    if (!prefs) return '';
    return (await prefs.get(TOKEN_KEY, '')) as string;
  }

  static async setUserId(id: number): Promise<void> {
    if (!prefs) return;
    await prefs.put(USER_ID_KEY, id);
    await prefs.flush();
  }

  static async getUserId(): Promise<number> {
    if (!prefs) return 0;
    return (await prefs.get(USER_ID_KEY, 0)) as number;
  }

  static async setUsername(name: string): Promise<void> {
    if (!prefs) return;
    await prefs.put(USERNAME_KEY, name);
    await prefs.flush();
  }

  static async getUsername(): Promise<string> {
    if (!prefs) return '';
    return (await prefs.get(USERNAME_KEY, '')) as string;
  }

  static async clear(): Promise<void> {
    if (!prefs) return;
    await prefs.clear();
    await prefs.flush();
  }

  static async isLoggedIn(): Promise<boolean> {
    const token = await StorageUtil.getToken();
    return token.length > 0;
  }
}
