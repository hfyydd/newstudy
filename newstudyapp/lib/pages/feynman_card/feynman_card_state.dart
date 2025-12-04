import 'package:get/get.dart';

/// 费曼卡片数据模型
class FeynmanCard {
  final String category;
  final String title;
  final String description;

  const FeynmanCard({
    required this.category,
    required this.title,
    required this.description,
  });
}

/// 费曼卡片页面状态
class FeynmanCardState {
  /// 当前卡片索引
  final currentIndex = 0.obs;

  /// 卡片列表
  final cards = <FeynmanCard>[
    const FeynmanCard(
      category: '生物学',
      title: '光合作用',
      description: '植物将光能转化为化学能的过程',
    ),
    const FeynmanCard(
      category: '物理学',
      title: '牛顿第一定律',
      description: '物体在不受外力作用时保持静止或匀速直线运动',
    ),
    const FeynmanCard(
      category: '化学',
      title: '氧化还原反应',
      description: '化学反应中电子转移的过程',
    ),
    const FeynmanCard(
      category: '数学',
      title: '微积分',
      description: '研究变化率和累积量的数学分支',
    ),
    const FeynmanCard(
      category: '经济学',
      title: '供需定律',
      description: '市场价格由供给和需求共同决定',
    ),
  ].obs;

  /// 获取总卡片数
  int get totalCards => cards.length;

  /// 获取当前卡片
  FeynmanCard get currentCard => cards[currentIndex.value];

  /// 获取当前页码（从1开始）
  int get currentPage => currentIndex.value + 1;
}

