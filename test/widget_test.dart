import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo/main.dart';

void main() {
  testWidgets('TODO 앱 기본 렌더링 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    expect(find.text('TODO'), findsOneWidget);
    expect(find.text('할 일을 추가해보세요!'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('TODO 항목 추가 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    await tester.enterText(find.byType(TextField), '우유 사기');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('우유 사기'), findsOneWidget);
    expect(find.text('남은 할 일: 1개 / 전체: 1개'), findsOneWidget);
  });

  testWidgets('TODO 완료 체크 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    await tester.enterText(find.byType(TextField), '운동하기');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // 체크 원 버튼 탭
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();

    expect(find.text('남은 할 일: 0개 / 전체: 1개'), findsOneWidget);
  });
}
