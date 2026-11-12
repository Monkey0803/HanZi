import settingsOptionsTest from './SettingsOptions.test';
import materialMapTest from './MaterialMap.test';
import imageSupportTest from './ImageSupport.test';
import constantsTest from './Constants.test';
import strokeEngineTest from './StrokeEngine.test';
import customImmersivePolicyTest from './CustomImmersivePolicy.test';
import adoptionPolicyTest from './AdoptionPolicy.test';
import strokeNumberLayoutTest from './StrokeNumberLayout.test';
import pinyinUtilsTest from './PinyinUtils.test';
import ideographDecompositionTest from './IdeographDecomposition.test';
import dailyCharPickerTest from './DailyCharPicker.test';
import readingTextBuilderTest from './ReadingTextBuilder.test';
import readingQuizTest from './ReadingQuiz.test';
import reviewSchedulerTest from './ReviewScheduler.test';

export default function testsuite() {
  settingsOptionsTest();
  materialMapTest();
  imageSupportTest();
  constantsTest();
  strokeEngineTest();
  customImmersivePolicyTest();
  adoptionPolicyTest();
  strokeNumberLayoutTest();
  pinyinUtilsTest();
  ideographDecompositionTest();
  dailyCharPickerTest();
  reviewSchedulerTest();
  readingTextBuilderTest();
  readingQuizTest();
}
