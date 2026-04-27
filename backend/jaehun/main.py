from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import requests
from bs4 import BeautifulSoup
import os
import re
import json
import base64
from datetime import datetime, timezone, timedelta
from dotenv import load_dotenv
from openai import OpenAI
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate

import firebase_admin
from firebase_admin import credentials, firestore

# 1. 환경 변수 로드
load_dotenv()
RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# --- Firebase 초기화 ---
cred = credentials.Certificate("resee-app-firebase-adminsdk-fbsvc-7110fd24e7.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

app = FastAPI()

# 2. CORS 설정 
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_headers=["*"],
)

# 3. AI 엔진 설정
llm_mini = ChatOpenAI(model_name="gpt-4o-mini", temperature=0, openai_api_key=OPENAI_API_KEY)
llm_pro = ChatOpenAI(model_name="gpt-4o", temperature=0, openai_api_key=OPENAI_API_KEY)
vision_client = OpenAI(api_key=OPENAI_API_KEY)

# 4. 요약 지시서 (자기계발 범위를 더 명확히 정의)
summary_prompt = PromptTemplate(
    input_variables=["content"],
    template="""
    너는 콘텐츠 분석 전문가야. 아래 규칙을 '반드시' 지켜서 분석해줘.
    사용자가 한눈에 정보를 파악할 수 있도록 불필요한 서술어는 빼고 핵심 데이터만 정리해줘.

    [작성 규칙]
    1. 반드시 한국어로 답변할 것.
    2. [전수 조사]: 본문에 여러 개의 장소, 제품, 정보가 나열되어 있다면 **절대로 하나도 빠뜨리지 말고 모두** 적어. 
       (예: 맛집 6곳이 나오면 6개 항목이 모두 요약에 포함되어야 함)
    3. [문장 형식 금지]: '~합니다', '~입니다' 같은 서술형 문장을 사용하지 마.
    4. [정보 보존]: 식당/제품 이름, 상세 주소(위치), 메뉴, 가격, 운영 시간, 꿀팁을 최대한 상세히 포함해.
    5. [리스트 형식]: 반드시 '• 항목명: 상세설명' 형식을 사용하고, 항목 간에는 줄바꿈을 해줘.
    6. [요약 금지]: 전체 내용을 한두 문장으로 뭉뚱그려 요약하지 마. 개별 항목을 나열하는 것이 우선이야.
    
    7. [카테고리 선택 - 아래 5개 중 하나만 딱 골라]
       - 장소 (주소나 위치가 명확한 식당, 카페, 여행지, 숙소, 사찰 등)
       - 자기계발 (K-패스 등 정책, 경제, 재테크, 공부법, 뉴스, 커리어, 지식)
       - 쇼핑 (제품 추천, 후기, 세일 정보)
       - 운동 (헬스, 식단, 건강 관리)
       - 기타 (위 4개에 해당하지 않는 내용)

    본문 내용:
    {content}

    답변 형식(JSON):
    {{
        "summary": "요약내용 (개별 항목을 줄바꿈하여 리스트로 작성)", 
        "category": "자기계발", 
        "tags": ["태그1", "태그2"]
    }}
    """
)

# --- [보조 함수들] ---

def parse_ai_json(response_text):
    clean_response = response_text.replace("```json", "").replace("```", "").strip()
    return json.loads(clean_response)

def get_ai_summary(content, use_pro=False):
    if not content or content == "내용 없음" or len(content) < 10:
        return "정보를 추출할 본문이 부족합니다.", "기타", []
        
    try:
        model = llm_pro if use_pro else llm_mini
        formatted_prompt = summary_prompt.format(content=content[:4000])
        response_message = model.invoke(formatted_prompt)
        result = parse_ai_json(response_message.content)
        
        summary_text = result.get("summary", "")
        ai_category = result.get("category", "기타").strip()
        tags = result.get("tags", [])

        # --- 1. 태그 개수 강제 제한 (2개) ---
        final_tags = tags[:2] if isinstance(tags, list) else []

        allowed_categories = ["장소", "자기계발", "쇼핑", "운동", "기타"]

        # --- 2. 카테고리 검증 및 강제 보정 로직 ---
        
        # AI가 리스트에 없는 단어를 만든 경우 1차 교정
        if ai_category not in allowed_categories:
            if any(word in ai_category for word in ["맛집", "여행", "카페", "사찰", "숙소", "장소"]): ai_category = "장소"
            elif any(word in ai_category for word in ["정책", "재테크", "공부", "팁", "카드", "혜택"]): ai_category = "자기계발"
            else: ai_category = "기타"

        # [핵심] '장소'로 분류됐지만 내용상 '정책/정보'인 경우 2차 교정 (K-패스 필터)
        policy_keywords = ["K-패스", "K패스", "환급", "카드", "정책", "정부", "혜택", "금리", "이자", "교통비", "복지", "요금"]
        place_keywords = ["위치", "주소", "영업시간", "식당", "카페", "가든", "번길", "로 "]

        if ai_category == "장소" and any(word in summary_text for word in policy_keywords):
            # 주소 관련 키워드가 없는데 정책 키워드만 있다면 "자기계발"로 변경
            if not any(word in summary_text for word in place_keywords):
                ai_category = "자기계발"
        
        # 3. 최종 카테고리 확정
        final_category = ai_category if ai_category in allowed_categories else "기타"
        
        return summary_text, final_category, final_tags
    
    except Exception as e:
        print(f"요약 에러: {e}")
        return "분석 중 오류가 발생했습니다.", "기타", []

# --- [이후 인스타그램/웹 데이터 추출 및 저장 로직] ---

def get_instagram_data(url):
    api_url = "https://instagram-scraper-stable-api.p.rapidapi.com/get_media_data_v2.php"
    match = re.search(r'/(?:p|reel|reels)/([A-Za-z0-9_-]+)', url)
    media_code = match.group(1) if match else ""
    headers = {"x-rapidapi-key": RAPIDAPI_KEY, "x-rapidapi-host": "instagram-scraper-stable-api.p.rapidapi.com"}
    try:
        response = requests.get(api_url, headers=headers, params={"media_code": media_code}, timeout=10)
        data = response.json()
        items = data.get("data") or data.get("items") or data
        if isinstance(items, list) and len(items) > 0: items = items[0]
        content, thumbnail = "내용 없음", ""
        if isinstance(items, dict):
            content = (items.get("edge_media_to_caption", {}).get("edges", [{}])[0].get("node", {}).get("text") or 
                       items.get("caption", {}).get("text") or items.get("caption_text") or items.get("text") or "내용 없음")
            thumbnail = items.get("display_url") or items.get("thumbnail_url") or ""
        return "Instagram 콘텐츠", content, thumbnail
    except Exception: return "Instagram 에러", "내용 없음", ""

def get_web_data(url):
    headers = {'User-Agent': 'Mozilla/5.0'}
    try:
        response = requests.get(url, headers=headers, timeout=10)
        soup = BeautifulSoup(response.text, 'html.parser')
        if "blog.naver.com" in url:
            main_frame = soup.find('iframe', id='mainFrame')
            if main_frame:
                new_url = "https://blog.naver.com" + main_frame['src']
                response = requests.get(new_url, headers=headers)
                soup = BeautifulSoup(response.text, 'html.parser')
        title = soup.title.string if soup.title else "제목 없음"
        content_area = soup.select_one('.se-main-container') or soup.body
        content = content_area.get_text(separator=' ', strip=True) if content_area else "본문 없음"
        return title, content, ""
    except Exception: return "웹 에러", "내용 없음", ""

def encode_image(image_bytes):
    return base64.b64encode(image_bytes).decode('utf-8')

def save_to_firestore(post_data):
    try:
        doc_ref = db.collection('posts').document()
        kst = timezone(timedelta(hours=9))
        post_data['createdAt'] = firestore.SERVER_TIMESTAMP
        doc_ref.set(post_data)
        return True
    except Exception as e:
        print(f"Firestore 저장 실패: {e}")
        return False

@app.post("/analyze")
def analyze_url(url: str):
    if "instagram.com" in url: title, content, thumbnail = get_instagram_data(url)
    else: title, content, thumbnail = get_web_data(url)
    summary, category, tags = get_ai_summary(content, use_pro=True)
    post_data = {"title": title, "summary": summary, "category": category, "tags": tags, "thumbnail": thumbnail, "url": url, "status": "ACTIVE", "isFavorite": False, "isPinned": False, "isRead": False, "isDeleted": False, "isCollected": False, "memo": "", "originalText": content, "memo_text":""}
    if save_to_firestore(post_data): return {"status": "success", "message": "Analyzed content saved to Firestore."}
    else: raise HTTPException(status_code=500, detail="Database save failed.")

@app.post("/analyze/image")
async def analyze_image(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        base64_image = encode_image(contents)
        ocr_response = vision_client.chat.completions.create(
            model="gpt-4o", 
            messages=[{"role": "user", "content": [{"type": "text", "text": "이 이미지의 모든 정보를 아카이빙 목적으로 정리해줘. 강조된 꿀팁 위주로 적어줘."},
                                                   {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}]}],
            temperature=0
        )
        raw_text = ocr_response.choices[0].message.content
        summary, category, tags = get_ai_summary(raw_text, use_pro=True)
        post_data = {"title": "이미지 분석 결과", "summary": summary, "category": category, "tags": tags, "thumbnail": "", "url": "uploaded_file", "status": "ACTIVE", "isFavorite": False, "isPinned": False, "isRead": False, "isDeleted": False, "isCollected": False, "memo": "", "originalText": raw_text, "memo_text":""}
        if save_to_firestore(post_data): return {"status": "success", "message": "Image analysis saved to Firestore."}
        else: raise HTTPException(status_code=500, detail="Database save failed.")
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
def health_check(): return {"status": "ok", "message": "ReSee API is alive!"}

# --- [기존 코드 하단에 추가, 관리용 엔드포인트 api임] ---

from pydantic import BaseModel
from typing import Optional

# 데이터 업데이트를 위한 요청 모델 설계
class StatusUpdate(BaseModel):
    isFavorite: Optional[bool] = None
    isPinned: Optional[bool] = None
    isRead: Optional[bool] = None
    isDeleted: Optional[bool] = None

class MemoUpdate(BaseModel):
    memo_text: str

class CategoryUpdate(BaseModel):
    category: str

# 1. 상태값(즐겨찾기, 고정, 읽음, 삭제) 업데이트 API
@app.patch("/posts/{post_id}/status")
def update_post_status(post_id: str, status_data: StatusUpdate):
    """
    사용자가 별표(즐겨찾기), 핀(고정), 체크(읽음), 휴지통(삭제) 버튼을 누를 때 호출합니다.
    """
    try:
        # 값이 들어온 필드만 필터링하여 업데이트 데이터 생성
        update_dict = {k: v for k, v in status_data.dict().items() if v is not None}
        if not update_dict:
            raise HTTPException(status_code=400, detail="업데이트할 데이터가 없습니다.")
        
        db.collection('posts').document(post_id).update(update_dict)
        return {"status": "success", "message": f"Post {post_id} status updated."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 2. 사용자 메모 저장 및 수정 API
@app.patch("/posts/{post_id}/memo")
def update_post_memo(post_id: str, memo_data: MemoUpdate):
    """
    사용자가 요약 카드 하단에 직접 메모를 작성하거나 수정할 때 호출합니다. [cite: 384-385, 968-969]
    """
    try:
        db.collection('posts').document(post_id).update({
            "memo_text": memo_data.memo_text,
            "updated_at": datetime.now(timezone(timedelta(hours=9))) # 수정 시간 기록
        })
        return {"status": "success", "message": "Memo saved successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 3. 카테고리 수동 변경 API
@app.patch("/posts/{post_id}/category")
def update_post_category(post_id: str, category_data: CategoryUpdate):
    """
    AI가 분류한 카테고리가 맘에 안 들 때 사용자가 직접 변경할 때 호출합니다. [cite: 1082-1084]
    """
    try:
        db.collection('posts').document(post_id).update({
            "category": category_data.category
        })
        return {"status": "success", "message": "Category updated."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 4. 통합 검색 API (제목, 요약, 메모 기반)
@app.get("/posts/search")
def search_posts(keyword: str):
    """
    사용자가 검색창에 입력한 키워드를 기반으로 정보를 탐색합니다. [cite: 1003-1005]
    """
    try:
        # Firestore의 기본 쿼리 제한으로 인해 간단한 필터링 후 서버사이드 검색 수행
        # 실제 운영 환경에서는 Algolia나 별도의 검색 엔진 도입을 고려할 수 있습니다.
        posts_ref = db.collection('posts').where("status", "==", "ACTIVE")
        docs = posts_ref.stream()
        
        results = []
        for doc in docs:
            post = doc.to_dict()
            # 제목, 요약, 메모 중 키워드가 포함된 경우 결과에 추가
            if (keyword in post.get("title", "") or 
                keyword in post.get("summary", "") or 
                keyword in post.get("memo_text", "")):
                results.append({"id": doc.id, **post})
                
        return {"status": "success", "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))