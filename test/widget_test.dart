// test/widget_test.dart
// 冒烟测试：App 能正常启动，主框架（底部导航）渲染出来。
// 说明：项目根组件是 TaoyueEduApp（lib/app.dart），不是脚手架模板的 MyApp。
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_edu_app/app.dart';
import 'package:flutter_edu_app/core/di.dart';

void main() {
  testWidgets('App 启动冒烟测试：能看到底部导航「首页」', (WidgetTester tester) async {
    await setupLocator(); // 注册 get_it 依赖，页面才取得到 HomeRepository 等

    await tester.pumpWidget(const TaoyueEduApp());

    // initState 里用 post-frame 触发的首次加载需要额外的帧才会执行；
    // 测试环境无后端，Dio 请求会被 flutter_test 拦截为 400，页面进入稳定错误态。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 底部导航四个 Tab 文案是稳定的（见 lib/ui/main/main_page.dart）
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}