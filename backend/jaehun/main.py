from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import requests
from bs4 import BeautifulSoup
import os
import re
import json
import base64
from typing import Optional, List
from pydantic import BaseModel
from dotenv import load_dotenv
from openai import OpenAI

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


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = OpenAI(api_key=OPENAI_API_KEY)


def make_fallback_summary(content: str):
    lines = [
        line.strip()
        for line in content.splitlines()
        if line.strip()
    ]

    cleaned = []

    for line in lines:
        if line.startswith("#"):
            continue

        line = (
            line.replace("👉", "")
            .replace("✔", "")
            .replace("💡", "")
            .replace("💌", "")
            .strip()
        )

        if line:
            cleaned.append(line)

    if not cleaned:
        return "요약할 수 있는 본문이 부족합니다."

    picked = cleaned[:6]

    return "\n".join([f"• {line}" for line in picked])


def make_fallback_tags(content: str):
    tags = []

    if any(word in content for word in ["낮잠", "졸릴", "집중", "커피냅"]):
        tags.append("집중")
    if "괄사" in content:
        tags.append("괄사")
    if any(word in content for word in ["사탕", "캔디", "박하"]):
        tags.append("간식")
    if any(word in content for word in ["아이드롭", "렌즈", "눈", "피로"]):
        tags.append("아이케어")
    if any(word in content for word in ["쿠팡", "추천", "제품", "필수템"]):
        tags.append("추천템")
    if "대학생" in content:
        tags.append("대학생")
    if any(word in content for word in ["맛집", "카페", "여행", "숙소"]):
        tags.append("장소")
    if any(word in content for word in ["운동", "헬스", "러닝", "다이어트"]):
        tags.append("운동")

    if not tags:
        tags = ["기록"]

    return tags[:3]


def guess_category(content: str):
    if any(word in content for word in ["운동", "헬스", "러닝", "다이어트", "필라테스"]):
        return "운동"

    if any(word in content for word in ["카페", "맛집", "여행", "숙소", "장소", "전시"]):
        return "장소"

    if any(
        word in content
        for word in ["쿠팡", "구매", "제품", "추천템", "사탕", "캔디", "아이드롭", "괄사", "필수템"]
    ):
        return "쇼핑"

    if any(word in content for word in ["공부", "집중", "습관", "생산성", "낮잠", "커피냅"]):
        return "자기계발"

    return "기타"


def get_ai_summary(content: str):
    if not content or content == "내용 없음" or len(content.strip()) < 10:
        return "정보를 추출할 본문이 부족합니다.", "기타", ["내용부족"]

    try:
        prompt = f"""
너는 콘텐츠 분석 전문가야.
아래 본문을 한국어로 분석해서 반드시 JSON만 반환해.

규칙:
1. summary는 줄바꿈이 있는 리스트 형식으로 작성해.
2. summary의 각 줄은 반드시 "• 항목: 설명" 형식으로 작성해.
3. category는 장소, 자기계발, 쇼핑, 운동, 기타 중 하나만 선택해.
4. tags는 핵심 키워드 2~3개 배열로 작성해.
5. 코드블록 없이 JSON 객체만 반환해.

본문:
{content[:4000]}

반환 형식:
{{
  "summary": "• 항목: 설명\\n• 항목: 설명",
  "category": "기타",
  "tags": ["키워드1", "키워드2"]
}}
"""

        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "system",
                    "content": "너는 반드시 JSON 객체만 반환하는 콘텐츠 분석기야.",
                },
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
            temperature=0,
            response_format={"type": "json_object"},
        )

        raw = response.choices[0].message.content.strip()
        result = json.loads(raw)

        summary_text = str(result.get("summary", "")).strip()
        ai_category = str(result.get("category", "기타")).strip()
        tags = result.get("tags", [])

        allowed_categories = ["장소", "자기계발", "쇼핑", "운동", "기타"]

        if ai_category not in allowed_categories:
            ai_category = guess_category(content)

        if not isinstance(tags, list):
            tags = []

        final_tags = [
            str(tag).strip()
            for tag in tags
            if str(tag).strip()
        ][:3]

        if not summary_text:
            summary_text = make_fallback_summary(content)

        if not final_tags:
            final_tags = make_fallback_tags(content)

        if not ai_category:
            ai_category = guess_category(content)

        return summary_text, ai_category, final_tags

    except Exception as e:
        print(f"요약 에러: {e}")

        fallback_summary = make_fallback_summary(content)
        fallback_category = guess_category(content)
        fallback_tags = make_fallback_tags(content)

        return fallback_summary, fallback_category, fallback_tags


def get_instagram_data(url: str):
    api_url = "https://instagram-scraper-stable-api.p.rapidapi.com/get_media_data_v2.php"

    match = re.search(r"/(?:p|reel|reels)/([A-Za-z0-9_-]+)", url)
    media_code = match.group(1) if match else ""

    headers = {
        "x-rapidapi-key": RAPIDAPI_KEY or "",
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

        if isinstance(items, list) and items:
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

    except Exception as e:
        print(f"Instagram 추출 에러: {e}")
        return "Instagram 콘텐츠", "내용 없음", ""


def get_web_data(url: str):
    try:
        response = requests.get(
            url,
            headers={"User-Agent": "Mozilla/5.0"},
            timeout=10,
        )

        soup = BeautifulSoup(response.text, "html.parser")

        title = (
            soup.title.string.strip()
            if soup.title and soup.title.string
            else "제목 없음"
        )

        for tag in soup(["script", "style", "noscript"]):
            tag.decompose()

        body_text = (
            soup.body.get_text(separator="\n", strip=True)
            if soup.body
            else "내용 없음"
        )

        content = body_text[:3000] if body_text else "내용 없음"

        thumbnail = ""
        og_image = soup.find("meta", property="og:image")
        if og_image and og_image.get("content"):
            thumbnail = og_image.get("content")

        return title, content, thumbnail

    except Exception as e:
        print(f"웹 추출 에러: {e}")
        return "제목 없음", "내용 없음", ""


def extract_image_text(base64_image: str):
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": "이미지 안의 텍스트와 핵심 정보를 한국어로 상세히 추출해줘.",
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

    return response.choices[0].message.content


@app.post("/analyze")
def analyze_url(url: str):
    if "instagram.com" in url:
        title, content, thumbnail = get_instagram_data(url)
    else:
        title, content, thumbnail = get_web_data(url)

    summary, category, tags = get_ai_summary(content)

    return {
        "status": "ACTIVE",
        "url": url,
        "title": title,
        "summary": summary,
        "category": category,
        "tags": tags,
        "thumbnail": thumbnail,
        "originalText": content,
    }


@app.post("/analyze/image")
async def analyze_image(files: List[UploadFile] = File(...)):
    all_image_text = ""

    for index, file in enumerate(files, start=1):
        contents = await file.read()
        base64_image = base64.b64encode(contents).decode("utf-8")

        image_text = extract_image_text(base64_image)
        all_image_text += f"\n\n[이미지 {index}]\n{image_text}"

    summary, category, tags = get_ai_summary(all_image_text)

    return {
        "status": "ACTIVE",
        "url": "uploaded_image",
        "title": "이미지 분석 결과",
        "summary": summary,
        "category": category,
        "tags": tags,
        "thumbnail": "",
        "originalText": all_image_text,
    }


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

    summary, category, tags = get_ai_summary(combined)

    return {
        "status": "ACTIVE",
        "url": url,
        "title": title,
        "summary": summary,
        "category": category,
        "tags": tags,
        "thumbnail": thumbnail,
        "originalText": combined,
    }


@app.get("/")
def health():
    return {"status": "ok"}