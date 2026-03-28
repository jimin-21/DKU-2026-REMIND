import '../models/post.dart';
import '../models/post_detail.dart';
import '../models/post_status.dart';

final List<Post> homePosts = [
  Post(
    id: 1,
    category: '자기계발',
    source: '@mindful_living',
    tags: ['#기록', '#습관'],
    title: '기록 습관 기르는 방법',
    date: '2026-03-07',
    keyPoints: [
      '기존 습관에 이어붙이기',
      '트래커 활용하기',
      '작은 기록 도구 항상 두기',
    ],
    isFavorite: true,
    isPinned: true,
    isRead: false,
    status: PostStatus.active,
  ),
  Post(
    id: 2,
    category: '운동',
    source: '@fitness_daily',
    tags: ['#운동', '#루틴'],
    title: '집에서 하는 전신 운동 루틴',
    date: '2026-03-05',
    keyPoints: [
      '스쿼트 15회 3세트',
      '푸시업 10회 3세트',
      '스트레칭으로 마무리',
    ],
    isFavorite: false,
    isPinned: false,
    isRead: false,
    status: PostStatus.active,
  ),
];

final List<Post> archivedPosts = [
  Post(
    id: 101,
    category: '기타',
    source: '@minimal_note',
    tags: ['#정리', '#미니멀'],
    title: '미니멀 라이프 시작하기',
    date: '2026-02-01',
    keyPoints: [
      '1일 1버리기 실천',
      '필요한 것만 구매',
      '공간의 여백 유지',
    ],
    isFavorite: true,
    isPinned: false,
    isRead: true,
    status: PostStatus.archived,
  ),
  Post(
    id: 102,
    category: '운동',
    source: '@fitness_coach',
    tags: ['#헬스', '#근력'],
    title: '집에서 하는 상체 운동',
    date: '2026-02-10',
    keyPoints: [
      '푸시업 3세트',
      '덤벨 운동 추가',
      '플랭크로 마무리',
    ],
    isFavorite: true,
    isPinned: false,
    isRead: true,
    status: PostStatus.archived,
  ),
  Post(
    id: 103,
    category: '장소',
    source: '@seoul_walk',
    tags: ['#산책', '#서울'],
    title: '북촌 한옥마을 산책 코스',
    date: '2026-02-08',
    keyPoints: [
      '안국역에서 출발',
      '카페 골목 들르기',
      '해질 무렵 사진 찍기',
    ],
    isFavorite: false,
    isPinned: false,
    isRead: true,
    status: PostStatus.archived,
  ),
];

final List<Post> minePosts = [
  Post(
    id: 201,
    category: '자기계발',
    source: null,
    tags: ['#아침루틴', '#습관'],
    title: '아침 루틴 만들기',
    date: '2026-02-15',
    keyPoints: [
      '매일 같은 시간에 일어나기',
      '물 한 잔 마시기',
      '스트레칭 5분',
    ],
    isFavorite: false,
    isPinned: false,
    isRead: true,
    status: PostStatus.mine,
  ),
  Post(
    id: 202,
    category: '운동',
    source: null,
    tags: ['#헬스', '#기록'],
    title: '주간 운동 체크리스트',
    date: '2026-02-18',
    keyPoints: [
      '월 수 금 근력운동',
      '화 목 유산소',
      '일요일 휴식',
    ],
    isFavorite: false,
    isPinned: false,
    isRead: true,
    status: PostStatus.mine,
  ),
];

final List<Post> allPosts = [
  ...archivedPosts,
  ...homePosts,
];

final Map<String, PostDetail> postDetails = {
  '1': PostDetail(
    id: 1,
    type: 'link',
    category: '자기계발',
    source: '@mindful_living',
    tags: ['#기록', '#습관'],
    title: '기록 습관 기르는 방법',
    date: '2026-03-07',
    keyPoints: [
      '기존 습관에 이어붙이기',
      '트래커 활용하기',
      '작은 기록 도구 항상 두기',
    ],
    summaryList: [
      '기존 습관에 새 행동을 이어붙이면 시작 장벽이 낮아진다.',
      '트래커를 사용하면 눈에 보이는 성취가 쌓여 지속하기 쉬워진다.',
      '기록 도구를 손 닿는 곳에 두면 습관 형성이 빨라진다.',
    ],
    originalText:
        '기록 습관은 거창하게 시작할 필요가 없습니다. 매일 하던 행동에 짧은 기록을 덧붙이는 것만으로도 충분합니다. 예를 들어 잠들기 전 오늘의 한 줄을 적는 방식처럼 작은 루틴부터 시작하면 부담이 적습니다.',
    originalUrl: 'https://example.com/post/1',
    isFavorite: true,
    isMastered: true,
    masteredDate: '2026-03-12',
    memo: '',
  ),
};