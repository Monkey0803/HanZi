/*
 * NotificationService.ets — HDS 即时通知（HdsSnackBar）封装。
 *
 * HdsSnackBar 是类而非组件：构造需要 UIContext，show(icon, message, operation, style?) 弹出。
 * 这里按 UIContext 缓存实例；通知只是「说一句」，失败不影响主流程（不抛给调用方）。
 */

import { UIContext } from '@kit.ArkUI';
import { HdsSnackBar, SnackBarOperationOptions, SnackBarOperationType } from '@kit.UIDesignKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class NotificationService {
  private snackBar: HdsSnackBar | undefined = undefined;
  private boundContext: UIContext | undefined = undefined;

  private ensure(uiContext: UIContext): HdsSnackBar {
    if (this.snackBar === undefined || this.boundContext !== uiContext) {
      this.snackBar = new HdsSnackBar(uiContext);
      this.boundContext = uiContext;
    }
    return this.snackBar;
  }

  /** 弹一条即时通知（默认 3 秒后自动消失，带关闭按钮）。 */
  show(uiContext: UIContext, message: ResourceStr): void {
    try {
      this.ensure(uiContext).show(
        { icon: $r('sys.symbol.checkmark_circle') },
        { content: message },
        { operationType: SnackBarOperationType.CLOSE_BUTTON_ONLY },
        { duration: 3000 }
      );
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('HdsSnackBar.show failed: ' + error.code.toString());
    }
  }

  /** 弹一条带文字操作按钮的即时通知（点按钮回调 onAction）。 */
  showWithAction(uiContext: UIContext, message: ResourceStr, actionText: ResourceStr,
    onAction: () => void): void {
    try {
      const operation: SnackBarOperationOptions = {
        operationType: SnackBarOperationType.TEXT_WITH_CLOSE,
        content: actionText,
        onContentClick: onAction
      };
      this.ensure(uiContext).show(
        { icon: $r('sys.symbol.checkmark_circle') },
        { content: message },
        operation,
        { duration: 4000 }
      );
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('HdsSnackBar.showWithAction failed: ' + error.code.toString());
    }
  }
}

/** 全局唯一实例。 */
export const notificationService: NotificationService = new NotificationService();
