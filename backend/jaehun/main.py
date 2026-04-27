from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import requests
from bs4 import BeautifulSoup
import os
import re
import json
import base64
from datetime import datetime, timezone, timedelta
from typing import Optional, List
from pydantic import BaseModel
from dotenv import load_dotenv
from openai import OpenAI
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate

import firebase_admin
from firebase_admin import credentials, firestore

load_dotenv()
RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")


class StatusUpdate(BaseModel):
    isFavorite: Optional[bool] = None
    isPinned: Optional[bool] = None
    isRead: Optional[bool] = None
    isDeleted: Optional[bool] = None


class MemoUpdate(BaseModel):
    memo_text: str


class CategoryUpdate(BaseModel):
    category: str


cred = credentials.Certificate("resee-app-firebase-adminsdk-fbsvc-7110fd24e7.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_headers=["*"],
)

llm_pro = ChatOpenAI(
    model_name="gpt-4o",
    temperature=0,
    openai_api_key=OPENAI_API_KEY,
)
vision_client = OpenAI(api_key=OPENAI_API_KEY)

summary_prompt = PromptTemplate(
    input_variables=["content"],
    template="""
    너는 콘텐츠 분석 전문가야. 아래 규칙을 '반드시' 지켜서 분석해줘.
    사용자가 한눈에 정보를 파악할 수 있도록 불필요한 서술어는 빼고 핵심 데이터만 정리해줘.

    [작성 규칙]
    1. 반드시 한국어로 답변할 것.
    2. [전수 조사]: 본문에 나열된 모든 정보(장소, 제품, 아티스트, 곡명 등)를 절대로 하나도 빠뜨리지 말고 모두 포함해.
    3. [문장 형식 금지]: 서술형 문장을 사용하지 마.
    4. [리스트 형식]: 반드시 '• 항목명: 상세설명' 형식을 사용하고, 항목 간에는 줄바꿈을 해줘.
    
    5. [태그 규칙 - 중요]: 'tags' 배열의 첫 번째 요소는 반드시 콘텐츠의 대주제(음악, 장소, 쇼핑, 운동, 자기계발 등)여야 함.
       예: 음악이면 ["음악", "아티스트명"], 맛집이면 ["장소", "강남맛집"]

    6. [카테고리 선택 - 아래 5개 중 하나만 선택]
       - 장소, 자기계발, 쇼핑, 운동, 기타

    본문 내용:
    {content}

    답변 형식(JSON):
    {{
        "summary": "요약내용", 
        "category": "장소/자기계발/쇼핑/운동/기타 중 택1", 
        "tags": ["대주제", "핵심키워드"]
    }}
    """,
)


def get_ai_summary(content, use_pro=False):
    if not content or content == "내용 없음" or len(content) < 10:
        return "정보를 추출할 본문이 부족합니다.", "기타", ["내용부족"]

    try:
        formatted_prompt = summary_prompt.format(content=content[:4000])
        response_message = llm_pro.invoke(formatted_prompt)
        clean_res = (
            response_message.content
            .replace("```json", "")
            .replace("```", "")
            .strip()
        )

        result = json.loads(clean_res)

        summary_text = result.get("summary", "")
        ai_category = result.get("category", "기타").strip()
        tags = result.get("tags", [])

        final_tags = tags[:3] if isinstance(tags, list) else []

        allowed_categories = ["장소", "자기계발", "쇼핑", "운동", "기타"]

        if ai_category not in allowed_categories:
            if any(
                word in ai_category
                for word in ["맛집", "여행", "카페", "사찰", "숙소", "장소"]
            ):
                ai_category = "장소"
            elif any(
                word in ai_category
                for word in ["정책", "재테크", "공부", "팁", "카드", "혜택"]
            ):
                ai_category = "자기계발"
            else:
                ai_category = "기타"

        policy_keywords = [
            "K-패스",
            "K패스",
            "환급",
            "카드",
            "정책",
            "정부",
            "혜택",
            "교통비",
        ]

        if ai_category == "장소" and any(
            word in summary_text for word in policy_keywords
        ):
            ai_category = "자기계발"

        return summary_text, ai_category, final_tags

    except Exception as e:
        print(f"요약 에러: {e}")
        return "분석 중 오류 발생", "기타", []


def get_instagram_data(url):
    api_url = "https://instagram-scraper-stable-api.p.rapidapi.com/get_media_data_v2.php"

    match = re.search(r'/(?:p|reel|reels)/([A-Za-z0-9_-]+)', url)
    media_code = match.group(1) if match else ""

    headers = {
        "x-rapidapi-key": RAPIDAPI_KEY,
        "x-rapidapi-host": "instagram-scraper-stable-api.p.rapidapi.com",
    }

    try:
        response = requests.get(
            api_url,
            headers=headers,
            params={"media_code": media_code},
            timeout=10,
        )

        data = response.json()
        items = data.get("data") or data.get("items") or [data]

        if isinstance(items, list):
            items = items[0]

        content = "내용 없음"
        thumbnail = ""

        if isinstance(items, dict):
            content = (
                items.get("edge_media_to_caption", {})
                .get("edges", [{}])[0]
                .get("node", {})
                .get("text")
                or items.get("caption", {}).get("text")
                or items.get("caption_text")
                or items.get("text")
                or "내용 없음"
            )

            thumbnail = (
                items.get("display_url")
                or items.get("thumbnail_url")
                or ""
            )

        return "Instagram 콘텐츠", content, thumbnail

    except Exception:
        return "Instagram 에러", "내용 없음", ""


def save_to_firestore(post_data):
    try:
        doc_ref = db.collection("posts").document()
        post_data["createdAt"] = datetime.now(timezone(timedelta(hours=9)))
        doc_ref.set(post_data)
        return True
    except Exception:
        return False


def extract_image_text(base64_image):
    ocr_res = vision_client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": "이미지 텍스트와 핵심 정보를 상세히 추출해줘.",
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{base64_image}"
                        },
                    },
                ],
            }
        ],
        temperature=0,
    )

    return ocr_res.choices[0].message.content


@app.post("/analyze")
def analyze_url(url: str):
    if "instagram.com" in url:
        title, content, thumbnail = get_instagram_data(url)
    else:
        res = requests.get(
            url,
            headers={"User-Agent": "Mozilla/5.0"},
            timeout=10,
        )
        soup = BeautifulSoup(res.text, "html.parser")
        title = soup.title.string if soup.title else "제목 없음"
        content = soup.body.get_text()[:3000] if soup.body else "내용 없음"
        thumbnail = ""

    summary, category, tags = get_ai_summary(content, use_pro=True)

    post_data = {
        "title": title,
        "summary": summary,
        "category": category,
        "tags": tags,
        "thumbnail": thumbnail,
        "url": url,
        "status": "ACTIVE",
        "isFavorite": False,
        "isPinned": False,
        "isRead": False,
        "isDeleted": False,
        "memo_text": "",
    }

    save_to_firestore(post_data)
    return {"status": "success"}


@app.post("/analyze/image")
async def analyze_image(files: List[UploadFile] = File(...)):
    all_image_text = ""

    for index, file in enumerate(files, start=1):
        contents = await file.read()
        base64_image = base64.b64encode(contents).decode("utf-8")

        image_text = extract_image_text(base64_image)

        all_image_text += f"\n\n[이미지 {index}]\n{image_text}"

    summary, category, tags = get_ai_summary(all_image_text, use_pro=True)

    post_data = {
        "title": "이미지 분석 결과",
        "summary": summary,
        "category": category,
        "tags": tags,
        "thumbnail": "",
        "url": "uploaded_file",
        "status": "ACTIVE",
        "isFavorite": False,
        "isPinned": False,
        "isRead": False,
        "isDeleted": False,
        "memo_text": "",
    }

    save_to_firestore(post_data)
    return {"status": "success"}


@app.post("/analyze/complex")
async def analyze_complex(url: str, files: List[UploadFile] = File(...)):
    title, url_content, thumbnail = get_instagram_data(url)

    all_image_text = ""

    for index, file in enumerate(files, start=1):
        contents = await file.read()
        base64_image = base64.b64encode(contents).decode("utf-8")

        image_text = extract_image_text(base64_image)

        all_image_text += f"\n\n[이미지 {index}]\n{image_text}"

    combined = f"""
[링크 본문]
{url_content}

[이미지 내 텍스트]
{all_image_text}
"""

    summary, category, tags = get_ai_summary(combined, use_pro=True)

    post_data = {
        "title": title,
        "summary": summary,
        "category": category,
        "tags": tags,
        "thumbnail": thumbnail,
        "url": url,
        "status": "ACTIVE",
        "isFavorite": False,
        "isPinned": False,
        "isRead": False,
        "isDeleted": False,
        "memo_text": "",
    }

    save_to_firestore(post_data)
    return {"status": "success"}


@app.patch("/posts/{post_id}/status")
def update_status(post_id: str, data: StatusUpdate):
    update_dict = {
        key: value
        for key, value in data.dict().items()
        if value is not None
    }

    db.collection("posts").document(post_id).update(update_dict)
    return {"status": "success"}


@app.get("/")
def health():
    return {"status": "ok"}