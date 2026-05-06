import json
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SEED_PATH = ROOT / "model" / "data" / "memo_context_seed_examples.json"
OUT_PATH = ROOT / "model" / "data" / "memo_context_examples.json"
TARGET_PER_LABEL = 600

LABELS = ["일정", "할 일", "아이디어", "공부", "업무", "건강", "여행", "재정", "개인", "일기"]
STYLES = ["short", "long", "imperative", "record", "colloquial", "ambiguous"]

COMMON_TIMES = [
    "오늘 오전",
    "오늘 저녁",
    "내일 아침",
    "내일 오후",
    "이번 주말",
    "다음 주 월요일",
    "다음 달 초",
    "퇴근 후",
    "점심시간에",
    "자기 전에",
    "주말 전에",
    "월말까지",
]

COMMON_CONNECTORS = [
    "놓치지 않게",
    "시간 나면",
    "우선순위로",
    "나중에 다시 볼 수 있게",
    "필요하면",
    "가능하면",
    "급한 건 아니지만",
    "헷갈리지 않게",
]

VARIANT_NOTES = [
    "",
    " 간단히 남김.",
    " 자세히 다시 확인.",
    " 앱에 저장.",
    " 종이에 적어둔 내용 옮김.",
    " 관련 링크 있으면 추가.",
    " 우선순위 낮음.",
    " 우선순위 높음.",
    " 나중에 검색하기 쉽게 적기.",
    " 헷갈리는 부분 표시.",
    " 다음에 이어서 보기.",
    " 필요하면 알림 설정.",
    " 완료 후 상태 바꾸기.",
    " 짧게만 기록.",
    " 길게 풀어서 정리.",
    " 오늘 안에 한 번 보기.",
    " 주말 전에 확인.",
    " 월말에 다시 보기.",
    " 관련 사진 있으면 붙이기.",
    " 이름을 명확히 적기.",
    " 숫자나 시간 틀리지 않게.",
    " 다른 메모와 섞이지 않게.",
    " 아직 확정은 아님.",
    " 확정되면 업데이트.",
    " 필요한 것만 남기기.",
    " 너무 오래 붙잡지 않기.",
    " 한 줄 요약 추가.",
    " 상세 내용은 나중에 보강.",
    " 중요한 단어만 표시.",
    " 다음 행동을 분명히 적기.",
]

CATEGORY_CONFIG = {
    "일정": {
        "topics": ["팀 회의", "병원 예약", "치과 스케일링", "친구 약속", "교수님 면담", "고객 미팅", "세미나 참석", "수업 시간", "운동 레슨", "가족 식사", "면접 일정", "출장 출발", "보고서 마감", "공연 예매", "상담 예약", "동창회 모임"],
        "actions": ["캘린더에 넣기", "시간 확인", "장소 확인", "알림 설정", "준비물 챙기기", "늦지 않게 출발", "참석 여부 답장", "일정 조율", "예약 번호 확인", "이동 시간 계산"],
        "details": ["주소가 바뀌었는지 확인", "담당자 연락처 저장", "자료를 미리 읽어두기", "전날 한 번 더 확인", "교통 상황 보고 출발", "관련 파일 챙기기", "참석자 명단 확인", "끝나는 시간도 같이 기록"],
        "ambiguous": [
            "{topic} 때문에 공부 계획을 미뤄야 할 수도 있음",
            "업무 메모처럼 보이지만 핵심은 {topic} 시간 확정",
            "{topic} 준비물은 할 일 같지만 캘린더에 넣어야 함",
            "친구랑 이야기한 내용보다 {topic} 약속 시간이 중요",
            "{topic} 관련 비용도 있지만 우선 날짜부터 확정",
        ],
    },
    "할 일": {
        "topics": ["장보기", "세탁물 정리", "택배 확인", "분리수거", "냉장고 정리", "사진 백업", "관리비 납부 확인", "부모님 전화", "선물 주문", "신발장 정리", "앱 업데이트", "서류 제출 준비", "차량 점검", "화장실 청소", "구독 서비스 해지", "비밀번호 변경"],
        "actions": ["끝내기", "체크하기", "미리 해두기", "목록 만들기", "순서대로 처리", "오늘 안에 하기", "잊지 말기", "완료 표시", "필요한 것 사기", "다시 확인"],
        "details": ["급한 것부터 처리", "미루면 번거로워짐", "준비물이 필요함", "한 번에 묶어서 하기", "끝나면 메모 지우기", "확인 문자 남기기", "기한 넘기지 않기", "다른 일과 같이 처리"],
        "ambiguous": [
            "{topic} 일정은 아니고 그냥 처리해야 할 일",
            "{topic} 비용이 들 수 있지만 가계부보다 해야 할 일에 가까움",
            "아이디어가 아니라 {topic} 실제로 실행하기",
            "{topic} 기록보다 완료 여부가 중요",
            "공부 자료 정리가 아니라 {topic}부터 처리",
        ],
    },
    "아이디어": {
        "topics": ["자동 분류 기능", "새 앱 화면", "블로그 주제", "유튜브 콘텐츠", "브랜드 카피", "사이드 프로젝트", "독서 모임 발제", "인테리어 구조", "루틴 설계", "업무 자동화", "마케팅 캠페인", "새 서비스 컨셉", "로고 시안", "식단 조합", "투자 포트폴리오", "모임 운영 방식"],
        "actions": ["구상하기", "초안 잡기", "아이디어 확장", "가능성 검토", "메모로 남기기", "다른 방식 생각", "프로토타입 상상", "장단점 적기", "키워드 뽑기", "나중에 발전시키기"],
        "details": ["아직 실행 단계는 아님", "대략적인 방향만 있음", "비슷한 사례 찾아보기", "문제와 해결책을 나눠보기", "사용자 입장에서 다시 생각", "작게 실험 가능", "기획안으로 키울 수 있음", "한 줄 컨셉이 필요"],
        "ambiguous": [
            "{topic}은 업무처럼 보이지만 아직 아이디어 단계",
            "{topic} 관련 공부가 아니라 새롭게 떠오른 구상",
            "당장 할 일은 아니고 {topic} 가능성 메모",
            "{topic} 비용 계산보다 컨셉 방향이 먼저",
            "일기처럼 적었지만 핵심은 {topic} 아이디어",
        ],
    },
    "공부": {
        "topics": ["영어 단어", "자료구조", "알고리즘 문제", "논문 읽기", "자격증 실기", "토익 스피킹", "스페인어 회화", "경제 기사", "디자인 패턴", "머신러닝 개념", "리액트 상태 관리", "수학 문제", "역사 교양서", "심리학 과제", "운전면허 필기", "데이터 분석 강의"],
        "actions": ["복습하기", "요약 정리", "문제 풀기", "오답노트 작성", "강의 듣기", "핵심 개념 정리", "예제 따라하기", "기출 확인", "암기하기", "읽고 표시"],
        "details": ["모르는 부분 따로 체크", "예시를 직접 만들어보기", "시험 범위에 포함", "지난번 틀린 부분 다시 보기", "30분만 집중", "개념과 실습 나누기", "요약본 다시 읽기", "질문 목록 만들기"],
        "ambiguous": [
            "{topic} 일정이 아니라 공부할 내용",
            "{topic} 관련 업무 자료처럼 보여도 학습용 정리",
            "{topic} 메모는 아이디어가 아니라 개념 이해 목적",
            "{topic} 기록보다 시험 대비가 중요",
            "할 일 목록 같지만 핵심은 {topic} 공부",
        ],
    },
    "업무": {
        "topics": ["주간 보고서", "클라이언트 메일", "프로젝트 일정", "기획 회의 안건", "QA 시나리오", "API 스펙", "마케팅 비용 정산", "고객 CS 분석", "서버 대시보드", "경쟁사 조사", "PPT 슬라이드", "온보딩 자료", "영업 데이터", "임원 보고", "협력업체 미팅", "버그 리포트"],
        "actions": ["작성하기", "공유하기", "검토하기", "답장하기", "정리하기", "담당자에게 전달", "초안 만들기", "리뷰 요청", "데이터 확인", "후속 작업 등록"],
        "details": ["팀에 공유 필요", "마감 전에 확인", "근거 자료 첨부", "담당자 코멘트 반영", "버전 헷갈리지 않기", "결정 사항 따로 표시", "수치 다시 검산", "리스크 메모"],
        "ambiguous": [
            "{topic}은 공부 자료가 아니라 회사 업무",
            "{topic} 일정도 있지만 핵심은 업무 처리",
            "{topic} 아이디어가 아니라 실제 프로젝트 문서",
            "{topic} 비용 메모는 개인 재정이 아니라 업무 정산",
            "일기처럼 적었지만 {topic} 관련 업무 회고",
        ],
    },
    "건강": {
        "topics": ["러닝 운동", "헬스 하체 운동", "요가 수업", "치과 진료", "피부과 상담", "수면 시간", "식단 기록", "영양제 루틴", "허리 스트레칭", "혈당 관리", "체중 기록", "명상 15분", "내과 처방약", "금연 기록", "필라테스", "물 마시기"],
        "actions": ["기록하기", "챙기기", "무리하지 않기", "루틴 지키기", "상태 확인", "예약 확인", "운동하기", "증상 적기", "습관 점검", "회복 우선"],
        "details": ["통증 있으면 중단", "수치를 같이 남기기", "몸 상태를 보고 조절", "식사 후에 확인", "전보다 나아졌는지 비교", "꾸준히 하는 게 중요", "약 복용 시간 체크", "피로도 함께 기록"],
        "ambiguous": [
            "{topic}은 일정처럼 보여도 건강 관리 내용",
            "{topic} 비용보다 몸 상태 기록이 중요",
            "{topic} 할 일이라기보다 건강 루틴",
            "{topic} 일기처럼 적었지만 건강 변화 기록",
            "여행 준비가 아니라 {topic} 컨디션 체크",
        ],
    },
    "여행": {
        "topics": ["제주 항공권", "호텔 예약", "여권 확인", "공항 버스", "오사카 맛집", "방콕 마사지샵", "여행자 보험", "캐리어 짐", "해외 로밍", "렌터카 예약", "현지 투어", "미술관 입장권", "환전", "캠핑장 예약", "여행 코스", "기념품 리스트"],
        "actions": ["확인하기", "예약하기", "지도에 저장", "비교하기", "준비물 챙기기", "번호 저장", "일정표에 추가", "가격 확인", "후기 찾아보기", "체크리스트 만들기"],
        "details": ["출발 전에 다시 확인", "예약 번호 캡처", "현지 시간 기준으로 보기", "동선이 겹치지 않게 조정", "날씨에 맞춰 준비", "취소 규정 확인", "주소를 오프라인 저장", "예산과 같이 보기"],
        "ambiguous": [
            "{topic} 비용이 있지만 재정보다 여행 준비",
            "{topic} 일정처럼 보이지만 여행 계획 일부",
            "{topic} 맛집 메모는 개인 취향보다 여행 정보",
            "{topic} 체크는 할 일이지만 여행 폴더에 넣기",
            "공부 자료가 아니라 {topic} 여행 정보 조사",
        ],
    },
    "재정": {
        "topics": ["카드 결제 내역", "월 예산", "보험료 자동이체", "세금 납부", "적금 만기", "식비 지출", "배당금 입금", "연말정산 서류", "청약 저축", "통신비 할인", "대출 이자", "중고거래 수익", "자동차세", "관리비 고지서", "비상금 통장", "쇼핑 지출"],
        "actions": ["확인하기", "기록하기", "계산하기", "납부하기", "비교하기", "정리하기", "영수증 보관", "예산 조정", "이체 확인", "지출 줄이기"],
        "details": ["금액을 정확히 적기", "증빙을 따로 저장", "다음 달 예산에 반영", "자동이체일 확인", "불필요한 지출 표시", "세부 항목 나누기", "잔액과 같이 보기", "혜택 조건 확인"],
        "ambiguous": [
            "{topic} 일정이 있지만 핵심은 돈 관리",
            "{topic} 할 일처럼 보여도 재정 기록",
            "{topic} 여행 준비가 아니라 예산 확인",
            "{topic} 업무 비용이 아니라 개인 지출",
            "일기처럼 적었지만 {topic} 소비 패턴 메모",
        ],
    },
    "개인": {
        "topics": ["가족 대화", "좋아하는 문장", "영화 명대사", "와인 시향", "위시리스트", "성격 유형 결과", "인터뷰 링크", "버킷리스트", "플레이리스트", "레시피", "스트레스 해소법", "꿈 내용", "좌우명", "카페 모음", "향수 노트", "좋아하는 계절"],
        "actions": ["메모해두기", "나중에 다시 보기", "모아두기", "기록하기", "생각 정리", "링크 저장", "리스트 만들기", "느낌 남기기", "취향 정리", "기억해두기"],
        "details": ["사적인 내용이라 따로 보관", "정답이 있는 내용은 아님", "나중에 참고하고 싶음", "취향이 드러나는 메모", "개인적인 기준으로 정리", "공유하지 않아도 됨", "가볍게 남겨두기", "생각이 바뀔 수 있음"],
        "ambiguous": [
            "{topic}은 일기보다 자료 보관에 가까움",
            "{topic}은 공부가 아니라 개인 취향 메모",
            "{topic} 비용보다 나중에 보고 싶은 개인 기록",
            "{topic} 일정은 아니고 그냥 저장해둘 내용",
            "업무 링크가 아니라 {topic} 개인 참고용",
        ],
    },
    "일기": {
        "topics": ["오늘 하루", "친구와 만난 일", "비 오는 기분", "회사에서 실수한 마음", "목표 달성한 순간", "가족 저녁", "무기력했던 시간", "푹 쉰 일요일", "새로운 도전", "상처받은 말", "운동 후 개운함", "예상 못 한 행운", "반성한 밤", "고마웠던 순간", "평화로운 하루", "설렘과 두려움"],
        "actions": ["느낌 적기", "마음 정리", "하루 돌아보기", "감정 기록", "생각 남기기", "솔직하게 쓰기", "기분 정리", "배운 점 적기", "나에게 남기기", "기억해두기"],
        "details": ["특별한 결론은 없어도 됨", "감정이 중요", "나중에 읽으면 좋을 듯", "그때 기분을 잊고 싶지 않음", "잘한 점과 아쉬운 점 같이 적기", "오늘의 분위기를 남기기", "마음이 복잡했음", "작은 변화가 있었음"],
        "ambiguous": [
            "{topic}에 운동이 나오지만 핵심은 감정 기록",
            "{topic}은 업무 사건보다 그때 느낀 마음",
            "{topic} 일정이 아니라 하루 회고",
            "{topic} 공부 내용보다 오늘의 생각 정리",
            "돈 이야기가 조금 있지만 {topic} 감정이 중심",
        ],
    },
}

STYLE_TEMPLATES = {
    "short": [
        "{topic} {action}",
        "{topic} {detail}",
        "{topic} 체크",
        "{time} {topic}",
    ],
    "long": [
        "{time} {topic} 관련해서 {detail}. {connector} {action}도 같이 해두기.",
        "{topic} 때문에 필요한 내용을 정리했다. {detail}라서 {action}까지 해두면 좋겠다.",
        "{time} {topic} 메모. {detail}, {connector} 다음에 이어서 확인.",
    ],
    "imperative": [
        "{time} {topic} {action}하기",
        "잊지 말고 {topic} {action}",
        "{connector} {topic} 먼저 {action}",
        "{topic} 미루지 말고 {action}",
    ],
    "record": [
        "{time} {topic} {detail} 기록",
        "오늘 {topic} 관련해서 {detail}.",
        "{topic} 진행 상황: {detail}, 다음엔 {action}.",
        "{time} 기준 {topic} 메모 남김.",
    ],
    "colloquial": [
        "아 {topic} {action}해야겠다",
        "{topic} 이거 까먹을 뻔, {action}",
        "{connector} {topic} 좀 봐야겠다",
        "{topic} 때문에 살짝 헷갈림. {detail}",
    ],
}


def pick(values, index, salt=0):
    return values[(index + salt) % len(values)]


def render(config, style, index, label_index):
    slot = index // len(STYLES)
    topic = pick(config["topics"], slot * 3, label_index)
    action = pick(config["actions"], slot * 5, label_index)
    detail = pick(config["details"], slot * 7, label_index)
    time = pick(COMMON_TIMES, slot * 11, label_index)
    connector = pick(COMMON_CONNECTORS, slot * 13, label_index)

    if style == "ambiguous":
        template = pick(config["ambiguous"], index, label_index)
    else:
        template = pick(STYLE_TEMPLATES[style], index, label_index)

    suffix = pick(VARIANT_NOTES, slot * 17, label_index)
    return template.format(
        topic=topic,
        action=action,
        detail=detail,
        time=time,
        connector=connector,
    ) + suffix


def load_seed_examples():
    if not SEED_PATH.exists():
        return []
    return json.loads(SEED_PATH.read_text(encoding="utf-8"))


def main():
    seed_by_label = {label: [] for label in LABELS}
    for item in load_seed_examples():
        label = item.get("label")
        text = item.get("text")
        if label in seed_by_label and text:
            seed_by_label[label].append({"label": label, "style": "seed", "text": text})

    all_examples = []
    seen_texts = set()

    for label_index, label in enumerate(LABELS):
        label_examples = []
        for item in seed_by_label[label]:
            if item["text"] not in seen_texts:
                label_examples.append(item)
                seen_texts.add(item["text"])

        style_counts = Counter(item["style"] for item in label_examples)
        index = 0
        while len(label_examples) < TARGET_PER_LABEL:
            if index > TARGET_PER_LABEL * 80:
                raise RuntimeError(f"Could not create enough unique examples for {label}")
            style = STYLES[index % len(STYLES)]
            text = render(CATEGORY_CONFIG[label], style, index, label_index)
            if text not in seen_texts:
                label_examples.append({"label": label, "style": style, "text": text})
                style_counts[style] += 1
                seen_texts.add(text)
            index += 1

        all_examples.extend(label_examples[:TARGET_PER_LABEL])
        print(label, len(label_examples[:TARGET_PER_LABEL]), dict(style_counts))

    OUT_PATH.write_text(
        json.dumps(all_examples, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {len(all_examples)} examples to {OUT_PATH}")


if __name__ == "__main__":
    main()
