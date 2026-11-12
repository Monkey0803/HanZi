import { describe, it, expect } from '@ohos/hypium';
import { hdsMaterial } from '@kit.UIDesignKit';
import { uiMaterial } from '@kit.ArkUI';
import { MaterialController } from '../../../main/ets/service/MaterialController';

// 语义 id -> hdsMaterial 枚举 的纯映射单测（不触发设备能力探测）+ 玻璃开关语义。

export default function materialMapTest() {
  describe('MaterialController', () => {
    it('maps_material_type_ids', 0, () => {
      expect(MaterialController.typeOf('immersive')).assertEqual(hdsMaterial.MaterialType.IMMERSIVE);
      expect(MaterialController.typeOf('none')).assertEqual(hdsMaterial.MaterialType.NONE);
      expect(MaterialController.typeOf('adaptive')).assertEqual(hdsMaterial.MaterialType.ADAPTIVE);
      expect(MaterialController.typeOf('whatever')).assertEqual(hdsMaterial.MaterialType.ADAPTIVE);
    });

    it('maps_material_level_ids', 0, () => {
      expect(MaterialController.levelOf('exquisite')).assertEqual(hdsMaterial.MaterialLevel.EXQUISITE);
      expect(MaterialController.levelOf('gentle')).assertEqual(hdsMaterial.MaterialLevel.GENTLE);
      expect(MaterialController.levelOf('smooth')).assertEqual(hdsMaterial.MaterialLevel.SMOOTH);
      expect(MaterialController.levelOf('adaptive')).assertEqual(hdsMaterial.MaterialLevel.ADAPTIVE);
      expect(MaterialController.levelOf('whatever')).assertEqual(hdsMaterial.MaterialLevel.ADAPTIVE);
    });

    it('material_levels_are_four_distinct_grades', 0, () => {
      // 沉浸光感四档（强/均衡/弱/系统自适应）必须是四个不同的枚举值。
      const exquisite: number = MaterialController.levelOf('exquisite');
      const gentle: number = MaterialController.levelOf('gentle');
      const smooth: number = MaterialController.levelOf('smooth');
      const adaptive: number = MaterialController.levelOf('adaptive');
      const unique: Set<number> = new Set<number>();
      unique.add(exquisite);
      unique.add(gentle);
      unique.add(smooth);
      unique.add(adaptive);
      expect(unique.size).assertEqual(4);
    });

    it('params_uses_none_when_immersive_is_off', 0, () => {
      const off = MaterialController.params('immersive', 'exquisite', false);
      expect(off.materialType).assertEqual(hdsMaterial.MaterialType.NONE);
      expect(off.materialLevel).assertEqual(hdsMaterial.MaterialLevel.EXQUISITE);
    });

    it('params_keeps_the_selected_type_when_immersive_is_on', 0, () => {
      const on = MaterialController.params('immersive', 'smooth', true);
      expect(on.materialType).assertEqual(hdsMaterial.MaterialType.IMMERSIVE);
      expect(on.materialLevel).assertEqual(hdsMaterial.MaterialLevel.SMOOTH);
    });

    it('glass_material_closes_with_empty_when_switched_off', 0, () => {
      // 关掉沉浸光感：能用材质时必须用 Material.empty 显式关闭（undefined 只是"恢复默认"，
      // 应用级 ENABLE 下会把默认材质放回来）；设备不支持 / 应用级 DISABLE 才给 undefined。
      const usable: boolean = MaterialController.materialUsable();
      const off: uiMaterial.Material | undefined = MaterialController.glassMaterial(false);
      expect(off === uiMaterial.Material.empty).assertEqual(usable);
      expect(off === undefined).assertEqual(!usable);
    });

    it('material_state_is_one_of_three_values', 0, () => {
      const state: uiMaterial.MaterialState = MaterialController.materialState();
      const known: boolean = state === uiMaterial.MaterialState.DEFAULT
        || state === uiMaterial.MaterialState.ENABLE
        || state === uiMaterial.MaterialState.DISABLE;
      expect(known).assertTrue();
    });

    it('global_material_level_is_one_of_three_grades', 0, () => {
      // 三档、只读：不存在 ADAPTIVE（那是 hdsMaterial 的档位），也没有 setMaterialLevel。
      const level: uiMaterial.MaterialLevel = MaterialController.globalLevel();
      const known: boolean = level === uiMaterial.MaterialLevel.EXQUISITE
        || level === uiMaterial.MaterialLevel.GENTLE
        || level === uiMaterial.MaterialLevel.SMOOTH;
      expect(known).assertTrue();
      // 三档之外没有第四档：ADAPTIVE 只存在于 hdsMaterial，uiMaterial 天然自适应、不可设置。
      const three: Set<number> = new Set<number>();
      three.add(uiMaterial.MaterialLevel.EXQUISITE);
      three.add(uiMaterial.MaterialLevel.GENTLE);
      three.add(uiMaterial.MaterialLevel.SMOOTH);
      expect(three.size).assertEqual(3);
    });

    it('params_clamps_hds_level_on_low_compute', 0, () => {
      // 文档 §5.4：低算力设备上强行 EXQUISITE / GENTLE 会卡顿发热，必须收敛到 ADAPTIVE。
      const params = MaterialController.params('immersive', 'exquisite', true);
      if (MaterialController.lowCompute()) {
        expect(params.materialLevel).assertEqual(hdsMaterial.MaterialLevel.ADAPTIVE);
      } else {
        expect(params.materialLevel).assertEqual(hdsMaterial.MaterialLevel.EXQUISITE);
      }
    });

    it('overlay_material_off_when_immersive_is_disabled', 0, () => {
      // 总开关关闭时必须显式返回 empty（而不是 undefined），避免组件回落到默认材质。
      if (!MaterialController.glassSupported() || !MaterialController.appMaterialOn()) {
        expect(MaterialController.overlayMaterial(false) === undefined).assertTrue();
      } else {
        expect(MaterialController.overlayMaterial(false) === uiMaterial.Material.empty).assertTrue();
      }
    });

    it('glass_material_follows_device_support', 0, () => {
      // 开关打开时：能不能拿到材质必须与 isImmersiveMaterialSupported() 完全一致，
      // 避免出现"设了 systemMaterial 却静默无效"的假成功。
      const material: uiMaterial.Material | undefined = MaterialController.glassMaterial(true);
      expect(material === undefined).assertEqual(!MaterialController.glassSupported());
    });
  });
}
