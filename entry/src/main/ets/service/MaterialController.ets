/*
 * MaterialController.ets — 沉浸光感材质（hdsMaterial + uiMaterial）。
 *
 * 两个层次：
 * 1) HDS 材质（hdsMaterial，6.1.0(23)+，手机 / 平板）：只表达"材质类型 + 四档厚薄"，
 *    交给 HdsNavigation / HdsTabs 的 systemMaterialEffect，形状是 SystemMaterialParams。
 *    调 getSystemMaterialTypes() 前必须 try/catch —— 不支持时它会抛 801，而不是返回空数组。
 * 2) 组件级沉浸系统材质（uiMaterial，26.0.0+）：形状是 ImmersiveMaterial 对象，挂到通用属性
 *    `.systemMaterial(...)`（或菜单 / 弹窗 options 的 systemMaterial 字段）。本文件的
 *    glassMaterial() / overlayMaterial() / menuOptionsFor() 是**唯一**构造它的地方：
 *    默认**不设置 materialColor**（无底色 = 最通透），需要品牌色调时再显式传半透明字面量。
 *    注意 materialColor 是**加法**（叠一层纯色），不是"关闭自适应"的开关。
 *
 * 生效区域（华为文档 §8.1 / §10，强制）：普通组件只在 Navigation/NavDestination 标题栏、或
 * barPosition=End 的底部 TabBar 内生效；弹窗类组件 / 接口、菜单、Slider、Toggle、Select 全页面生效；
 * 其余区域（包括页面内容区）设置后**没有任何视觉效果**，且不会报错。
 *
 * 应用级开关：entry 模块 module.json5 的 metadata `ohos.arkui.UIMaterial.state`
 * （default / enable / disable）。ENABLE 会让系统清单内的组件默认获得材质（Dialog / Toast / 菜单 /
 * Toggle / Slider / Select / Chip / SegmentButton / Navigation 等自动接管样式；Popup / Tips / Button
 * 不在清单内，必须组件级显式设置），DISABLE 则让所有组件级材质设置彻底失效。组件级优先级高于应用级，
 * 但"关闭"必须用 uiMaterial.Material.empty，传 undefined 只是"恢复默认"，在 ENABLE 下反而会把默认
 * 材质放回来。
 *
 * 材质等级：uiMaterial 的 MaterialLevel 只有 EXQUISITE(0)/GENTLE(1)/SMOOTH(2) 三档，由设备算力
 * 决定、**只能查不能设**；hdsMaterial 另有 ADAPTIVE(10) 档，可设但低算力设备上设高等级会卡顿发热，
 * 所以这里对 hdsMaterial 的等级做了收敛（见 params()）。
 */

import { hdsMaterial, SystemMaterialParams } from '@kit.UIDesignKit';
import { promptAction, uiMaterial } from '@kit.ArkUI';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { MaterialKind, MaterialGrade } from '../common/constants/SettingsConstants';
import { CustomLevel, CustomPlan } from '../common/material/CustomImmersivePolicy';

export class MaterialController {
  private static cachedTypes: hdsMaterial.MaterialType[] | undefined = undefined;
  private static cachedGlassSupported: boolean | undefined = undefined;
  private static cachedGlassMaterial: uiMaterial.Material | undefined = undefined;
  private static cachedState: uiMaterial.MaterialState | undefined = undefined;
  private static cachedLevel: uiMaterial.MaterialLevel | undefined = undefined;

  /** 设备支持的 HDS 材质类型；不支持时返回空数组（并缓存，避免反复探测）。 */
  static supportedTypes(): hdsMaterial.MaterialType[] {
    const cached: hdsMaterial.MaterialType[] | undefined = MaterialController.cachedTypes;
    if (cached !== undefined) {
      return cached;
    }
    let types: hdsMaterial.MaterialType[] = [];
    try {
      types = hdsMaterial.getSystemMaterialTypes();
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('hdsMaterial.getSystemMaterialTypes failed: ' + error.code.toString());
      types = [];
    }
    MaterialController.cachedTypes = types;
    return types;
  }

  /** 设备是否支持 HDS 沉浸式材质（标题栏 / 页签的 systemMaterialEffect）。 */
  static immersiveSupported(): boolean {
    return MaterialController.supportedTypes().indexOf(hdsMaterial.MaterialType.IMMERSIVE) >= 0;
  }

  /**
   * 应用级（全局）沉浸光感状态：module.json5 metadata `ohos.arkui.UIMaterial.state` 的运行时读法。
   *
   * 三态语义（不是布尔）：
   * - DEFAULT(0)：未配置，或显式配置 default —— 只有 Dialog / Toast / AlphabetIndexer / Text 文本菜单
   *   在组件自身没设背景、模糊、阴影时默认开启；
   * - ENABLE(1)：系统清单内的组件默认开启（Dialog / Toast / 菜单 / Chip / Select / Toggle / Slider /
   *   SegmentButton / Navigation / NavDestination …；页签栏在悬浮样式生效时才算），且材质优先级高于
   *   组件自身的背景色 / 模糊 / 阴影 / 边框 —— 不需要再逐个挂材质，只想关掉其中某个时才用
   *   Material.empty。**Popup / Tips / Button 不在清单内**，ENABLE 下仍需组件级显式设置；
   * - DISABLE(2)：所有组件级材质设置一律不生效。
   *
   * 该接口 26.0.0 起才有，且只在 **entry** 模块的配置会被读取；低版本 / 异常一律兜底成 DEFAULT。
   */
  static materialState(): uiMaterial.MaterialState {
    const cached: uiMaterial.MaterialState | undefined = MaterialController.cachedState;
    if (cached !== undefined) {
      return cached;
    }
    let state: uiMaterial.MaterialState = uiMaterial.MaterialState.DEFAULT;
    try {
      const info: uiMaterial.MaterialInfo = uiMaterial.getMaterialInfo();
      state = info.state;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('uiMaterial.getMaterialInfo failed: ' + error.code.toString());
      state = uiMaterial.MaterialState.DEFAULT;
    }
    MaterialController.cachedState = state;
    return state;
  }

  /** 应用级是否没被显式禁用（DEFAULT / ENABLE 都算"可开"）。 */
  static appMaterialOn(): boolean {
    return MaterialController.materialState() !== uiMaterial.MaterialState.DISABLE;
  }

  /** HDS 轨道（HdsTabs / HdsNavigation）当前是否真的会渲染材质。 */
  static immersiveActive(immersiveOn: boolean): boolean {
    return immersiveOn && MaterialController.immersiveSupported() && MaterialController.appMaterialOn();
  }

  /**
   * 全局材质等级 = 设备算力档（高 / 中 / 低）。
   *
   * 强制规则（华为文档 §5.2）：只有 `isImmersiveMaterialSupported()` 为 true 才有必要查询；
   * 该值由设备定义、应用运行后不变，**没有任何设置入口**（不存在 setMaterialLevel 之类 API），
   * 所以只缓存查询结果，不做任何"写入"。
   *
   * 查不到时（低版本 / 异常）按最低算力 SMOOTH 处理：宁可让 hdsMaterial 退回 ADAPTIVE，
   * 也不在高等级上冒险。
   */
  static globalLevel(): uiMaterial.MaterialLevel {
    const cached: uiMaterial.MaterialLevel | undefined = MaterialController.cachedLevel;
    if (cached !== undefined) {
      return cached;
    }
    let level: uiMaterial.MaterialLevel = uiMaterial.MaterialLevel.SMOOTH;
    if (MaterialController.glassSupported()) {
      try {
        level = uiMaterial.getGlobalMaterialLevel();
      } catch (err) {
        const error: BusinessError = err as BusinessError;
        console.error('uiMaterial.getGlobalMaterialLevel failed: ' + error.code.toString());
        level = uiMaterial.MaterialLevel.SMOOTH;
      }
    }
    MaterialController.cachedLevel = level;
    return level;
  }

  /** 设备是否低算力（材质只有简化的背景色 / 边框 / 阴影实现）。 */
  static lowCompute(): boolean {
    return MaterialController.globalLevel() === uiMaterial.MaterialLevel.SMOOTH;
  }

  /** 设备算力档的语义 id（供纯策略函数消费，避免把 Kit 枚举带进 common）。 */
  static globalLevelId(): string {
    const level: uiMaterial.MaterialLevel = MaterialController.globalLevel();
    if (level === uiMaterial.MaterialLevel.EXQUISITE) {
      return 'EXQUISITE';
    }
    if (level === uiMaterial.MaterialLevel.GENTLE) {
      return 'GENTLE';
    }
    return 'SMOOTH';
  }

  /** getSystemMaterialTypes() 的枚举数组转 string[]；探测异常已在 supportedTypes() 收敛。 */
  static materialTypeNames(): string[] {
    const types: hdsMaterial.MaterialType[] = MaterialController.supportedTypes();
    const names: string[] = [];
    for (let i = 0; i < types.length; i += 1) {
      const type: hdsMaterial.MaterialType = types[i];
      if (type === hdsMaterial.MaterialType.IMMERSIVE) {
        names.push('IMMERSIVE');
      } else if (type === hdsMaterial.MaterialType.NONE) {
        names.push('NONE');
      } else {
        names.push('ADAPTIVE');
      }
    }
    return names;
  }

  /** 组件级材质此刻是否**有意义**：设备支持，且应用级没被 DISABLE 掉。 */
  static materialUsable(): boolean {
    return MaterialController.glassSupported() && MaterialController.appMaterialOn();
  }

  /**
   * 组件级沉浸系统材质（uiMaterial）是否可用：26.0.0+ 且设备支持。
   *
   * 文档要求挂载 systemMaterial 之前必须调用 isImmersiveMaterialSupported()；该接口本身就是
   * 26.0.0 起才有，低版本直接调用会抛异常，所以先用 apiAvailable('26.0.0') 挡一层，
   * 外层再 try/catch 兜底。结果与构造出的材质一起缓存，避免每次 build 都探测 / 重建。
   */
  static glassSupported(): boolean {
    const cached: boolean | undefined = MaterialController.cachedGlassSupported;
    if (cached !== undefined) {
      return cached;
    }
    let supported: boolean = false;
    try {
      supported = deviceInfo.apiAvailable('26.0.0') && uiMaterial.isImmersiveMaterialSupported();
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('uiMaterial.isImmersiveMaterialSupported failed: ' + error.code.toString());
      supported = false;
    }
    MaterialController.cachedGlassSupported = supported;
    return supported;
  }

  /**
   * 玻璃材质：最通透配方（无底色 + ULTRA_THIN）+ 智能反色 + 材质自带阴影。
   *
   * 为什么这样配：
   * - 不设 materialColor → 不在滤镜上叠任何纯色，壁纸透出最多；
   * - ULTRA_THIN → 滤镜最薄；colorInvert 也只在 ULTRA_THIN / THIN 这类薄材质上生效；
   * - 若产品要品牌色调，再显式传**半透明字面量**（如 '#33FFFFFF'）：materialColor 是加法，
   *   会多一层底色、通透度下降；传 $r('sys.color.*') / $r('app.color.*') 还会让底色随深浅色变化。
   *
   * 其余硬性要求：
   * - 若加了颜色，必须半透明 —— 纯不透明会遮挡滤镜 / 折射 / 高光；
   * - colorInvert: true —— 深色壁纸上前景仍可读（**前景文字必须是 $r('sys.color.*') 这类
   *   特殊系统资源色**，硬编码颜色不会触发反色）；
   * - 不设 materialColor 时不要再给同一组件设 backgroundColor：高 / 中算力下 systemMaterial
   *   生效时 backgroundColor 会被重置为透明，二者会打架。
   *
   * @param enabled 总开关（appSettings.immersiveOn）。关掉时返回 uiMaterial.Material.empty
   *                （**显式关闭**默认材质）；设备不支持 / 应用级 DISABLE 时返回 undefined，
   *                组件退回自身已设置的通用属性样式（文档 §7 的降级方式）。
   */
  static glassMaterial(enabled: boolean): uiMaterial.Material | undefined {
    if (!MaterialController.materialUsable()) {
      // 设备不支持 / 应用级 DISABLE：不挂材质，组件回到自己设置的通用属性样式。
      return undefined;
    }
    if (!enabled) {
      // 用户关掉了沉浸光感：必须用 Material.empty **显式关闭**。
      // 传 undefined 只是"恢复默认"，应用级 ENABLE 下会把默认材质放回来（文档 §11.5 / Q2）。
      return uiMaterial.Material.empty;
    }
    const cached: uiMaterial.Material | undefined = MaterialController.cachedGlassMaterial;
    if (cached !== undefined) {
      return cached;
    }
    try {
      const options: uiMaterial.ImmersiveOptions = {
        style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
        colorInvert: true,
        applyShadow: true
      };
      const material: uiMaterial.Material = new uiMaterial.ImmersiveMaterial(options);
      MaterialController.cachedGlassMaterial = material;
      return material;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('uiMaterial.ImmersiveMaterial (glass) failed: ' + error.code.toString());
      return undefined;
    }
  }

  /** 语义 id -> MaterialType。 */
  static typeOf(id: string): hdsMaterial.MaterialType {
    if (id === MaterialKind.IMMERSIVE) {
      return hdsMaterial.MaterialType.IMMERSIVE;
    }
    if (id === MaterialKind.NONE) {
      return hdsMaterial.MaterialType.NONE;
    }
    return hdsMaterial.MaterialType.ADAPTIVE;
  }

  /** 语义 id -> MaterialLevel（四档）。 */
  static levelOf(id: string): hdsMaterial.MaterialLevel {
    if (id === MaterialGrade.EXQUISITE) {
      return hdsMaterial.MaterialLevel.EXQUISITE;
    }
    if (id === MaterialGrade.GENTLE) {
      return hdsMaterial.MaterialLevel.GENTLE;
    }
    if (id === MaterialGrade.SMOOTH) {
      return hdsMaterial.MaterialLevel.SMOOTH;
    }
    return hdsMaterial.MaterialLevel.ADAPTIVE;
  }

  /** CustomPlan 的档位字符串 -> hdsMaterial.MaterialLevel（大小写与策略层一致）。 */
  static levelOfCustom(id: CustomLevel): hdsMaterial.MaterialLevel {
    if (id === 'EXQUISITE') {
      return hdsMaterial.MaterialLevel.EXQUISITE;
    }
    if (id === 'GENTLE') {
      return hdsMaterial.MaterialLevel.GENTLE;
    }
    if (id === 'SMOOTH') {
      return hdsMaterial.MaterialLevel.SMOOTH;
    }
    return hdsMaterial.MaterialLevel.ADAPTIVE;
  }

  /**
   * 自定义沉浸光感计划 -> HDS 双入口共用的材质参数。
   *
   * - plan.emitEffect=false（L3 / 总开关关闭）：返回 undefined，调用方**整体不下发**
   *   systemMaterialEffect（不能用 undefined 字段冒充关闭）。
   * - 类型：默认 ADAPTIVE（自定义只切等级）；用户在设置页显式选 NONE / IMMERSIVE 时尊重用户选择。
   * - 等级：纯策略已按设备能力 / 算力 / 手表收敛，这里不再二次判断。
   */
  static paramsOfPlan(plan: CustomPlan, userTypeId: string): SystemMaterialParams | undefined {
    if (!plan.emitEffect) {
      return undefined;
    }
    let type: hdsMaterial.MaterialType = hdsMaterial.MaterialType.ADAPTIVE;
    if (userTypeId === MaterialKind.NONE) {
      type = hdsMaterial.MaterialType.NONE;
    } else if (userTypeId === MaterialKind.IMMERSIVE) {
      type = hdsMaterial.MaterialType.IMMERSIVE;
    }
    const params: SystemMaterialParams = {
      materialType: type,
      materialLevel: MaterialController.levelOfCustom(plan.materialLevel)
    };
    return params;
  }

  /**
   * 组件级材质的统一出口：
   *   - 设备 / 应用级已无材质可言 → undefined（不传，组件走自身兜底）；
   *   - 用户关掉开关 → uiMaterial.Material.empty（显式关闭；传 undefined 只会「恢复默认」）；
   *   - 开启 → 交给 build() 构造具体材质。
   */
  private static materialOrOff(immersiveOn: boolean,
    build: () => uiMaterial.Material): uiMaterial.Material | undefined {
    if (!MaterialController.glassSupported() || !MaterialController.appMaterialOn()) {
      return undefined;
    }
    if (!immersiveOn) {
      return uiMaterial.Material.empty;
    }
    try {
      return build();
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('uiMaterial.ImmersiveMaterial failed: ' + error.code.toString());
      return undefined;
    }
  }

  /**
   * 弹层（Menu / Sheet / AlertDialog / Toast）用的组件级沉浸光感材质。
   * 与 glassMaterial() 的区别：THICK + interactive，承载文字更易读。
   * lightEnabled 对应「光感反馈」开关：关掉后只保留静态材质，不再跟随触摸流光。
   */
  static overlayMaterial(immersiveOn: boolean, lightEnabled: boolean = true): uiMaterial.Material | undefined {
    return MaterialController.materialOrOff(immersiveOn, (): uiMaterial.Material => {
      const options: uiMaterial.ImmersiveOptions = {
        style: uiMaterial.ImmersiveStyle.THICK,
        interactive: true
      };
      if (lightEnabled) {
        options.lightEffect = { color: undefined };
      }
      return new uiMaterial.ImmersiveMaterial(options);
    });
  }

  /** 半模态设置系统材质时，背板色必须让位（否则材质被 backgroundColor 覆盖）。 */
  private static readonly SHEET_MATERIAL_BACKDROP: ResourceColor = Color.Transparent;

  private static applySheetMaterial(options: SheetOptions, material: uiMaterial.Material): void {
    options.systemMaterial = material;
    options.backgroundColor = MaterialController.SHEET_MATERIAL_BACKDROP;
  }

  /** 半模态面板（bindSheet）注入沉浸光感；不支持时原样返回。 */
  static sheetOptions(options: SheetOptions, immersiveOn: boolean, lightEnabled: boolean = true): SheetOptions {
    const material: uiMaterial.Material | undefined =
      MaterialController.overlayMaterial(immersiveOn, lightEnabled);
    if (material !== undefined) {
      MaterialController.applySheetMaterial(options, material);
    }
    return options;
  }

  /** 对话框（showAlertDialog）注入沉浸光感；不支持时原样返回。 */
  static dialogParams<T extends AlertDialogParam>(params: T, immersiveOn: boolean,
    lightEnabled: boolean = true): T {
    const material: uiMaterial.Material | undefined =
      MaterialController.overlayMaterial(immersiveOn, lightEnabled);
    if (material !== undefined) {
      params.systemMaterial = material;
    }
    return params;
  }

  /** Toast 注入沉浸光感；不支持时原样返回。 */
  static toastOptions(options: promptAction.ShowToastOptions, immersiveOn: boolean,
    lightEnabled: boolean = true): promptAction.ShowToastOptions {
    const material: uiMaterial.Material | undefined =
      MaterialController.overlayMaterial(immersiveOn, lightEnabled);
    if (material !== undefined) {
      options.systemMaterial = material;
    }
    return options;
  }

  /** 自定义菜单内容（AppMenu + bindMenu）注入沉浸光感。 */
  static menuOptionsFor(options: ContextMenuOptions, immersiveOn: boolean,
    lightEnabled: boolean = true): ContextMenuOptions {
    const material: uiMaterial.Material | undefined =
      MaterialController.overlayMaterial(immersiveOn, lightEnabled);
    if (material !== undefined) {
      options.systemMaterial = material;
    }
    return options;
  }

  /**
   * 组装下发到 HdsTabs / HdsNavigation 的材质参数（HDS 的四档体系）。
   *
   * 两处收敛：
   * 1. 总开关关掉、或应用级配置为 DISABLE 时，材质类型直接给 NONE（DISABLE 下组件级也开不了）；
   * 2. 等级按华为文档 §5.4 的风险提示收敛：低算力设备（SMOOTH）只接受自适应档，
   *    强行 EXQUISITE / GENTLE 会卡顿发热，所以非 ADAPTIVE 的选择会被强制回 ADAPTIVE。
   *
   * 注意 uiMaterial 没有 ADAPTIVE 档（只有 EXQUISITE / GENTLE / SMOOTH，且天然自适应、
   * 不能设置）；ADAPTIVE 是 hdsMaterial 独有档位，两套体系不要混用。
   */
  static params(typeId: string, levelId: string, immersiveOn: boolean): SystemMaterialParams {
    const on: boolean = immersiveOn && MaterialController.appMaterialOn();
    const level: hdsMaterial.MaterialLevel = MaterialController.levelOf(levelId);
    const adaptive: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.ADAPTIVE;
    const result: SystemMaterialParams = {
      materialType: on ? MaterialController.typeOf(typeId) : hdsMaterial.MaterialType.NONE,
      materialLevel: MaterialController.lowCompute() ? adaptive : level
    };
    return result;
  }
}
