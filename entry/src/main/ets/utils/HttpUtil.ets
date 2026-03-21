import { http } from '@kit.NetworkKit';
import { BASE_URL } from './Constants';
import { StorageUtil } from './StorageUtil';

export class HttpUtil {
  static async get(url: string): Promise<Record<string, Object>> {
    return HttpUtil.request(url, http.RequestMethod.GET);
  }

  static async post(url: string, data?: Object): Promise<Record<string, Object>> {
    return HttpUtil.request(url, http.RequestMethod.POST, data as Record<string, Object>);
  }

  static async put(url: string, data?: Record<string, Object>): Promise<Record<string, Object>> {
    return HttpUtil.request(url, http.RequestMethod.PUT, data);
  }

  private static async request(
    url: string,
    method: http.RequestMethod,
    data?: Record<string, Object>
  ): Promise<Record<string, Object>> {
    const httpRequest = http.createHttp();
    const token = await StorageUtil.getToken();

    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    try {
      const response = await httpRequest.request(BASE_URL + url, {
        method: method,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      const result = JSON.parse(response.result as string) as Record<string, Object>;

      if (response.responseCode >= 400) {
        const errMsg = (result['error'] as string) || '请求失败';
        throw new Error(errMsg);
      }

      return result;
    } finally {
      httpRequest.destroy();
    }
  }
}
