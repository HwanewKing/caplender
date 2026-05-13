# caplender

> 사진 한 장으로 끝나는 메모와 리마인드.
> 카톡 "나에게 보내기"나 갤러리 뒤지기로 잃어버리던 정보를 깔끔하게 모아둡니다.

---

## 한 줄 소개

디지털 친화도가 낮은 **40–50대 사용자**를 위한 사진 메모/리마인드 앱.
사진을 찍기만 하면 AI가 **자동으로 분류**(메모 · 영수증 · 명함 · 설명서 · 기타)하고, 필요한 순간에 **알림**으로 다시 띄워줍니다.

---

## 핵심 기능 (MVP)

| 기능 | 설명 |
| --- | --- |
| 사진 촬영 → 자동 분석 | 촬영 즉시 OpenAI Vision이 이미지를 읽어 카테고리·제목·날짜·내용을 한국어로 추출 |
| 5가지 카테고리 자동 분류 | `메모` · `영수증` · `명함` · `설명서` · `기타` |
| 리마인드 | 메모마다 알림 시각 설정 — 약속, 영수증 보관기간, 진료 일정 등 |
| 캘린더 보기 | 날짜별로 메모를 한눈에 — 일정과 사진 메모가 한 화면에 |
| 큰 글씨 모드 | 4단계 글자 크기(`작게` · `보통` · `크게` · `아주 크게`) |

---

## 기술 스택

- **Frontend** — Flutter (Dart `^3.11.5`, Material 3)
- **Backend** — Supabase (Postgres + Storage + Auth + Edge Functions)
- **AI** — OpenAI Vision (`gpt-5.4-nano`, Edge Function 경유)
- **주요 패키지** — `supabase_flutter`, `image_picker`, `google_fonts`(Gaegu 손글씨체), `shared_preferences`

---

## 디자인 원칙

40–50대 사용자를 기준으로 만들었습니다.

- **탭 수 최소화** — 한두 번 만에 모든 기능에 도달
- **모호한 자동화 금지** — "자동 삭제"처럼 부정확할 수 있는 기능은 제외
- **익명 로그인 기본값** — 회원가입 없이 바로 사용. 이후 이메일로 업그레이드 가능
- **깔끔한 한국어 출력** — AI 응답은 4줄 고정 포맷, 영어·이모지·마크다운 사용 안 함
- **친근한 색감과 손글씨 폰트** — `cream`/`teal` 베이스, 메모 본문에 Gaegu 폰트

---

## 프로젝트 구조

```
caplender/
├── lib/
│   ├── main.dart                  # 부트스트랩 + 에러 복구 게이트
│   ├── app.dart                   # MaterialApp + 테마/스코프
│   ├── data/                      # 모델, 카테고리 시드
│   ├── screens/
│   │   ├── home_shell.dart        # 하단 탭 셸
│   │   ├── calendar/              # 캘린더 + 일자 상세
│   │   ├── gallery/               # 카테고리별 사진 갤러리
│   │   ├── reminders/             # 리마인드 목록
│   │   ├── quick_photo/           # 사진 촬영 플로우
│   │   ├── quick_text/            # 텍스트 메모 플로우
│   │   ├── photo_memo_detail.dart
│   │   ├── photo_memo_edit.dart
│   │   └── settings/
│   ├── services/
│   │   ├── bootstrap.dart         # Supabase 초기화 + 익명 로그인
│   │   ├── auth_service.dart
│   │   ├── memo_store.dart        # 인메모리 캐시 + 변경 알림
│   │   ├── memo_repository.dart   # Supabase CRUD
│   │   └── photo_capture_service.dart
│   ├── widgets/                   # 공용 위젯
│   └── theme/                     # 색상, 글꼴, 설정
├── supabase/
│   ├── migrations/
│   │   ├── 0001_initial_schema.sql      # categories, photo_memos, storage RLS
│   │   ├── 0002_profiles.sql            # profiles + 자동 생성 트리거
│   │   └── 0003_add_manual_category.sql # "설명서" 카테고리 추가
│   └── functions/
│       └── classify-image/        # OpenAI Vision 호출 Edge Function
├── env.example.json
└── pubspec.yaml
```

---

## 데이터 모델

**`photo_memos`** — 한 줄에 사진 메모 하나

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| `id` | uuid | PK |
| `user_id` | uuid | 소유자 (RLS로 격리) |
| `memo_date` | date | 캘린더에서 보이는 날짜 |
| `title` / `memo` | text | 사용자가 보는 제목/본문 |
| `category_id` | text | 5개 카테고리 중 하나 |
| `photo_path` | text | `{user_id}/{photo_id}.jpg` |
| `ocr_text` | text | AI가 사진에서 뽑아낸 "내용" |
| `classification_reason` | text | 분류 근거 |
| `remind` / `remind_at` | bool / timestamptz | 알림 설정 |

모든 테이블에 **Row-Level Security** 적용 — 본인 데이터만 읽고 쓸 수 있습니다.
Storage 버킷 `photo-memos`도 `{user_id}/` 폴더 단위로 격리됩니다.

---

## AI 분류 응답 포맷

Edge Function이 OpenAI Vision으로부터 받아 파싱하는 4줄 고정 포맷입니다.

```
제목: <한국어, 15자 이내, 다시 찾기 쉬운 키워드>
날짜: <YYYY-MM-DD | MM-DD | 해당 없음 | 확인 필요>
카테고리: <영수증 | 메모 | 명함 | 설명서 | 기타>
내용: <핵심 텍스트. 항목별로 줄바꿈, 글머리표 사용 안 함>
```

예외 응답(흐린 사진, 텍스트 없음, 입력 부족 등)도 동일한 포맷으로 처리됩니다.
프롬프트는 [supabase/functions/classify-image/index.ts](supabase/functions/classify-image/index.ts) 참고.

---

## 빠른 시작

### 1. 환경 변수 설정

`env.example.json`을 복사해서 `env.json`을 만들고 본인 Supabase 값을 채워 넣습니다. (`env.json`은 gitignore 됨)

```json
{
  "SUPABASE_URL": "https://your-project-ref.supabase.co",
  "SUPABASE_ANON_KEY": "eyJhbGc...your-anon-jwt-here"
}
```

### 2. Supabase 마이그레이션

Supabase Dashboard → SQL Editor에서 순서대로 실행:

```
supabase/migrations/0001_initial_schema.sql
supabase/migrations/0002_profiles.sql
supabase/migrations/0003_add_manual_category.sql
```

### 3. Edge Function 시크릿

Dashboard → Edge Functions → Secrets:

```
OPENAI_API_KEY = sk-...
OPENAI_MODEL   = gpt-4o-mini   # (선택)
```

그리고 함수 배포:

```bash
supabase functions deploy classify-image
```

### 4. 앱 실행

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

---

## 보안 메모

- 시크릿은 **`--dart-define`** 으로만 주입합니다. 에셋에 번들링하지 않습니다.
- 클라이언트는 Edge Function을 통해서만 OpenAI를 호출합니다 — API 키는 서버에만 존재.
- Edge Function은 호출자의 JWT를 검증하고, 사진 경로가 본인 폴더(`{user_id}/...`)인지 한 번 더 확인합니다.

---

## 가격 정책

타깃 사용자의 가격 민감도가 높아 **월 3,000–5,000원 이하**를 기준으로 검토 중입니다.
(자동 삭제처럼 정확도가 불확실한 기능은 무료/유료 모두에서 제외)

---

## 상태

MVP 개발 중. 캘린더 · 갤러리 · 사진/텍스트 메모 플로우 · 리마인드 · 설정 화면 구현 완료, 분류 Edge Function 연동 완료.
